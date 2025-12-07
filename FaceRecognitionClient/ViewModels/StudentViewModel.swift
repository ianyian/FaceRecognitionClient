//
//  StudentViewModel.swift
//  FaceRecognitionClient
//
//  Student Management ViewModel
//  Created on December 4, 2025.
//  Updated December 4, 2025 - Added faceData sync (same as CoMa web app)
//

import Combine
import FirebaseFirestore
import Foundation
import MediaPipeTasksVision
import SwiftUI

// MARK: - Form Data

struct StudentFormData {
    var studentFirstName: String = ""
    var studentLastName: String = ""
    var className: String = ""
    var parentFirstName: String = ""
    var parentLastName: String = ""
    var parentPhone: String = ""

    var isValid: Bool {
        studentFirstName.count >= 2 && studentLastName.count >= 2 && !className.isEmpty
            && parentFirstName.count >= 2 && parentLastName.count >= 2 && parentPhone.count >= 10
    }

    mutating func reset() {
        studentFirstName = ""
        studentLastName = ""
        className = ""
        parentFirstName = ""
        parentLastName = ""
        parentPhone = ""
    }
}

// MARK: - Class Info

struct ClassInfo: Identifiable, Codable {
    let id: String
    let name: String
}

// MARK: - View Model

@MainActor
class StudentViewModel: ObservableObject {
    // MARK: - Published Properties

    // Navigation
    @Published var selectedStudent: Student?
    @Published var showingAddForm = false
    @Published var showingEditForm = false
    @Published var showingDeleteAlert = false

    // List View
    @Published var students: [Student] = []
    @Published var searchText = ""
    @Published var statusFilter: StudentStatus = .registered
    @Published var isLoading = false

    // Form View
    @Published var formData = StudentFormData()
    @Published var capturedImages: [UIImage] = []
    @Published var existingImages: [String] = []
    @Published var isSubmitting = false
    @Published var isCameraOn = false

    // Classes
    @Published var classes: [ClassInfo] = []

    // Toast/Alert
    @Published var showToast = false
    @Published var toastMessage = ""
    @Published var toastType: ToastType = .success

    // MARK: - Constants

    static let maxFaceSamples = 5
    static let minFaceSamples = 3

    // MARK: - Dependencies

    private let firebaseService = FirebaseService.shared
    private let db = Firestore.firestore()
    private let mediaPipeService = MediaPipeFaceLandmarkerService.shared
    private var schoolId: String

    // Staff context for permission checking
    let staff: Staff

    // MARK: - Computed Properties

    var filteredStudents: [Student] {
        let filtered = students.filter { student in
            // Status filter
            guard student.status == statusFilter else { return false }

            // Search filter
            if !searchText.isEmpty {
                let fullName = student.fullName.lowercased()
                if !fullName.contains(searchText.lowercased()) {
                    return false
                }
            }

            return true
        }

        // Sort by updatedAt (newest first)
        return filtered.sorted { a, b in
            let dateA = a.updatedAt ?? a.registrationDate ?? Date.distantPast
            let dateB = b.updatedAt ?? b.registrationDate ?? Date.distantPast
            return dateA > dateB
        }
    }

    var isEditMode: Bool {
        selectedStudent != nil && showingEditForm
    }

    var captureCount: Int {
        capturedImages.count
    }

    var canCapture: Bool {
        capturedImages.count < Self.maxFaceSamples
    }

    var hasEnoughSamples: Bool {
        capturedImages.count >= Self.minFaceSamples
    }

    // MARK: - Initialization

    init(schoolId: String, staff: Staff) {
        self.schoolId = schoolId
        self.staff = staff
    }

    // MARK: - Data Loading

    func loadData() async {
        isLoading = true

        do {
            async let studentsTask = loadStudents()
            async let classesTask = loadClasses()

            let (loadedStudents, loadedClasses) = try await (studentsTask, classesTask)

            students = loadedStudents
            classes = loadedClasses

            print("✅ Loaded \(students.count) students and \(classes.count) classes")
        } catch {
            print("❌ Failed to load data: \(error)")
            showError("Failed to load data: \(error.localizedDescription)")
        }

        isLoading = false
    }

