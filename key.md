# Firebase Configuration for iOS Swift Client

## Smart Attendance System - Face Recognition

This document contains all necessary Firebase/Firestore configuration and API details for building the iOS Swift client application for student face check-in functionality.

---

## 🔑 Firebase Configuration

### Firebase Project Details

```swift
// Use these values to configure Firebase in your iOS app
let firebaseConfig = [
  "projectId": "studio-4796520355-68573",
  "appId": "1:749344629546:web:703d99a87371cab385f453",
  "apiKey": "AIzaSyD1v8MYDb8HJ2fosj9H8eytWgmzWs-nwa8",
  "authDomain": "studio-4796520355-68573.firebaseapp.com",
  "messagingSenderId": "749344629546"
]
```

### Key Configuration Values

- **Project ID**: `studio-4796520355-68573`
- **App ID**: `1:749344629546:web:703d99a87371cab385f453`
- **API Key**: `AIzaSyD1v8MYDb8HJ2fosj9H8eytWgmzWs-nwa8`
- **Auth Domain**: `studio-4796520355-68573.firebaseapp.com`
- **Messaging Sender ID**: `749344629546`

---

## 📊 Firestore Database Structure

### Security Model

The system uses a **school-based security model** with role-based access control:

- Data is organized by schools for complete isolation
- Staff members can only access data for their assigned school
- Three roles: **Admin**, **Reception**, and **Teacher**

### Key Collections & Paths

#### 1. Staff Collection

**Path**: `/staff/{staffId}`

**Purpose**: Store staff member profiles with roles and school assignments

**Fields**:

- `id` (string) - Unique staff identifier (matches Auth UID)
- `role` (string) - Role type: "admin", "reception", or "teacher"
- `schoolId` (string) - Reference to assigned school
- `isActive` (boolean) - Whether staff member is active
- `firstName` (string)
- `lastName` (string)
- `email` (string)

**Access Rules**:

- Read: Any authenticated user
- Create: User creating their own profile
- Update: User updating own profile OR admin
- Delete: Admin only

---

#### 2. Students Collection

**Path**: `/schools/{schoolId}/students/{studentId}`

**Purpose**: Store student records within a school context

**Fields**:

```swift
struct Student {
    let id: String
    let firstName: String
    let lastName: String
    let `class`: String           // The class/grade student is in
    let parentId: String          // Reference to parent
    let faceEncoding: String      // Face recognition encoding
    let avatarUrl: String?        // Optional profile picture URL
    let status: String            // "Registered", "Pending", or "Deleted"
    let registrationDate: String  // ISO 8601 date format
}
```

**Access Rules**:

- Read: Active staff of the school
- Create: Admin or Reception staff
- Update: Admin or Reception staff
- Delete: Admin only

---

#### 3. Face Samples Sub-Collection

**Path**: `/schools/{schoolId}/students/{studentId}/faceSamples/{sampleId}`

**Purpose**: Store multiple face images for each student (avoid 1MB document limit)

**Fields**:

```swift
struct FaceSample {
    let id: String
    let dataUrl: String  // Data URI format: "data:image/jpeg;base64,..."
}
```

**Access Rules**:

- Read/Write: Active staff of the school

---

#### 4. Classes Collection

**Path**: `/schools/{schoolId}/classes/{classId}`

**Purpose**: Store class definitions within a school

**Fields**:

```swift
struct Class {
    let id: String
    let name: String
    let createdAt: String  // ISO 8601 date format
}
```

**Access Rules**:

- Read: Active staff of the school
- Write: Admin or Reception staff

---

#### 5. Attendance Logs Collection

**Path**: `/schools/{schoolId}/students/{studentId}/attendanceLogs/{attendanceLogId}`

**Purpose**: Track student check-ins (for future implementation)

**Fields**:

```swift
struct AttendanceLog {
    let id: String
    let studentId: String
    let checkInTime: String  // ISO 8601 date-time format
}
```

