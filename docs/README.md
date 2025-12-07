# FaceCheck iOS Client

Face recognition-based student attendance system for tuition centers.

## 📱 Overview

This iOS application allows tuition center staff to check in students using face recognition technology. When a student's face is recognized, the system automatically sends a WhatsApp notification to their parent.

## ✨ Features

- **Staff Authentication** - Email/password login with Firebase
- **School Isolation** - Staff can only access their assigned school's data
- **Face Recognition** - Real-time face detection and matching
- **Auto Check-in** - Automatic attendance logging
- **WhatsApp Integration** - Instant parent notifications
- **Offline Support** - Local face encoding comparison
- **Role-Based Access** - Admin, Reception, and Teacher roles

## 🛠 Tech Stack

- **SwiftUI** - Modern declarative UI framework
- **Firebase Auth** - User authentication
- **Firebase Firestore** - Cloud database
- **Vision Framework** - Face detection
- **AVFoundation** - Camera access
- **CoreML** - Machine learning (future)

## 📋 Prerequisites

- Xcode 15.0+
- iOS 15.0+
- Swift 5.9+
- Firebase Project (already configured)
- Valid Firebase credentials in `GoogleService-Info.plist`

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd FaceRecognitionClient
```

### 2. Add Firebase SDK

The project uses Swift Package Manager for Firebase dependencies:

1. Open `FaceRecognitionClient.xcodeproj` in Xcode
2. File → Add Package Dependencies
3. Enter: `https://github.com/firebase/firebase-ios-sdk.git`
4. Select version 10.0.0 or later
5. Add these products:
   - FirebaseAuth
   - FirebaseFirestore
   - FirebaseStorage

### 3. Configure Firebase

The `GoogleService-Info.plist` is already included with the project configuration for:

- **Project ID**: `studio-4796520355-68573`
- **API Key**: Pre-configured
- **Auth Domain**: `studio-4796520355-68573.firebaseapp.com`

> **Note**: You may need to register this iOS app in the Firebase Console to get an iOS-specific `GOOGLE_APP_ID`.

### 4. Build and Run

1. Open the project in Xcode
2. Select your target device or simulator
3. Press `Cmd + R` to build and run

## 📱 App Structure

```
FaceRecognitionClient/
├── Models/
│   ├── School.swift          # School data model
│   ├── Staff.swift           # Staff member model
│   ├── Student.swift         # Student data model
│   └── FaceMatch.swift       # Face recognition result
├── Services/
│   ├── FirebaseService.swift       # Firebase operations
│   ├── FaceRecognitionService.swift # Face matching logic
│   └── KeychainService.swift       # Secure credential storage
├── ViewModels/
│   ├── LoginViewModel.swift   # Login screen logic
│   └── CameraViewModel.swift  # Camera screen logic
├── Views/
│   ├── LoginView.swift        # Login screen UI
│   └── CameraView.swift       # Camera & face recognition UI
└── GoogleService-Info.plist   # Firebase configuration
```

## 🔐 Authentication

### Test Accounts

You'll need to create staff accounts in Firebase. Example:

```javascript
// In Firebase Console or using Admin SDK
{
  email: "staff@example.com",
  password: "password123",
  firstName: "Ian",
  lastName: "Wong",
  role: "reception",
  schoolId: "main-tuition-center",
  isActive: true
}
```

### Roles

- **Admin** - Full access (read/write/delete)
- **Reception** - Can check in students and manage records
- **Teacher** - Read-only access

## 📸 Face Recognition

### Current Implementation

The face recognition service currently uses **placeholder logic** for demonstration:

- Face detection: ✅ Uses Apple's Vision framework
- Face encoding: ⚠️ Placeholder (timestamp-based)
- Face matching: ⚠️ Random match simulation

### Production Implementation

For production use, you need to:

1. **Implement Face Encoding**

   - Use a pre-trained CoreML model (FaceNet, ArcFace, etc.)
   - Extract 128-512 dimensional face embeddings
   - Ensure consistency with web app encodings

