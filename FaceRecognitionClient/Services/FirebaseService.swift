//
//  FirebaseService.swift
//  FaceRecognitionClient
//
//  Created on November 28, 2025.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

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
            throw NSError(domain: "auth", code: 401,
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
            throw NSError(domain: "firestore", code: 404,
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
        let querySnapshot = try await db
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
            throw NSError(domain: "firestore", code: 404,
                         userInfo: [NSLocalizedDescriptionKey: "School not found"])
        }
        
        return try School(from: snapshot)
    }
    
    // MARK: - Attendance Logs
    
    func recordAttendance(schoolId: String, studentId: String) async throws {
        let logId = UUID().uuidString
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let attendanceData: [String: Any] = [
            "id": logId,
            "studentId": studentId,
            "checkInTime": isoFormatter.string(from: Date())
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
    
    func saveLoginPicture(image: UIImage, staffId: String, schoolId: String) async throws -> String {
        // Resize image to fit within Firestore limits (1MB per field)
        // Target: ~800KB after base64 encoding to leave room for overhead
        let resizedImage = resizeImageToFitFirestore(image: image, maxSizeKB: 600)
        
        // Convert image to JPEG data with compression
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "firestore", code: 400,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        // Convert to base64 string
        let base64String = imageData.base64EncodedString()
        let dataUri = "data:image/jpeg;base64,\(base64String)"
        
        // Check size (Firestore limit is ~1MB per field)
        let sizeKB = dataUri.count / 1024
        print("📊 Image data size: \(sizeKB) KB")
        
        if sizeKB > 1000 {
            throw NSError(domain: "firestore", code: 400,
                         userInfo: [NSLocalizedDescriptionKey: "Image too large after compression (\(sizeKB) KB). Please use a smaller image."])
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
            "timestamp": FieldValue.serverTimestamp()
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
            throw NSError(domain: "firestore", code: 404,
                         userInfo: [NSLocalizedDescriptionKey: "Login picture not found"])
        }
        
        guard let data = snapshot.data() else {
            throw NSError(domain: "firestore", code: 500,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to parse picture data"])
        }
        
        print("✅ Login picture retrieved from /schools/\(schoolId)/login-pictures/\(pictureId)")
        return data
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
        
        print("📐 Resized image from \(Int(image.size.width))x\(Int(image.size.height)) to \(Int(finalImage.size.width))x\(Int(finalImage.size.height))")
        return finalImage
    }
}