---

## 🎯 Face Recognition Flow

### Face Encoding Process

The system uses AI-powered face encoding to create unique identifiers for each student's face.

**Flow Name**: `faceEncodingFlow`

**Input**:

```swift
struct FaceEncodingInput {
    let photoDataUri: String  // Format: "data:image/jpeg;base64,<base64_encoded_image>"
}
```

**Output**:

```swift
struct FaceEncodingOutput {
    let faceEncoding: String  // Unique encoding string
}
```

**Current Implementation**:

- Placeholder implementation generates timestamp-based encodings
- Format: `encoding_{timestamp}_{random}`
- **Note**: Real implementation would use dedicated face embedding model

---

### Real-Time Face Matching Process

Used during check-in to match captured face against stored student encodings.

**Flow Name**: `realTimeFaceMatchFlow`

**Input**:

```swift
struct RealTimeFaceMatchInput {
    let faceImageDataUri: String        // Captured face image as data URI
    let storedFaceEncodings: [String]   // Array of encodings to match against
}
```

**Output**:

```swift
struct RealTimeFaceMatchOutput {
    let isMatch: Bool
    let studentId: String?    // ID of matched student (if found)
    let confidence: Double?   // Confidence score 0-1 (if matched)
}
```

**Current Implementation**:

- Placeholder returns match if any encoding exists
- Simulates 0.99 confidence for matches
- **Note**: Real implementation would perform actual face comparison

---

## 📱 iOS Client Implementation Guide

### Required Firebase iOS SDK Pods/SPM

Add these Firebase libraries to your iOS project:

```swift
// Using Swift Package Manager
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
]

// Required products:
.product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
.product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
.product(name: "FirebaseStorage", package: "firebase-ios-sdk")
```

### Initialize Firebase in iOS App

```swift
import Firebase

@main
struct AttendanceApp: App {
    init() {
        // Configure with plist or programmatically
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### GoogleService-Info.plist Configuration

Create a `GoogleService-Info.plist` file with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>PROJECT_ID</key>
    <string>studio-4796520355-68573</string>
    <key>BUNDLE_ID</key>
    <string>YOUR_BUNDLE_ID_HERE</string>
    <key>API_KEY</key>
    <string>AIzaSyD1v8MYDb8HJ2fosj9H8eytWgmzWs-nwa8</string>
    <key>GCM_SENDER_ID</key>
    <string>749344629546</string>
    <key>GOOGLE_APP_ID</key>
    <string>1:749344629546:ios:YOUR_IOS_APP_ID</string>
</dict>
</plist>
```

**Important**: You'll need to register an iOS app in the Firebase Console to get the iOS-specific `GOOGLE_APP_ID` and complete `GoogleService-Info.plist`.

---

## 🔐 Authentication

### Supported Auth Providers

- **Email/Password Authentication**
- **Anonymous Authentication** (for testing)

### Authentication Flow for iOS

```swift
import FirebaseAuth

// Sign in with email/password
func signIn(email: String, password: String) async throws {
    try await Auth.auth().signIn(withEmail: email, password: password)
}

// Get current user
func getCurrentUser() -> User? {
    return Auth.auth().currentUser
}

// Sign out
func signOut() throws {
    try Auth.auth().signOut()
}
```

### Required User Data After Auth

After authentication, fetch the staff profile to determine:

- School ID (schoolId)
- User role (role)
- Active status (isActive)

---

## 📸 Face Check-In Implementation Guide

### Step-by-Step Process for iOS

#### 1. Capture Face Image

```swift
import AVFoundation
import UIKit

// Capture photo from camera
func capturePhoto() -> UIImage? {
    // Use AVCaptureSession to capture image
    // Return UIImage
}
```

#### 2. Convert Image to Data URI

```swift
func imageToDataURI(_ image: UIImage) -> String? {
    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
        return nil
    }
    let base64String = imageData.base64EncodedString()
    return "data:image/jpeg;base64,\(base64String)"
}
```

