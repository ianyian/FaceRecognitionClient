//
//  FirebaseService.swift
//  FaceRecognitionClient
//
//  Created on November 28, 2025.
//

import Combine
import FirebaseAuth
import FirebaseFirestore
import Foundation

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()

    private let db = Firestore.firestore()
    private let auth = Auth.auth()

    @Published var currentUser: User?
    @Published var currentStaff: Staff?

    private init() {
        self.currentUser = auth.currentUser
    }

    // MARK: - Authentication

    @MainActor
    func signIn(email: String, password: String) async throws -> Staff {
        let result = try await auth.signIn(withEmail: email, password: password)
        self.currentUser = result.user

        // Load staff profile
        let staff = try await loadStaffProfile(uid: result.user.uid)

        // Verify staff is active
        guard staff.isActive else {
            try auth.signOut()
            throw NSError(
                domain: "auth", code: 401,
                userInfo: [NSLocalizedDescriptionKey: "Account is inactive"])
        }

        self.currentStaff = staff
        return staff
    }

    @MainActor
    func signOut() throws {
        try auth.signOut()
        self.currentUser = nil
        self.currentStaff = nil
    }

    func getCurrentUser() -> User? {
        return auth.currentUser
    }

    // MARK: - Staff

    func loadStaffProfile(uid: String) async throws -> Staff {
        let docRef = db.collection("staff").document(uid)
        let snapshot = try await docRef.getDocument()

        guard snapshot.exists else {
            throw NSError(
                domain: "firestore", code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Staff profile not found"])
        }

        return try Staff(from: snapshot)
    }

    func updateLastLogin(staffId: String) async throws {
        let docRef = db.collection("staff").document(staffId)
        try await docRef.updateData([
            "lastLoginAt": FieldValue.serverTimestamp()
        ])
    }

    // MARK: - Students

    func loadStudents(schoolId: String) async throws -> [Student] {
        let querySnapshot =
            try await db
            .collection("schools").document(schoolId)
            .collection("students")
            .whereField("status", isEqualTo: "Registered")
            .getDocuments()

        var students: [Student] = []

        for document in querySnapshot.documents {
            do {
                let student = try Student(from: document)
                // Only include students with face encodings
                if student.hasFaceEncoding {
                    students.append(student)
                }
            } catch {
                print("⚠️ Error parsing student \(document.documentID): \(error)")
            }
        }

        print("✅ Loaded \(students.count) students with face encodings")
        return students
    }

    func loadStudentEncodings(schoolId: String) async throws -> [StudentEncoding] {
        let students = try await loadStudents(schoolId: schoolId)

        return students.compactMap { student in
            guard let encoding = student.faceEncoding else { return nil }
            return StudentEncoding(
                id: student.id,
                name: student.fullName,
                encoding: encoding,
                parentName: student.parentName,
                parentContact: student.parentContact
            )
        }
    }

    // MARK: - School

    func loadSchool(schoolId: String) async throws -> School {
        let docRef = db.collection("schools").document(schoolId)
        let snapshot = try await docRef.getDocument()

        guard snapshot.exists else {
            throw NSError(
                domain: "firestore", code: 404,
                userInfo: [NSLocalizedDescriptionKey: "School not found"])
        }

        return try School(from: snapshot)
    }

    /// Load all active schools from Firestore
    /// Used for login dropdown and global user school switching
    func loadAllSchools() async throws -> [School] {
        print("🔍 Fetching schools from Firestore...")

        // First try to get all schools, then filter by isActive
        // This handles cases where isActive field might not exist
        let querySnapshot = try await db.collection("schools").getDocuments()

        print("📊 Found \(querySnapshot.documents.count) total school documents")

        var schools: [School] = []

        for document in querySnapshot.documents {
            print("  📄 Processing school: \(document.documentID)")
            do {
                let school = try School(from: document)
                print("    - Name: \(school.name), isActive: \(school.isActive)")
                // Include school if isActive is true (default is true if field missing)
                if school.isActive {
                    schools.append(school)
                } else {
                    print("    ⏭️ Skipped (isActive = false)")
                }
            } catch {
                print("⚠️ Error parsing school \(document.documentID): \(error)")
            }
        }

        // Sort by name for consistent display
        schools.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

        print("✅ Loaded \(schools.count) active schools: \(schools.map { $0.name })")
        return schools
    }

    // MARK: - Get Student

    func getStudent(schoolId: String, studentId: String) async throws -> Student? {
        let snapshot = try await db.collection("schools")
            .document(schoolId)
            .collection("students")
            .document(studentId)
            .getDocument()

        guard snapshot.exists else {
            return nil
        }

        return try Student(from: snapshot)
    }

    // MARK: - Attendance Logs

    func recordAttendance(schoolId: String, studentId: String) async throws {
        let logId = UUID().uuidString
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let attendanceData: [String: Any] = [
            "id": logId,
            "studentId": studentId,
            "checkInTime": isoFormatter.string(from: Date()),
        ]

        try await db.collection("schools")
            .document(schoolId)
            .collection("students")
            .document(studentId)
            .collection("attendanceLogs")
            .document(logId)
            .setData(attendanceData)

        print("✅ Attendance recorded for student \(studentId)")
    }

    // MARK: - Login Pictures (Temporary for Testing)

    func saveLoginPicture(image: UIImage, staffId: String, schoolId: String) async throws -> String
    {
        // Resize image to fit within Firestore limits (1MB per field)
        // Target: ~800KB after base64 encoding to leave room for overhead
        let resizedImage = resizeImageToFitFirestore(image: image, maxSizeKB: 600)

        // Convert image to JPEG data with compression
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            throw NSError(
                domain: "firestore", code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }

        // Convert to base64 string
        let base64String = imageData.base64EncodedString()
        let dataUri = "data:image/jpeg;base64,\(base64String)"

        // Check size (Firestore limit is ~1MB per field)
        let sizeKB = dataUri.count / 1024
        print("📊 Image data size: \(sizeKB) KB")

        if sizeKB > 1000 {
            throw NSError(
                domain: "firestore", code: 400,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Image too large after compression (\(sizeKB) KB). Please use a smaller image."
                ])
        }

        // Create document in login-pictures collection under schools
        let pictureId = UUID().uuidString
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let pictureData: [String: Any] = [
            "id": pictureId,
            "staffId": staffId,
            "schoolId": schoolId,
            "imageData": dataUri,
            "capturedAt": isoFormatter.string(from: Date()),
            "timestamp": FieldValue.serverTimestamp(),
        ]

        // Save to nested path: /schools/{schoolId}/login-pictures/{pictureId}
        try await db.collection("schools")
            .document(schoolId)
            .collection("login-pictures")
            .document(pictureId)
            .setData(pictureData)

        print("✅ Login picture saved to /schools/\(schoolId)/login-pictures/\(pictureId)")
        return pictureId
    }

    func loadLoginPicture(pictureId: String, schoolId: String) async throws -> [String: Any] {
        let docRef = db.collection("schools")
            .document(schoolId)
            .collection("login-pictures")
            .document(pictureId)

        let snapshot = try await docRef.getDocument()

        guard snapshot.exists else {
            throw NSError(
                domain: "firestore", code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Login picture not found"])
        }

        guard let data = snapshot.data() else {
            throw NSError(
                domain: "firestore", code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Failed to parse picture data"])
        }

        print("✅ Login picture retrieved from /schools/\(schoolId)/login-pictures/\(pictureId)")
        return data
    }

    // MARK: - Face Data Download

    /// Download face data from Firestore faceData collection
    /// Filters out invalid encodings (empty, placeholder, no landmarks)
    /// Only includes face data for students with "Registered" status
    func downloadFaceData(schoolId: String, progressHandler: ((Int, Int) -> Void)? = nil)
        async throws -> [FaceDataDocument]
    {
        print("📥 Starting face data download for school: \(schoolId)")

        // Step 1: Get all registered students first
        let registeredStudentIds = try await getRegisteredStudentIds(schoolId: schoolId)
        print("📋 Found \(registeredStudentIds.count) registered students")

        // Step 2: Get all face data documents
        let querySnapshot =
            try await db
            .collection("schools").document(schoolId)
            .collection("faceData")
            .order(by: "studentId")
            .getDocuments()

        let totalDocs = querySnapshot.documents.count
        print("📊 Found \(totalDocs) face data documents")

        var faceDataList: [FaceDataDocument] = []
        var processedCount = 0
        var skippedCount = 0
        var skippedNonRegistered = 0

        for document in querySnapshot.documents {
            processedCount += 1
            progressHandler?(processedCount, totalDocs)

            let data = document.data()

            // Extract required fields
            guard let faceDataId = data["faceDataId"] as? String,
                let studentId = data["studentId"] as? String,
                let studentDocId = data["studentDocId"] as? String,
                let studentName = data["studentName"] as? String,
                let encoding = data["encoding"] as? String
            else {
                skippedCount += 1
                continue
            }

            // Skip face data for non-registered students
            if !registeredStudentIds.contains(studentId) {
                skippedNonRegistered += 1
                print("⏭️ Skipping face data for non-registered student: \(studentName)")
                continue
            }

            // Validate encoding - skip invalid ones
            guard isValidEncoding(encoding) else {
                skippedCount += 1
                print("⏭️ Skipping invalid encoding for \(studentName): \(encoding.prefix(30))...")
                continue
            }

            // Parse optional fields
            let className = data["className"] as? String
            let parentId = data["parentId"] as? String
            let sampleIndex = data["sampleIndex"] as? Int ?? 0
            let faceConfidence = data["faceConfidence"] as? Double ?? 0.0
            let version = data["version"] as? Int ?? 1
            let isOrphaned = data["isOrphaned"] as? Bool ?? false

            // Parse dates
            let createdAt = parseFirestoreDate(data["createdAt"]) ?? ""
            let updatedAt = parseFirestoreDate(data["updatedAt"]) ?? ""

            // Skip orphaned records
            if isOrphaned {
                skippedCount += 1
                continue
            }

            let faceData = FaceDataDocument(
                faceDataId: faceDataId,
                studentId: studentId,
                studentDocId: studentDocId,
                studentName: studentName,
                className: className,
                parentId: parentId,
                sampleIndex: sampleIndex,
                encoding: encoding,
                faceConfidence: faceConfidence,
                version: version,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isOrphaned: isOrphaned
            )

            faceDataList.append(faceData)
        }

        print("✅ Downloaded \(faceDataList.count) valid face records")
        print("   ⏭️ Skipped \(skippedCount) invalid records")
        print("   ⏭️ Skipped \(skippedNonRegistered) non-registered student records")
        return faceDataList
    }

    /// Get IDs of all students with "Registered" status
    private func getRegisteredStudentIds(schoolId: String) async throws -> Set<String> {
        let querySnapshot =
            try await db
            .collection("schools").document(schoolId)
            .collection("students")
            .whereField("status", isEqualTo: "Registered")
            .getDocuments()

        var studentIds = Set<String>()
        for document in querySnapshot.documents {
            studentIds.insert(document.documentID)
        }

        return studentIds
    }

    /// Get face data version metadata
    func getFaceDataVersion(schoolId: String) async throws -> Int {
        let docRef = db.collection("schools").document(schoolId)
            .collection("faceDataMeta").document("version")

        let snapshot = try await docRef.getDocument()

        guard snapshot.exists,
            let data = snapshot.data(),
            let version = data["currentVersion"] as? Int
        else {
            return 0
        }

        return version
    }

    // MARK: - Validation Helpers

    private func isValidEncoding(_ encoding: String) -> Bool {
        // Skip empty
        guard !encoding.isEmpty else { return false }

        // Skip placeholder encodings (e.g., "encoded_1764572452696_3")
        guard !encoding.hasPrefix("encoded_") else { return false }

        // Must contain landmarks
        guard encoding.contains("landmarks") else { return false }

        return true
    }

    private func parseFirestoreDate(_ value: Any?) -> String? {
        if let timestamp = value as? Timestamp {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter.string(from: timestamp.dateValue())
        }
        if let dateString = value as? String {
            return dateString
        }
        return nil
    }

    // MARK: - Helper Functions

    private func resizeImageToFitFirestore(image: UIImage, maxSizeKB: Int) -> UIImage {
        // Start with a reasonable size that should fit
        var targetWidth: CGFloat = 800
        var targetHeight: CGFloat = 800

        // Calculate aspect ratio
        let aspectRatio = image.size.width / image.size.height

        if aspectRatio > 1 {
            // Landscape
            targetHeight = targetWidth / aspectRatio
        } else {
            // Portrait
            targetWidth = targetHeight * aspectRatio
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
}