    private func loadStudents() async throws -> [Student] {
        let querySnapshot =
            try await db
            .collection("schools").document(schoolId)
            .collection("students")
            .getDocuments()

        var loadedStudents: [Student] = []

        for document in querySnapshot.documents {
            do {
                let student = try Student(from: document)
                loadedStudents.append(student)
            } catch {
                print("⚠️ Error parsing student \(document.documentID): \(error)")
            }
        }

        return loadedStudents
    }

    private func loadClasses() async throws -> [ClassInfo] {
        let querySnapshot =
            try await db
            .collection("schools").document(schoolId)
            .collection("classes")
            .getDocuments()

        var loadedClasses: [ClassInfo] = []

        for document in querySnapshot.documents {
            let data = document.data()
            let name = data["name"] as? String ?? document.documentID
            loadedClasses.append(ClassInfo(id: document.documentID, name: name))
        }

        return loadedClasses
    }

    // MARK: - Student Detail

    func loadStudentDetail(_ studentId: String) async {
        do {
            let docRef =
                db
                .collection("schools").document(schoolId)
                .collection("students").document(studentId)

            let snapshot = try await docRef.getDocument()
            let student = try Student(from: snapshot)
            selectedStudent = student

            // Load face samples
            existingImages = try await loadFaceSamples(studentId: studentId)
        } catch {
            print("❌ Failed to load student detail: \(error)")
            showError("Failed to load student: \(error.localizedDescription)")
        }
    }

    private func loadFaceSamples(studentId: String) async throws -> [String] {
        let querySnapshot =
            try await db
            .collection("schools").document(schoolId)
            .collection("students").document(studentId)
            .collection("faceSamples")
            .getDocuments()

        var samples: [String] = []

        for document in querySnapshot.documents {
            if let dataUrl = document.data()["dataUrl"] as? String {
                samples.append(dataUrl)
            }
        }

        return samples
    }

    // MARK: - Form Actions

    func prepareAddForm() {
        formData.reset()
        capturedImages = []
        existingImages = []
        selectedStudent = nil
        showingAddForm = true
    }

    func prepareEditForm() {
        guard let student = selectedStudent else { return }

        // Parse parent name - prefer new schema, fall back to legacy
        var parentFirst = student.parentFirstName ?? ""
        var parentLast = student.parentLastName ?? ""

        // If new schema fields are empty, try to parse from legacy parentName
        if parentFirst.isEmpty, let legacyName = student.parentName {
            let components = legacyName.components(separatedBy: " ")
            if components.count >= 2 {
                parentFirst = components[0]
                parentLast = components.dropFirst().joined(separator: " ")
            } else if components.count == 1 {
                parentFirst = components[0]
            }
        }

        // Get phone - prefer new schema, fall back to legacy
        let phone = student.parentPhone ?? student.parentContact ?? ""

        formData = StudentFormData(
            studentFirstName: student.firstName,
            studentLastName: student.lastName,
            className: student.className,
            parentFirstName: parentFirst,
            parentLastName: parentLast,
            parentPhone: phone
        )
        capturedImages = []
        showingEditForm = true
    }

    func cancelForm() {
        showingAddForm = false
        showingEditForm = false
        formData.reset()
        capturedImages = []  // Release captured images
        existingImages = []  // Release base64 strings
        isCameraOn = false
    }

    // MARK: - Face Capture

    func addCapturedImage(_ image: UIImage) {
        guard canCapture else {
            showWarning("Maximum \(Self.maxFaceSamples) samples allowed")
            return
        }

        // Resize immediately to save memory (max 400x400 for face samples)
        let resizedImage = resizeForMemory(image: image, maxDimension: 400)
        capturedImages.append(resizedImage)
        showSuccess("Face \(capturedImages.count) captured")
    }

    /// Resize image to reduce memory footprint
    private func resizeForMemory(image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size

        // Don't upscale if already smaller
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }

        let scale = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resized ?? image
    }

    func removeCapturedImage(at index: Int) {
        guard index >= 0 && index < capturedImages.count else { return }
        capturedImages.remove(at: index)
    }

    // MARK: - Submit Form

    func submitForm() async {
        // Validate form
        guard formData.isValid else {
            showError("Please fill in all required fields")
            return
        }

        // Validate face samples for new registration
        if !isEditMode && capturedImages.count < Self.minFaceSamples {
            showError("Please capture at least \(Self.minFaceSamples) face samples")
            return
        }

        // Validate face samples for edit (if replacing)
        if isEditMode && capturedImages.count > 0 && capturedImages.count < Self.minFaceSamples {
            showError("If replacing images, provide at least \(Self.minFaceSamples) new ones")
            return
        }

        isSubmitting = true

        do {
            if isEditMode {
                try await updateStudent()
            } else {
                try await createStudent()
            }

            // Reload data
            await loadData()

            // Close form
            cancelForm()

        } catch {
            print("❌ Submit failed: \(error)")
            showError("Failed to save: \(error.localizedDescription)")
        }

        isSubmitting = false
    }

    private func createStudent() async throws {
        let studentId = UUID().uuidString

        // ISO8601 date formatter for registrationDate (matches CoMa web format)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let now = Date()

        // Generate face encodings from captured images using MediaPipe
        var faceEncodings: [MediaPipeFaceEncoding] = []
        for image in capturedImages {
            do {
                let encoding = try mediaPipeService.detectFaceLandmarks(in: image)
                faceEncodings.append(encoding)
                print("✅ Generated face encoding for image")
            } catch {
                print("⚠️ Failed to generate encoding for image: \(error)")
            }
        }

        // Create faceEncoding marker (used by old system, now we use faceData collection)
        let faceEncodingMarker =
            faceEncodings.isEmpty
            ? "encoded_\(Date().timeIntervalSince1970)_\(capturedImages.count)"
            : "mediapipe_\(Date().timeIntervalSince1970)_\(faceEncodings.count)"

        // Get student full name for faceData
        let studentFullName = "\(formData.studentFirstName) \(formData.studentLastName)"

        // Student data matching CoMa web app schema exactly
        let studentData: [String: Any] = [
            "id": studentId,
            "firstName": formData.studentFirstName,
            "lastName": formData.studentLastName,
            "class": formData.className,
            // Parent info - new schema (CoMa web format)
            "parentFirstName": formData.parentFirstName,
            "parentLastName": formData.parentLastName,
            "parentPhone": formData.parentPhone,
            // Status and dates
            "status": "Registered",
            "registrationDate": isoFormatter.string(from: now),  // ISO string like web
            "createdAt": now,
            "updatedAt": now,
            "schoolId": schoolId,
            // Face encoding placeholder
            "faceEncoding": faceEncodingMarker,
            "avatarUrl": "https://picsum.photos/seed/\(studentId)/100/100",
        ]

        // Save student document
        try await db
            .collection("schools").document(schoolId)
            .collection("students").document(studentId)
            .setData(studentData)

        // Save face samples (for avatar display - same as web)
        try await saveFaceSamples(studentId: studentId)

        // Save to faceData collection (for face recognition - same as web)
        if !faceEncodings.isEmpty {
            try await saveFaceData(
                studentId: studentId,
                studentName: studentFullName,
                className: formData.className,
                encodings: faceEncodings
            )
        }

        showSuccess("\(formData.studentFirstName) has been registered!")
        print("✅ Created student: \(studentId) with \(faceEncodings.count) face encodings")
    }

    private func updateStudent() async throws {
        guard let studentId = selectedStudent?.id else {
            throw NSError(
                domain: "Student", code: 400,
                userInfo: [NSLocalizedDescriptionKey: "No student selected"])
        }

        // Get student full name for faceData
        let studentFullName = "\(formData.studentFirstName) \(formData.studentLastName)"

        // Check if name or class changed (need to update faceData)
        let nameChanged =
            selectedStudent?.firstName != formData.studentFirstName
            || selectedStudent?.lastName != formData.studentLastName
        let classChanged = selectedStudent?.className != formData.className

        // Update data matching CoMa web app schema
        var updateData: [String: Any] = [
            "firstName": formData.studentFirstName,
            "lastName": formData.studentLastName,
            "class": formData.className,
            // Parent info - new schema (CoMa web format)
            "parentFirstName": formData.parentFirstName,
            "parentLastName": formData.parentLastName,
            "parentPhone": formData.parentPhone,
            "updatedAt": Date(),
        ]

        // If new images captured, update face encoding and faceData
        if !capturedImages.isEmpty {
            // Generate face encodings from captured images using MediaPipe
            var faceEncodings: [MediaPipeFaceEncoding] = []
            for image in capturedImages {
                do {
                    let encoding = try mediaPipeService.detectFaceLandmarks(in: image)
                    faceEncodings.append(encoding)
                    print("✅ Generated face encoding for image")
                } catch {
                    print("⚠️ Failed to generate encoding for image: \(error)")
                }
            }

            // Update encoding marker
            let faceEncodingMarker =
                faceEncodings.isEmpty
                ? "encoded_\(Date().timeIntervalSince1970)_\(capturedImages.count)"
                : "mediapipe_\(Date().timeIntervalSince1970)_\(faceEncodings.count)"
            updateData["faceEncoding"] = faceEncodingMarker

            // Delete old face samples
            try await deleteExistingFaceSamples(studentId: studentId)

            // Save new face samples (for avatar display)
            try await saveFaceSamples(studentId: studentId)

            // Delete old faceData and save new ones (same as CoMa web cleanReplaceStudentFaceData)
            if !faceEncodings.isEmpty {
                try await deleteExistingFaceData(studentId: studentId)
                try await saveFaceData(
                    studentId: studentId,
                    studentName: studentFullName,
                    className: formData.className,
                    encodings: faceEncodings
                )
            }
        } else if nameChanged || classChanged {
            // No new images, but name or class changed - update existing faceData records
            try await updateExistingFaceData(
                studentId: studentId,
                studentName: studentFullName,
                className: formData.className
            )
        }

        // Update student document
        try await db
            .collection("schools").document(schoolId)
            .collection("students").document(studentId)
            .updateData(updateData)

        // Refresh selectedStudent so detail view shows updated data
        await loadStudentDetail(studentId)

        showSuccess("\(formData.studentFirstName) has been updated!")
        print("✅ Updated student: \(studentId)")
    }

    private func saveFaceSamples(studentId: String) async throws {
        let batch = db.batch()

        for image in capturedImages {
            // Resize image to fit Firestore limits (~1MB per field)
            let resizedImage = resizeImageForFirestore(image: image, maxSizeKB: 500)
            guard let imageData = resizedImage.jpegData(compressionQuality: 0.6) else { continue }

            let base64String = imageData.base64EncodedString()
            let dataUrl = "data:image/jpeg;base64,\(base64String)"

            // Check size
            let sizeKB = dataUrl.count / 1024
            print("📊 Face sample size: \(sizeKB) KB")

            if sizeKB > 900 {
                print("⚠️ Image still too large (\(sizeKB) KB), skipping")
                continue
            }

            let sampleId = UUID().uuidString
            let sampleRef =
                db
                .collection("schools").document(schoolId)
                .collection("students").document(studentId)
                .collection("faceSamples").document(sampleId)

            batch.setData(
                [
                    "id": sampleId,
                    "dataUrl": dataUrl,
                ], forDocument: sampleRef)
        }

        try await batch.commit()
        print("✅ Saved \(capturedImages.count) face samples")
    }

    /// Resize image to fit within Firestore field size limits
    private func resizeImageForFirestore(image: UIImage, maxSizeKB: Int) -> UIImage {
        // Target dimensions - face samples don't need to be large
        var targetWidth: CGFloat = 400
        var targetHeight: CGFloat = 400

        // Calculate aspect ratio
        let aspectRatio = image.size.width / image.size.height

        if aspectRatio > 1 {
            // Landscape
            targetHeight = targetWidth / aspectRatio
        } else {
            // Portrait
            targetWidth = targetHeight * aspectRatio
        }

        // If image is already smaller, don't upscale
        if image.size.width <= targetWidth && image.size.height <= targetHeight {
            // Still need to check if it fits after compression
            if let data = image.jpegData(compressionQuality: 0.6) {
                let sizeKB = data.count / 1024
                if sizeKB <= maxSizeKB {
                    return image
                }
            }
        }

        // Create new size
        let newSize = CGSize(width: targetWidth, height: targetHeight)

        // Resize image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let finalImage = resizedImage else {
            print("⚠️ Failed to resize image, using original")
            return image
        }

        print(
            "📐 Resized image from \(Int(image.size.width))x\(Int(image.size.height)) to \(Int(finalImage.size.width))x\(Int(finalImage.size.height))"
        )
        return finalImage
    }

    private func deleteExistingFaceSamples(studentId: String) async throws {
        let querySnapshot =
            try await db
            .collection("schools").document(schoolId)
            .collection("students").document(studentId)
            .collection("faceSamples")
            .getDocuments()

        let batch = db.batch()

        for document in querySnapshot.documents {
            batch.deleteDocument(document.reference)
        }

        try await batch.commit()
        print("✅ Deleted existing face samples")
    }

    // MARK: - FaceData Collection Sync (same as CoMa web app)

    /// Save face encodings to faceData collection (used for face recognition)
    /// This matches the CoMa web app's FaceDataService.addFaceData behavior
    private func saveFaceData(
        studentId: String,
        studentName: String,
        className: String,
        encodings: [MediaPipeFaceEncoding]
    ) async throws {
        let batch = db.batch()

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let nowString = isoFormatter.string(from: Date())

        // Get current version from faceDataMeta
        let currentVersion = try await getCurrentFaceDataVersion()
        let newVersion = currentVersion + 1

        for (index, encoding) in encodings.enumerated() {
            // Convert encoding to JSON string (same format as web)
            let encoder = JSONEncoder()
            guard let encodingData = try? encoder.encode(encoding),
                let encodingString = String(data: encodingData, encoding: .utf8)
            else {
                print("⚠️ Failed to encode face data \(index)")
                continue
            }

            // Get original image as base64 (for display in faceData list)
            var originalImage = ""
            if index < capturedImages.count {
                let resizedImage = resizeImageForFirestore(
                    image: capturedImages[index], maxSizeKB: 300)
                if let imageData = resizedImage.jpegData(compressionQuality: 0.5) {
                    originalImage = "data:image/jpeg;base64,\(imageData.base64EncodedString())"
                }
            }

            let faceDataId = "\(studentId)_\(index)_\(Int(Date().timeIntervalSince1970 * 1000))"

            let faceDataRef =
                db
                .collection("schools").document(schoolId)
                .collection("faceData").document(faceDataId)

            // FaceData document structure (matches CoMa web app exactly)
            let faceDataDocument: [String: Any] = [
                "faceDataId": faceDataId,
                "studentId": studentId,
                "studentDocId": studentId,
                "studentName": studentName,
                "className": className,
                "sampleIndex": index,
                "encoding": encodingString,  // MediaPipe landmarks JSON
                "originalImage": originalImage,  // Base64 image for display
                "faceConfidence": encoding.confidence,
                "version": newVersion,
                "createdAt": nowString,
                "updatedAt": nowString,
                "createdBy": "ios-app",
                "updatedBy": "ios-app",
                "isOrphaned": false,
                "syncDate": nowString,
                "syncVersion": newVersion,
                "lastUpdated": nowString,
                "encoderType": "mediapipe",
            ]

            batch.setData(faceDataDocument, forDocument: faceDataRef)
        }

        try await batch.commit()
        print("✅ Saved \(encodings.count) face data records to faceData collection")

        // Update faceDataMeta version
        try await updateFaceDataVersion(newVersion: newVersion)
    }

    /// Delete all faceData for a student (called before re-adding during edit)
    /// This matches the CoMa web app's FaceDataService.deleteFaceDataForStudent behavior
    private func deleteExistingFaceData(studentId: String) async throws {
        let querySnapshot =
            try await db
            .collection("schools").document(schoolId)
            .collection("faceData")
            .whereField("studentId", isEqualTo: studentId)
            .getDocuments()

        if querySnapshot.documents.isEmpty {
            print("ℹ️ No existing faceData found for student \(studentId)")
            return
        }

        let batch = db.batch()

        for document in querySnapshot.documents {
            batch.deleteDocument(document.reference)
        }

        try await batch.commit()
        print(
            "✅ Deleted \(querySnapshot.documents.count) existing faceData records for student \(studentId)"
        )
    }

    /// Update studentName and className in existing faceData records when student info changes
    private func updateExistingFaceData(studentId: String, studentName: String, className: String)
        async throws
    {
        let querySnapshot =
            try await db
            .collection("schools").document(schoolId)
            .collection("faceData")
            .whereField("studentId", isEqualTo: studentId)
            .getDocuments()

        if querySnapshot.documents.isEmpty {
            print("ℹ️ No existing faceData found for student \(studentId) to update")
            return
        }

        let batch = db.batch()

        for document in querySnapshot.documents {
            batch.updateData(
                [
                    "studentName": studentName,
                    "className": className,
                    "updatedAt": Date(),
                ], forDocument: document.reference)
        }

        try await batch.commit()
        print(
            "✅ Updated \(querySnapshot.documents.count) faceData records for student \(studentId) with new name: \(studentName), class: \(className)"
        )
    }

    /// Get current faceData version from faceDataMeta collection
    private func getCurrentFaceDataVersion() async throws -> Int {
        let docRef =
            db
            .collection("schools").document(schoolId)
            .collection("faceDataMeta").document("version")

        let snapshot = try await docRef.getDocument()

        if let data = snapshot.data(), let version = data["version"] as? Int {
            return version
        }

        return 0  // Default to 0 if no version exists
    }

    /// Update faceDataMeta version (triggers cache refresh on all clients)
    private func updateFaceDataVersion(newVersion: Int) async throws {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let nowString = isoFormatter.string(from: Date())

        let versionData: [String: Any] = [
            "version": newVersion,
            "lastUpdated": nowString,
            "updatedBy": "ios-app",
            "syncDate": nowString,
        ]

        try await db
            .collection("schools").document(schoolId)
            .collection("faceDataMeta").document("version")
            .setData(versionData, merge: true)

        print("✅ Updated faceDataMeta version to \(newVersion)")
    }

    // MARK: - Delete Student

    func confirmDelete() {
        showingDeleteAlert = true
    }

    func deleteStudent() async {
        guard let studentId = selectedStudent?.id else { return }

        do {
            // Mark student as deleted
            try await db
                .collection("schools").document(schoolId)
                .collection("students").document(studentId)
                .updateData(["status": "Deleted", "updatedAt": Date()])

            // Also delete faceData for this student (so they won't be matched)
            try await deleteExistingFaceData(studentId: studentId)

            // Increment version to trigger cache refresh
            let currentVersion = try await getCurrentFaceDataVersion()
            try await updateFaceDataVersion(newVersion: currentVersion + 1)

            showSuccess("Student has been deleted")
            selectedStudent = nil

            await loadData()
        } catch {
            print("❌ Delete failed: \(error)")
            showError("Failed to delete: \(error.localizedDescription)")
        }
    }

    // MARK: - Toast Helpers

    enum ToastType {
        case success, error, warning
    }

    private func showSuccess(_ message: String) {
        toastMessage = message
        toastType = .success
        showToast = true
    }

    private func showError(_ message: String) {
        toastMessage = message
        toastType = .error
        showToast = true
    }

    private func showWarning(_ message: String) {
        toastMessage = message
        toastType = .warning
        showToast = true
    }
}