#### 3. Fetch Student Encodings from Firestore

```swift
import FirebaseFirestore

func fetchStudentEncodings(schoolId: String) async throws -> [StudentEncoding] {
    let db = Firestore.firestore()
    let snapshot = try await db.collection("schools")
        .document(schoolId)
        .collection("students")
        .whereField("status", isEqualTo: "Registered")
        .getDocuments()

    return snapshot.documents.compactMap { doc -> StudentEncoding? in
        guard let firstName = doc.data()["firstName"] as? String,
              let lastName = doc.data()["lastName"] as? String,
              let encoding = doc.data()["faceEncoding"] as? String else {
            return nil
        }
        return StudentEncoding(
            id: doc.documentID,
            name: "\(firstName) \(lastName)",
            encoding: encoding
        )
    }
}

struct StudentEncoding {
    let id: String
    let name: String
    let encoding: String
}
```

#### 4. Perform Face Matching

```swift
// Option A: Client-side matching (compare encodings)
func matchFace(capturedImage: String, students: [StudentEncoding]) -> StudentMatch? {
    // Implement face comparison algorithm
    // For placeholder: just check if encodings exist
    if let firstStudent = students.first {
        return StudentMatch(
            studentId: firstStudent.id,
            studentName: firstStudent.name,
            confidence: 0.99
        )
    }
    return nil
}

struct StudentMatch {
    let studentId: String
    let studentName: String
    let confidence: Double
}
```

#### 5. Record Attendance

```swift
func recordAttendance(schoolId: String, studentId: String) async throws {
    let db = Firestore.firestore()
    let logId = UUID().uuidString

    let attendanceData: [String: Any] = [
        "id": logId,
        "studentId": studentId,
        "checkInTime": ISO8601DateFormatter().string(from: Date())
    ]

    try await db.collection("schools")
        .document(schoolId)
        .collection("students")
        .document(studentId)
        .collection("attendanceLogs")
        .document(logId)
        .setData(attendanceData)
}
```

---

## 🛡️ Security Considerations

### Firestore Security Rules Summary

The security rules enforce:

1. **Authentication Required**: All operations require authenticated user
2. **School Isolation**: Staff can only access data from their assigned school
3. **Role-Based Permissions**:
   - **Admin**: Full CRUD access to all school data
   - **Reception**: Can create/update students and classes (no delete)
   - **Teacher**: Read-only access to students and classes
4. **Active Status**: Only active staff members can access data

### Important Security Notes for iOS

- Always check `isActive` status after authentication
- Cache `schoolId` locally for efficient queries
- Implement offline persistence with caution (sensitive face data)
- Use Firebase Security Rules as primary defense layer
- Never bypass server-side validation

---

## 📐 Data Format Standards

### Date/Time Format

All dates use **ISO 8601 format**:

```swift
// Swift date formatter
let isoFormatter = ISO8601DateFormatter()
isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
let dateString = isoFormatter.string(from: Date())
// Example: "2025-11-28T10:30:45.123Z"
```

### Image Data URI Format

```
data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEAYABgAAD...
```

Components:

- Protocol: `data:`
- MIME type: `image/jpeg` or `image/png`
- Encoding: `base64`
- Data: Base64-encoded image bytes

---

## 🔄 API Endpoints (if using Cloud Functions)

Currently, the web app uses client-side AI flows. For iOS, you may need to expose these as HTTP endpoints.

### Recommended Cloud Function Endpoints

#### Face Encoding Endpoint

```
POST https://us-central1-studio-4796520355-68573.cloudfunctions.net/faceEncoding
```

Request:

```json
{
  "photoDataUri": "data:image/jpeg;base64,..."
}
```

Response:

```json
{
  "faceEncoding": "encoding_1234567890_0.123456"
}
```

#### Face Matching Endpoint

