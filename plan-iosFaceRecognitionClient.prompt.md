# iOS Client - Face Recognition Attendance System

## Project Specification Document

**Project Name:** FaceCheck iOS Client  
**Version:** 1.0  
**Last Updated:** November 28, 2025  
**Language:** Swift  
**Platform:** iOS 15.0+

---

## 📋 Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture & Technology Stack](#architecture--technology-stack)
3. [Firebase Configuration](#firebase-configuration)
4. [User Flow & Screens](#user-flow--screens)
5. [Data Models](#data-models)
6. [API Integration](#api-integration)
7. [Face Recognition Implementation](#face-recognition-implementation)
8. [WhatsApp Integration](#whatsapp-integration)
9. [Security & Authentication](#security--authentication)
10. [UI/UX Guidelines](#uiux-guidelines)
11. [Implementation Steps](#implementation-steps)
12. [Code Structure](#code-structure)
13. [Testing Guidelines](#testing-guidelines)

---

## 1. Project Overview

### 1.1 Purpose

A lightweight iOS application for tuition center staff to perform face recognition-based student attendance check-in. When a student's face is recognized, the system automatically sends a WhatsApp notification to their parent.

### 1.2 Key Features

- ✅ Tuition center code selection (persistent)
- ✅ Staff authentication
- ✅ Real-time face detection and recognition
- ✅ Visual feedback (green/red status)
- ✅ Automatic WhatsApp notification to parents
- ✅ Offline face recognition capability
- ✅ Simple, single-purpose interface

### 1.3 Target Users

- Reception staff
- Teachers
- Administrators
- Operating on iPad or iPhone

---

## 2. Architecture & Technology Stack

### 2.1 iOS Technologies

```swift
// Core Frameworks
import UIKit                    // UI Components
import AVFoundation             // Camera access
import Vision                   // Face detection
import CoreML                   // Face recognition model
import FirebaseAuth             // Authentication
import FirebaseFirestore        // Database
import FirebaseStorage          // Image storage

// Third-party Libraries (via Swift Package Manager)
- Firebase iOS SDK (10.x)
- WhatsApp Business API SDK (if available) or URL scheme
```

### 2.2 Architecture Pattern

**MVVM (Model-View-ViewModel)** with Coordinators

```
📁 iOS-Client/
├── 📁 App/
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   └── Info.plist
├── 📁 Models/
│   ├── School.swift
│   ├── Staff.swift
│   ├── Student.swift
│   └── FaceMatch.swift
├── 📁 ViewModels/
│   ├── LoginViewModel.swift
│   ├── CameraViewModel.swift
│   └── AuthViewModel.swift
├── 📁 Views/
│   ├── LoginViewController.swift
│   ├── CameraViewController.swift
│   └── Components/
│       ├── StatusView.swift
│       └── CameraPreviewView.swift
├── 📁 Services/
│   ├── FirebaseService.swift
│   ├── FaceRecognitionService.swift
│   ├── WhatsAppService.swift
│   └── KeychainService.swift
├── 📁 Utilities/
│   ├── Extensions.swift
│   ├── Constants.swift
│   └── Helpers.swift
└── 📁 Resources/
    ├── Assets.xcassets
    └── GoogleService-Info.plist
```

---

## 3. Firebase Configuration

### 3.1 Firebase Project

**Project ID:** `studio-4796520355-68573`  
**Region:** asia-southeast1

### 3.2 Firebase Services Used

1. **Authentication** - Staff login
2. **Firestore** - Read student & school data
3. **Storage** - Download face encoding data

### 3.3 iOS Setup Steps

```bash
# 1. Add iOS app in Firebase Console
# Bundle ID: com.yourcompany.facecheckclient

# 2. Download GoogleService-Info.plist

# 3. Add Firebase SDK via Swift Package Manager
https://github.com/firebase/firebase-ios-sdk
```

### 3.4 Firestore Data Structure (Read-Only)

```
/staff/{staffId}
  - email: string
  - role: string
  - schoolId: string
  - isActive: boolean

/schools/{schoolId}
  - name: string
  - isActive: boolean

  /students/{studentId}
    - firstName: string
    - lastName: string
    - parentName: string
    - parentContact: string (phone with country code)
    - status: string
    - faceEncoding: string (base64 encoded face embedding)

    /faceSamples/{sampleId}
      - imageUrl: string
      - uploadedAt: timestamp
```

### 3.5 Security Rules (iOS App Permissions)

The iOS app will use the same Firestore rules as the web app:

- Staff must be authenticated
- Can only access data for their assigned school
- Read-only access to student data
- Cannot modify student records (attendance logging will be added later)

---

## 4. User Flow & Screens

### 4.1 Screen Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                                                               │
│  [Launch Screen]                                             │
│        ↓                                                      │
│  Check saved credentials                                     │
│        ↓                                                      │
│  ┌─────────────────┬─────────────────────────────────────┐  │
│  │                 │                                       │  │
│  │  No credentials │  Has credentials                     │  │
│  │        ↓        │         ↓                            │  │
│  │  [Login Screen] │  Auto-login → [Camera Screen]       │  │
│  │                 │                                       │  │
│  └─────────────────┴───────────────────────────────────────┘  │
│                                                               │
│  Login Screen                                                │
│  ├─ Tuition Center Code input (dropdown or text)            │
│  ├─ Email input                                              │
│  ├─ Password input                                           │
│  └─ Login button                                             │
│        ↓                                                      │
│  Validate & Authenticate                                     │
│        ↓                                                      │
│  Save credentials to Keychain                                │
│        ↓                                                      │
│  [Camera Screen]                                             │
│  ├─ Camera preview (full screen)                            │
│  ├─ Face detection overlay                                   │
│  ├─ Status indicator (top)                                   │
│  │   └─ "Scanning..." / "Access OK" / "Access FAILED"       │
│  └─ Logout button (top right)                               │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 Screen Specifications

#### 4.2.1 Login Screen

**Purpose:** Authenticate staff and select tuition center

**UI Components:**

```swift
// Login Screen Layout
┌─────────────────────────────────────┐
│                                     │
│         📚 FaceCheck Client         │
│         Tuition Center Login        │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ Tuition Center Code           │ │
│  │ [main-tuition-center    ▼]    │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ Email                         │ │
│  │ staff@example.com             │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │ Password                      │ │
│  │ ●●●●●●●●                      │ │
│  └───────────────────────────────┘ │
│                                     │
│  [ Remember Me ] ☑️                │
│                                     │
│  ┌───────────────────────────────┐ │
│  │        LOGIN                  │ │
│  └───────────────────────────────┘ │
│                                     │
│  Status: Ready to login             │
│                                     │
└─────────────────────────────────────┘
```

**Validation Rules:**

- Tuition center code: Required, alphanumeric
- Email: Required, valid email format
- Password: Required, minimum 6 characters
- All fields must match existing Firebase staff account

**Persistence:**

- Save tuition center code to UserDefaults
- Save email to Keychain (if "Remember Me" checked)
- Never save password in plain text

#### 4.2.2 Camera Screen

**Purpose:** Detect and recognize student faces

**UI Components:**

```swift
// Camera Screen Layout
┌─────────────────────────────────────┐
│  [Logout]              [Staff: Ian] │ ← Top Bar
│─────────────────────────────────────│
│                                     │
│                                     │
│         📷 Camera Preview           │
│                                     │
│     ┌─────────────────────┐         │
│     │                     │         │ ← Face Detection Box
│     │   Face Detected     │         │   (drawn when face found)
│     │                     │         │
│     └─────────────────────┘         │
│                                     │
│                                     │
│─────────────────────────────────────│
│                                     │
│  ┌───────────────────────────────┐ │
│  │                               │ │
│  │      STATUS: Scanning...      │ │ ← Status Area
│  │                               │ │   (changes color)
│  └───────────────────────────────┘ │
│                                     │
│  Last Check: -                      │
│  Student: -                         │
│                                     │
└─────────────────────────────────────┘
```

**Status States:**

1. **Scanning (Blue)** - Camera active, no face detected
2. **Processing (Yellow)** - Face detected, comparing with database
3. **Access OK (Green)** - Student recognized, sending WhatsApp
4. **Access FAILED (Red)** - Face not recognized or unauthorized

**Camera Features:**

- Continuous face detection
- Front or rear camera (configurable)
- Auto-focus on faces
- Face detection overlay (bounding box)
- Real-time processing

---

## 5. Data Models

### 5.1 School Model

```swift
// Models/School.swift
import Foundation

struct School: Codable, Identifiable {
    let id: String              // "main-tuition-center"
    let name: String            // "Main Tuition Center"
    let address: String?
    let phone: String?
    let isActive: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
        case phone
        case isActive
        case createdAt
    }
}
```

### 5.2 Staff Model

```swift
// Models/Staff.swift
import Foundation

enum StaffRole: String, Codable {
    case admin = "admin"
    case teacher = "teacher"
    case reception = "reception"
}

struct Staff: Codable, Identifiable {
    let id: String              // Firebase Auth UID
    let email: String
    let displayName: String
    let role: StaffRole
    let schoolId: String
    let isActive: Bool
    let createdAt: Date
    let lastLoginAt: Date?

    var canAccessCamera: Bool {
        return isActive && (role == .admin || role == .reception)
    }
}
```

### 5.3 Student Model

```swift
// Models/Student.swift
import Foundation

enum StudentStatus: String, Codable {
    case active = "Active"
    case inactive = "Inactive"
    case deleted = "Deleted"
}

struct Student: Codable, Identifiable {
    let id: String
    let firstName: String
    let lastName: String
    let parentName: String
    let parentContact: String      // E.164 format: +60123456789
    let status: StudentStatus
    let className: String
    let faceEncoding: String?      // Base64 encoded face embedding
    let registrationDate: Date?
    let updatedAt: Date?

    var fullName: String {
        return "\(firstName) \(lastName)"
    }

    var isActive: Bool {
        return status == .active
    }

    var hasFaceEncoding: Bool {
        return faceEncoding != nil && !faceEncoding!.isEmpty
    }
}
```

### 5.4 Face Match Result

```swift
// Models/FaceMatch.swift
import Foundation

struct FaceMatchResult {
    let student: Student
    let confidence: Float          // 0.0 to 1.0
    let matchTimestamp: Date
    let processingTime: TimeInterval

    var isValidMatch: Bool {
        return confidence >= 0.7   // 70% threshold
    }
}

enum FaceRecognitionError: Error {
    case noFaceDetected
    case multipleFacesDetected
    case noMatch
    case encodingFailed
    case databaseError(String)
    case lowConfidence

    var localizedDescription: String {
        switch self {
        case .noFaceDetected:
            return "No face detected in frame"
        case .multipleFacesDetected:
            return "Multiple faces detected. Please ensure only one person is visible."
        case .noMatch:
            return "Face not recognized. Please try again."
        case .encodingFailed:
            return "Failed to process face data"
        case .databaseError(let message):
            return "Database error: \(message)"
        case .lowConfidence:
            return "Recognition confidence too low"
        }
    }
}
```

---

## 6. API Integration

### 6.1 Firebase Service

```swift
// Services/FirebaseService.swift
import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class FirebaseService {
    static let shared = FirebaseService()
    private let db = Firestore.firestore()
    private let auth = Auth.auth()

    private init() {}

    // MARK: - Authentication

    func signIn(email: String, password: String) async throws -> Staff {
        let result = try await auth.signIn(withEmail: email, password: password)

        // Load staff profile
        let staff = try await loadStaffProfile(uid: result.user.uid)

        // Verify staff is active
        guard staff.isActive else {
            try auth.signOut()
            throw NSError(domain: "auth", code: 401,
                         userInfo: [NSLocalizedDescriptionKey: "Account is inactive"])
        }

        return staff
    }

    func signOut() throws {
        try auth.signOut()
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

        let data = snapshot.data()!
        return Staff(
            id: snapshot.documentID,
            email: data["email"] as! String,
            displayName: data["displayName"] as! String,
            role: StaffRole(rawValue: data["role"] as! String)!,
            schoolId: data["schoolId"] as! String,
            isActive: data["isActive"] as? Bool ?? true,
            createdAt: (data["createdAt"] as! Timestamp).dateValue(),
            lastLoginAt: (data["lastLoginAt"] as? Timestamp)?.dateValue()
        )
    }

    // MARK: - Students

    func loadStudents(schoolId: String) async throws -> [Student] {
        let querySnapshot = try await db
            .collection("schools").document(schoolId)
            .collection("students")
            .whereField("status", isEqualTo: "Active")
            .getDocuments()

        var students: [Student] = []

        for document in querySnapshot.documents {
            let data = document.data()
            let student = Student(
                id: document.documentID,
                firstName: data["firstName"] as! String,
                lastName: data["lastName"] as! String,
                parentName: data["parentName"] as! String,
                parentContact: data["parentContact"] as! String,
                status: StudentStatus(rawValue: data["status"] as! String) ?? .active,
                className: data["class"] as! String,
                faceEncoding: data["faceEncoding"] as? String,
                registrationDate: (data["registrationDate"] as? Timestamp)?.dateValue(),
                updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue()
            )

            // Only include students with face encodings
            if student.hasFaceEncoding {
                students.append(student)
            }
        }

        return students
    }

    // MARK: - School

    func loadSchool(schoolId: String) async throws -> School {
        let docRef = db.collection("schools").document(schoolId)
        let snapshot = try await docRef.getDocument()

        guard snapshot.exists else {
            throw NSError(domain: "firestore", code: 404,
                         userInfo: [NSLocalizedDescriptionKey: "School not found"])
        }

        let data = snapshot.data()!
        return School(
            id: snapshot.documentID,
            name: data["name"] as! String,
            address: data["address"] as? String,
            phone: data["phone"] as? String,
            isActive: data["isActive"] as? Bool ?? true,
            createdAt: (data["createdAt"] as! Timestamp).dateValue()
        )
    }
}
```

---

## 7. Face Recognition Implementation

### 7.1 Face Recognition Service

```swift
// Services/FaceRecognitionService.swift
import Foundation
import Vision
import CoreML
import UIKit

class FaceRecognitionService {
    static let shared = FaceRecognitionService()

    private var studentEncodings: [String: [Float]] = [:]  // studentId: encoding
    private var students: [Student] = []

    private let recognitionThreshold: Float = 0.7  // 70% similarity

    private init() {}

    // MARK: - Setup

    func loadStudentData(_ students: [Student]) {
        self.students = students
        self.studentEncodings.removeAll()

        for student in students {
            if let encodingString = student.faceEncoding,
               let encoding = decodeBase64ToFloatArray(encodingString) {
                studentEncodings[student.id] = encoding
            }
        }

        print("✅ Loaded \(studentEncodings.count) student face encodings")
    }

    // MARK: - Face Detection & Recognition

    func detectAndRecognizeFace(in image: UIImage) async throws -> FaceMatchResult {
        let startTime = Date()

        // Step 1: Detect face
        guard let cgImage = image.cgImage else {
            throw FaceRecognitionError.encodingFailed
        }

        let faces = try await detectFaces(in: cgImage)

        guard faces.count == 1 else {
            if faces.isEmpty {
                throw FaceRecognitionError.noFaceDetected
            } else {
                throw FaceRecognitionError.multipleFacesDetected
            }
        }

        // Step 2: Extract face encoding
        let faceEncoding = try await extractFaceEncoding(from: cgImage, face: faces[0])

        // Step 3: Compare with database
        let matchResult = try findBestMatch(for: faceEncoding)

        let processingTime = Date().timeIntervalSince(startTime)

        return FaceMatchResult(
            student: matchResult.student,
            confidence: matchResult.confidence,
            matchTimestamp: Date(),
            processingTime: processingTime
        )
    }

    // MARK: - Face Detection

    private func detectFaces(in image: CGImage) async throws -> [VNFaceObservation] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectFaceRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let results = request.results as? [VNFaceObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                continuation.resume(returning: results)
            }

            let handler = VNImageRequestHandler(cgImage: image, options: [:])

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Face Encoding Extraction

    private func extractFaceEncoding(from image: CGImage, face: VNFaceObservation) async throws -> [Float] {
        // This is a placeholder - you'll need to implement actual face encoding
        // Options:
        // 1. Use Apple's Vision framework with face landmarks
        // 2. Use a pre-trained CoreML model (like FaceNet or ArcFace)
        // 3. Call your backend API for encoding

        // For now, returning a mock encoding
        // TODO: Implement actual face encoding using CoreML model

        return try await withCheckedThrowingContinuation { continuation in
            // Placeholder implementation
            let mockEncoding = (0..<128).map { _ in Float.random(in: -1...1) }
            continuation.resume(returning: mockEncoding)
        }
    }

    // MARK: - Face Matching

    private func findBestMatch(for encoding: [Float]) throws -> (student: Student, confidence: Float) {
        var bestMatch: (student: Student, confidence: Float)?

        for (studentId, studentEncoding) in studentEncodings {
            let similarity = cosineSimilarity(encoding, studentEncoding)

            if similarity >= recognitionThreshold {
                if bestMatch == nil || similarity > bestMatch!.confidence {
                    if let student = students.first(where: { $0.id == studentId }) {
                        bestMatch = (student, similarity)
                    }
                }
            }
        }

        guard let match = bestMatch else {
            throw FaceRecognitionError.noMatch
        }

        return match
    }

    // MARK: - Helper Functions

    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0.0 }

        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))

        guard magnitudeA > 0 && magnitudeB > 0 else { return 0.0 }

        return dotProduct / (magnitudeA * magnitudeB)
    }

    private func decodeBase64ToFloatArray(_ base64String: String) -> [Float]? {
        guard let data = Data(base64Encoded: base64String) else {
            return nil
        }

        let floatCount = data.count / MemoryLayout<Float>.size
        var floatArray = [Float](repeating: 0, count: floatCount)

        data.withUnsafeBytes { rawBufferPointer in
            let bufferPointer = rawBufferPointer.bindMemory(to: Float.self)
            floatArray = Array(bufferPointer)
        }

        return floatArray
    }
}
```

### 7.2 Face Encoding Notes

⚠️ **IMPORTANT:** The face encoding extraction is a placeholder. You need to:

1. **Option A: Use the same model as web app**

   - Port the face encoding model to CoreML
   - Ensure consistency with web app encodings

2. **Option B: Use native iOS solution**

   - Use Vision framework's face landmarks
   - Convert to embedding vector
   - May not match web app encodings exactly

3. **Option C: Server-side encoding (Recommended for MVP)**
   - Capture face image on iOS
   - Send to your backend API
   - Backend uses same model as web app
   - Return encoding to iOS for local comparison

**Recommendation:** Start with Option C for consistency, then optimize to on-device later.

---

## 8. WhatsApp Integration

### 8.1 WhatsApp Service

```swift
// Services/WhatsAppService.swift
import Foundation
import UIKit

class WhatsAppService {
    static let shared = WhatsAppService()

    private init() {}

    // MARK: - Send Message

    func sendAttendanceNotification(to phoneNumber: String, studentName: String) async throws {
        let message = """
        ✅ Attendance Confirmed

        Hello! Your child \(studentName) has successfully checked in at the tuition center.

        Time: \(formatTime(Date()))
        Date: \(formatDate(Date()))

        Thank you!
        - Main Tuition Center
        """

        try await sendWhatsAppMessage(to: phoneNumber, message: message)
    }

    // MARK: - WhatsApp Methods

    private func sendWhatsAppMessage(to phoneNumber: String, message: String) async throws {
        // Clean phone number (remove spaces, dashes, etc.)
        let cleanNumber = phoneNumber.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)

        // URL encode message
        guard let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw NSError(domain: "whatsapp", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to encode message"])
        }

        // Try WhatsApp URL scheme
        let whatsappURL = "whatsapp://send?phone=\(cleanNumber)&text=\(encodedMessage)"

        guard let url = URL(string: whatsappURL) else {
            throw NSError(domain: "whatsapp", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        // Check if WhatsApp is installed
        if await UIApplication.shared.canOpenURL(url) {
            await UIApplication.shared.open(url)
        } else {
            // Fallback to web WhatsApp
            let webURL = "https://wa.me/\(cleanNumber)?text=\(encodedMessage)"
            if let webUrl = URL(string: webURL) {
                await UIApplication.shared.open(webUrl)
            } else {
                throw NSError(domain: "whatsapp", code: 404, userInfo: [NSLocalizedDescriptionKey: "WhatsApp not available"])
            }
        }
    }

    // MARK: - Helper Functions

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
```

### 8.2 WhatsApp URL Scheme Configuration

Add to `Info.plist`:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>whatsapp</string>
</array>
```

### 8.3 Alternative: WhatsApp Business API

For production use, consider:

- **WhatsApp Business API** (requires business verification)
- **Twilio API** for WhatsApp messaging
- **MessageBird** or similar services

This allows automated messaging without opening the WhatsApp app.

---

## 9. Security & Authentication

### 9.1 Keychain Service

```swift
// Services/KeychainService.swift
import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()

    private let service = "com.yourcompany.facecheckclient"

    private init() {}

    // MARK: - Save

    func save(key: String, value: String) -> Bool {
        let data = value.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        // Delete any existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Load

    func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    // MARK: - Delete

    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
}

// Usage:
// KeychainService.shared.save(key: "email", value: "user@example.com")
// let email = KeychainService.shared.load(key: "email")
```

### 9.2 Credential Storage

```swift
struct CredentialKeys {
    static let schoolCode = "schoolCode"
    static let email = "email"
    // Never store password
}

// Save credentials after successful login
func saveCredentials(schoolCode: String, email: String) {
    UserDefaults.standard.set(schoolCode, forKey: CredentialKeys.schoolCode)
    KeychainService.shared.save(key: CredentialKeys.email, value: email)
}

// Load saved credentials
func loadSavedCredentials() -> (schoolCode: String?, email: String?) {
    let schoolCode = UserDefaults.standard.string(forKey: CredentialKeys.schoolCode)
    let email = KeychainService.shared.load(key: CredentialKeys.email)
    return (schoolCode, email)
}
```

---

## 10. UI/UX Guidelines

### 10.1 Design Principles

1. **Simplicity First** - Single-purpose screens
2. **Large Touch Targets** - 44pt minimum
3. **Clear Feedback** - Visual and haptic
4. **Error Recovery** - Clear error messages
5. **Accessibility** - VoiceOver support

### 10.2 Color Scheme

```swift
// Utilities/Constants.swift
enum AppColors {
    static let primary = UIColor.systemBlue
    static let success = UIColor.systemGreen
    static let error = UIColor.systemRed
    static let warning = UIColor.systemOrange
    static let scanning = UIColor.systemBlue

    static let background = UIColor.systemBackground
    static let secondaryBackground = UIColor.secondarySystemBackground
}
```

### 10.3 Typography

```swift
enum AppFonts {
    static let largeTitle = UIFont.systemFont(ofSize: 34, weight: .bold)
    static let title = UIFont.systemFont(ofSize: 28, weight: .bold)
    static let headline = UIFont.systemFont(ofSize: 17, weight: .semibold)
    static let body = UIFont.systemFont(ofSize: 17, weight: .regular)
    static let caption = UIFont.systemFont(ofSize: 12, weight: .regular)
}
```

### 10.4 Animations

```swift
// Smooth transitions
UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
    // Animation code
}

// Haptic feedback
let generator = UINotificationFeedbackGenerator()
generator.notificationOccurred(.success)  // For successful match
generator.notificationOccurred(.error)    // For failed match
```

---

## 11. Implementation Steps

### Phase 1: Project Setup (Day 1)

```bash
1. Create new Xcode project
   - iOS App
   - Bundle ID: com.yourcompany.facecheckclient
   - SwiftUI or UIKit: UIKit
   - Language: Swift

2. Install Firebase SDK
   - Add Firebase package via SPM
   - Download GoogleService-Info.plist
   - Configure Firebase in AppDelegate

3. Setup folder structure
   - Create Models, Views, ViewModels, Services folders
   - Add Constants.swift

4. Configure Info.plist
   - Camera usage description
   - WhatsApp URL scheme
```

### Phase 2: Authentication (Day 2-3)

```bash
1. Create Login Screen
   - UI layout with text fields
   - Form validation
   - Error handling

2. Implement FirebaseService
   - Sign in method
   - Staff profile loading
   - School data loading

3. Implement KeychainService
   - Save/load credentials
   - Auto-login flow

4. Test authentication
   - Valid credentials
   - Invalid credentials
   - Network errors
```

### Phase 3: Camera & Face Detection (Day 4-5)

```bash
1. Create Camera Screen
   - AVCaptureSession setup
   - Camera preview layer
   - Face detection overlay

2. Implement basic face detection
   - Vision framework integration
   - Draw bounding boxes
   - Single face validation

3. Add UI feedback
   - Status indicator
   - Color changes
   - Haptic feedback

4. Test camera functionality
   - Different lighting conditions
   - Various distances
   - Multiple faces handling
```

### Phase 4: Face Recognition (Day 6-7)

```bash
1. Implement FaceRecognitionService
   - Load student encodings from Firestore
   - Face encoding extraction (placeholder first)
   - Similarity comparison

2. Integrate with Camera Screen
   - Capture frames
   - Process faces
   - Display results

3. Add error handling
   - No match found
   - Low confidence
   - Processing errors

4. Test recognition
   - Known students
   - Unknown persons
   - Similar faces
```

### Phase 5: WhatsApp Integration (Day 8)

```bash
1. Implement WhatsAppService
   - URL scheme integration
   - Message formatting
   - Error handling

2. Connect to recognition flow
   - Trigger on successful match
   - Format parent message
   - Handle WhatsApp not installed

3. Test messaging
   - Different phone formats
   - WhatsApp installed/not installed
   - Message delivery
```

### Phase 6: Polish & Testing (Day 9-10)

```bash
1. UI refinement
   - Smooth animations
   - Loading states
   - Error messages

2. Performance optimization
   - Reduce memory usage
   - Optimize face detection
   - Cache student data

3. Comprehensive testing
   - Unit tests for services
   - UI tests for flows
   - Real-world testing

4. Documentation
   - Code comments
   - README
   - User manual
```

---

## 12. Code Structure

### 12.1 View Controller Example

```swift
// Views/CameraViewController.swift
import UIKit
import AVFoundation
import Vision

class CameraViewController: UIViewController {

    // MARK: - Properties

    private let viewModel: CameraViewModel
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    // UI Components
    private let statusView = StatusView()
    private let logoutButton = UIButton()
    private let faceOverlayView = UIView()

    // MARK: - Lifecycle

    init(viewModel: CameraViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCamera()
        bindViewModel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startCamera()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCamera()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .black

        // Add status view
        view.addSubview(statusView)
        statusView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            statusView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            statusView.heightAnchor.constraint(equalToConstant: 120)
        ])

        // Add logout button
        // ... setup logout button
    }

    private func setupCamera() {
        // Camera setup code
    }

    private func bindViewModel() {
        viewModel.onStatusChange = { [weak self] status in
            self?.updateStatus(status)
        }

        viewModel.onMatchFound = { [weak self] match in
            self?.handleMatchFound(match)
        }
    }

    // MARK: - Actions

    private func handleMatchFound(_ match: FaceMatchResult) {
        // Update UI
        statusView.showSuccess(studentName: match.student.fullName)

        // Send WhatsApp
        viewModel.sendWhatsAppNotification(for: match.student)

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    @objc private func logoutTapped() {
        // Handle logout
    }
}
```

### 12.2 ViewModel Example

```swift
// ViewModels/CameraViewModel.swift
import Foundation
import UIKit

enum CameraStatus {
    case scanning
    case processing
    case success(String)  // Student name
    case failed(String)   // Error message
}

class CameraViewModel {

    // MARK: - Properties

    private let firebaseService = FirebaseService.shared
    private let faceRecognitionService = FaceRecognitionService.shared
    private let whatsappService = WhatsAppService.shared

    private var students: [Student] = []
    private var currentStaff: Staff?
    private var currentSchool: School?

    // MARK: - Callbacks

    var onStatusChange: ((CameraStatus) -> Void)?
    var onMatchFound: ((FaceMatchResult) -> Void)?
    var onError: ((Error) -> Void)?

    // MARK: - Lifecycle

    func loadData(staff: Staff, school: School) async {
        self.currentStaff = staff
        self.currentSchool = school

        do {
            students = try await firebaseService.loadStudents(schoolId: school.id)
            faceRecognitionService.loadStudentData(students)
            onStatusChange?(.scanning)
        } catch {
            onError?(error)
        }
    }

    // MARK: - Face Recognition

    func processFrame(_ image: UIImage) async {
        onStatusChange?(.processing)

        do {
            let match = try await faceRecognitionService.detectAndRecognizeFace(in: image)

            if match.isValidMatch {
                onMatchFound?(match)
                onStatusChange?(.success(match.student.fullName))
            } else {
                onStatusChange?(.failed("Low confidence match"))
            }

        } catch let error as FaceRecognitionError {
            onStatusChange?(.failed(error.localizedDescription))
        } catch {
            onError?(error)
        }
    }

    // MARK: - WhatsApp

    func sendWhatsAppNotification(for student: Student) {
        Task {
            do {
                try await whatsappService.sendAttendanceNotification(
                    to: student.parentContact,
                    studentName: student.fullName
                )
            } catch {
                print("⚠️ Failed to send WhatsApp: \(error)")
            }
        }
    }
}
```

---

## 13. Testing Guidelines

### 13.1 Unit Tests

```swift
// iOS-ClientTests/FaceRecognitionServiceTests.swift
import XCTest
@testable import FaceCheckClient

class FaceRecognitionServiceTests: XCTestCase {

    var sut: FaceRecognitionService!

    override func setUp() {
        super.setUp()
        sut = FaceRecognitionService.shared
    }

    func testLoadStudentData() {
        // Given
        let students = createMockStudents()

        // When
        sut.loadStudentData(students)

        // Then
        // Verify encodings loaded correctly
    }

    func testCosineSimilarity() {
        // Test similarity calculation
    }

    private func createMockStudents() -> [Student] {
        // Create test data
        return []
    }
}
```

### 13.2 UI Tests

```swift
// iOS-ClientUITests/LoginFlowTests.swift
import XCTest

class LoginFlowTests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testSuccessfulLogin() {
        // Test valid login
    }

    func testInvalidCredentials() {
        // Test error handling
    }
}
```

### 13.3 Test Checklist

```
Authentication:
☐ Valid login succeeds
☐ Invalid credentials rejected
☐ Network error handled
☐ Auto-login works
☐ Logout clears session

Camera:
☐ Camera permission requested
☐ Camera preview displays
☐ Face detection works
☐ Single face validated
☐ Multiple faces rejected

Recognition:
☐ Known student recognized
☐ Unknown person rejected
☐ Low confidence handled
☐ Processing time acceptable (<2s)
☐ Results displayed correctly

WhatsApp:
☐ Message sent successfully
☐ Phone format validated
☐ WhatsApp not installed handled
☐ Message content correct

Performance:
☐ App launches quickly (<3s)
☐ Camera starts immediately
☐ Recognition real-time (<2s)
☐ Memory usage acceptable
☐ No memory leaks
```

---

## 14. Additional Considerations

### 14.1 Performance Optimization

- Cache student data locally (CoreData)
- Implement frame throttling (process every 3rd frame)
- Use background threads for processing
- Optimize image resolution for detection

### 14.2 Offline Capability

- Store student encodings locally
- Queue WhatsApp messages for retry
- Sync attendance logs when online
- Show offline indicator

### 14.3 Analytics & Monitoring

- Track recognition success rate
- Log error frequencies
- Monitor performance metrics
- User behavior analytics

### 14.4 Future Enhancements

- Multiple tuition center support
- Attendance history view
- Manual student search
- Parent app companion
- Tablet optimization
- Dark mode support

---

## 15. Deployment

### 15.1 App Store Requirements

```
- iOS 15.0+ minimum
- iPhone and iPad support
- All orientations (camera: portrait only)
- Privacy policy URL
- App Store description
- Screenshots (5.5" and 6.5")
- App icon (1024x1024)
```

### 15.2 Provisioning

```
1. Apple Developer Account
2. App ID: com.yourcompany.facecheckclient
3. Provisioning Profile (Development & Distribution)
4. Push Notification certificate (future)
```

### 15.3 Build Configuration

```swift
// Release configuration
- Enable optimization
- Disable debug logs
- Use production Firebase
- Enable bitcode
- Increment build number
```

---

## 16. Support & Maintenance

### 16.1 Known Limitations

- Face recognition requires good lighting
- WhatsApp must be installed (or fallback to web)
- Network required for initial data sync
- Single face at a time only

### 16.2 Troubleshooting

**Camera not working:**

- Check Info.plist permission
- Verify device has camera
- Restart app

**Recognition not working:**

- Check student has face encoding
- Verify network connection
- Check face quality and lighting

**WhatsApp not sending:**

- Verify WhatsApp installed
- Check phone number format
- Verify URL scheme configured

---

## 17. Conclusion

This specification provides a complete blueprint for building the iOS Face Recognition Client. The implementation should take approximately 10 days for an experienced iOS developer.

**Key Success Factors:**

1. ✅ Start with MVP features only
2. ✅ Test thoroughly at each phase
3. ✅ Use existing web app's face encoding format
4. ✅ Prioritize user experience and simplicity
5. ✅ Plan for offline scenarios

**Next Steps:**

1. Create iOS project in Xcode
2. Setup Firebase and download GoogleService-Info.plist
3. Follow Phase 1 implementation steps
4. Refer back to this document for detailed implementation

---

## Appendix

### A. Firebase Configuration Details

```json
{
  "project_info": {
    "project_id": "studio-4796520355-68573",
    "firebase_url": "https://studio-4796520355-68573.firebaseio.com",
    "storage_bucket": "studio-4796520355-68573.appspot.com"
  }
}
```

### B. Required Permissions (Info.plist)

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required to scan student faces for attendance</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access for face recognition testing</string>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>whatsapp</string>
</array>
```

### C. Swift Package Dependencies

```
- Firebase/Auth: 10.x
- Firebase/Firestore: 10.x
- Firebase/Storage: 10.x
```

### D. Contact Information

For questions or clarifications, refer to the main web application codebase or contact the development team.

---

**Document Version:** 1.0  
**Last Updated:** November 28, 2025  
**Author:** Development Team  
**Status:** Ready for Implementation