2. **Implement Face Matching**

   - Compare captured encoding with stored encodings
   - Use cosine similarity or Euclidean distance
   - Set appropriate confidence threshold (0.7 = 70%)

3. **Optimize Performance**
   - Process frames on background thread
   - Throttle frame processing (every 3rd frame)
   - Cache student encodings locally

## 📊 Firebase Collections

### Staff Collection

```
/staff/{staffId}
  - email: string
  - firstName: string
  - lastName: string
  - role: "admin" | "reception" | "teacher"
  - schoolId: string
  - isActive: boolean
```

### Students Collection

```
/schools/{schoolId}/students/{studentId}
  - firstName: string
  - lastName: string
  - class: string
  - parentId: string
  - parentName: string
  - parentContact: string (E.164 format)
  - faceEncoding: string (base64)
  - status: "Registered" | "Pending" | "Deleted"
```

### Attendance Logs

```
/schools/{schoolId}/students/{studentId}/attendanceLogs/{logId}
  - id: string
  - studentId: string
  - checkInTime: string (ISO 8601)
```

## 📱 WhatsApp Integration

The app uses WhatsApp URL schemes to send notifications:

```swift
whatsapp://send?phone={number}&text={message}
```

### Requirements

- WhatsApp must be installed on the device
- Phone numbers must be in E.164 format (+60123456789)
- URL scheme `whatsapp` must be declared in Info.plist

### Fallback

If WhatsApp is not installed, the app uses web WhatsApp:

```swift
https://wa.me/{number}?text={message}
```

## 🧪 Testing

### Demo Controls

The Camera View includes demo controls for testing UI states:

- 🔍 Scanning
- 👤 Face Detected
- ⏳ Processing
- ✅ Success
- ❌ Failed

> **Remove these controls in production build**

### Unit Tests

```bash
# Run tests
xcodebuild test -scheme FaceRecognitionClient -destination 'platform=iOS Simulator,name=iPhone 15'
```

## 🔧 Configuration

### Info.plist Permissions

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required to capture student faces for attendance check-in.</string>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>whatsapp</string>
</array>
```

### Firestore Settings

Enable offline persistence for better performance:

```swift
let settings = Firestore.firestore().settings
settings.isPersistenceEnabled = true
Firestore.firestore().settings = settings
```

## 📝 TODO

### High Priority

- [ ] Implement real face encoding using CoreML model
- [ ] Add actual camera capture functionality
- [ ] Implement real-time face comparison
- [ ] Add proper error handling for camera
- [ ] Implement attendance history view

### Medium Priority

- [ ] Add pull-to-refresh for student data
- [ ] Implement offline mode with sync
- [ ] Add student search functionality
- [ ] Show attendance statistics
- [ ] Add dark mode support

### Low Priority

- [ ] Add biometric authentication (Face ID/Touch ID)
- [ ] Implement multi-language support
- [ ] Add accessibility features
- [ ] Create iPad-optimized layout
- [ ] Add analytics tracking

## 🐛 Known Issues

1. **Face Recognition Placeholder** - Uses mock matching logic
2. **Camera Feed** - Currently shows placeholder, needs AVCaptureSession implementation
3. **Face Encoding** - Needs real ML model for production use
4. **WhatsApp Opening** - Requires app switch (user friction)

## 🔒 Security Considerations

- ✅ Firebase Security Rules enforce school isolation
- ✅ Credentials stored in iOS Keychain
- ✅ Staff authentication required
- ✅ Role-based access control
- ⚠️ Face encodings need encryption at rest
- ⚠️ Implement certificate pinning for API calls
- ⚠️ Add biometric authentication option

## 📄 License

[Your License Here]

## 👥 Contributors

- Your Name - Initial work

## 📞 Support

For issues or questions:

- Check the documentation in `/docs`
- Review Firebase configuration in `key.md`
- Contact project administrator

---

**Version**: 1.0.0  
**Last Updated**: November 28, 2025  
**Status**: MVP - Ready for Testing