```
POST https://us-central1-studio-4796520355-68573.cloudfunctions.net/realTimeFaceMatch
```

Request:

```json
{
  "faceImageDataUri": "data:image/jpeg;base64,...",
  "storedFaceEncodings": ["encoding_1", "encoding_2"]
}
```

Response:

```json
{
  "isMatch": true,
  "studentId": "abc123",
  "confidence": 0.99
}
```

**Note**: These endpoints are NOT yet deployed. The current web app uses server-side AI flows. You'll need to deploy Cloud Functions or call the AI flows directly if exposed.

---

## 🎨 UI/UX Recommendations for iOS

### Key Screens to Implement

1. **Login Screen**

   - Email/password authentication
   - Display school name after login
   - Show staff role and permissions

2. **Face Check-In Screen**

   - Live camera preview
   - Face detection overlay
   - Capture button
   - Real-time matching feedback
   - Success/failure animations

3. **Student List Screen**

   - Browse all students in school
   - Search/filter by name or class
   - View student details

4. **Student Detail Screen**

   - Student information
   - Face samples gallery
   - Attendance history
   - Edit capabilities (based on role)

5. **Settings Screen**
   - Camera settings
   - Confidence threshold adjustment
   - Offline mode settings

### Camera Permissions

Add to `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required to capture student faces for attendance check-in.</string>
```

---

## 🧪 Testing Recommendations

### Test Accounts Needed

Create test staff accounts with different roles:

1. Admin account (full access)
2. Reception account (create/edit only)
3. Teacher account (read-only)

### Test Data

- Create test school
- Add sample students with face images
- Test face matching with various lighting conditions
- Test offline scenarios

### Security Testing

- Verify school isolation (staff can't access other schools)
- Verify role permissions (teachers can't edit)
- Verify inactive staff can't access data

---

## 📚 Additional Resources

### Firebase iOS Documentation

- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
- [Firestore iOS Guide](https://firebase.google.com/docs/firestore/quickstart)
- [Firebase Authentication iOS](https://firebase.google.com/docs/auth/ios/start)

### Face Recognition Libraries for iOS

- **Vision Framework** (Apple native, recommended)
- **MLKit Face Detection** (Google)
- **OpenCV iOS** (Advanced computer vision)

### Project Documentation

- See `docs/backend.json` for detailed data schema
- See `docs/blueprint.md` for system architecture
- See `firestore.rules` for complete security rules

---

## ⚠️ Important Notes

1. **Face Recognition is Placeholder**: The current implementation uses timestamp-based encodings, not real face recognition. For production:

   - Implement actual face embedding model (e.g., FaceNet, ArcFace)
   - Use Vision Framework on iOS for face detection
   - Send face features to backend for matching

2. **iOS App Registration**: You must register an iOS app in Firebase Console to get:

   - iOS-specific App ID
   - Complete GoogleService-Info.plist
   - iOS bundle ID configuration

3. **Cloud Functions**: Consider deploying Cloud Functions for:

   - Face encoding generation
   - Face matching logic
   - Attendance notifications to parents

4. **Storage**: Consider Firebase Storage for:

   - High-quality student photos
   - Face sample backups
   - Profile avatars

5. **Offline Support**: Implement Firestore offline persistence:

   ```swift
   let settings = Firestore.firestore().settings
   settings.isPersistenceEnabled = true
   Firestore.firestore().settings = settings
   ```

6. **Privacy & Compliance**:
   - Ensure GDPR/privacy law compliance for biometric data
   - Implement data retention policies
   - Provide parent consent mechanisms
   - Secure face data with encryption

---

## 📞 Support

For questions about this configuration or the Firebase setup, refer to:

- Project repository: ianyian/studio
- Firebase Console: https://console.firebase.google.com/project/studio-4796520355-68573
- Current web implementation in `src/` directory

---

**Last Updated**: November 28, 2025  
**Project**: Smart Attendance System - CoMa  
**Platform**: iOS Swift Client Configuration
