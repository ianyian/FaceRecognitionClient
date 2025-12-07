# Camera Implementation Guide

## Overview

The iOS app now has full camera integration that captures photos and saves them to Firestore for testing purposes. This document explains the implementation and how to test it.

## What Was Implemented

### 1. **CameraService** (`Services/CameraService.swift`)

A complete AVFoundation-based camera service that:

- ✅ Checks camera authorization
- ✅ Sets up front camera session
- ✅ Captures still photos
- ✅ Provides continuous video frames for face detection
- ✅ Generates preview layer for SwiftUI

**Key Features:**

```swift
- checkAuthorization() -> Requests camera permissions
- setupSession() -> Configures AVCaptureSession with front camera
- startSession() -> Begins capturing video
- stopSession() -> Stops camera
- capturePhoto() -> Takes a still photo
- getPreviewLayer() -> Returns CALayer for preview
- onFrameCapture callback -> Processes each video frame
```

### 2. **CameraPreviewView** (`Views/CameraPreviewView.swift`)

UIKit wrapper for showing camera feed in SwiftUI:

- ✅ Displays live camera preview
- ✅ Automatically handles layer sizing
- ✅ Integrates with SwiftUI lifecycle

### 3. **Firebase Storage** (`Services/FirebaseService.swift`)

New method for saving captured images:

```swift
func saveLoginPicture(image: UIImage, staffId: String) async throws -> String
```

- Converts UIImage to JPEG (80% quality)
- Encodes as base64 data URI
- Saves to Firestore collection: `login-pictures`
- Returns document ID

### 4. **Updated CameraViewModel**

Enhanced with real camera integration:

- ✅ Initializes camera on view load
- ✅ Processes video frames at ~1 FPS (throttled)
- ✅ Saves captured images to Firestore
- ✅ Shows "Face Detected" status even when recognition fails
- ✅ Properly cleans up camera on view dismiss

**Key Properties:**

```swift
let cameraService = CameraService()
@Published var isCameraReady: Bool = false
private var isProcessing: Bool = false
private var frameCounter: Int = 0
```

### 5. **Updated CameraView**

Now shows live camera feed:

- ✅ Displays real camera preview when ready
- ✅ Shows loading indicator during initialization
- ✅ Stops camera when view disappears
- ✅ Maintains all original UI elements (face box, status bar)

## How It Works

### Flow Diagram

```
1. User logs in → CameraView loads
2. CameraViewModel.loadData() called
3. Camera authorization requested
4. Camera session starts
5. Video frames captured at 30 FPS
6. Every 30th frame processed (1 per second)
7. Face detection attempted
8. Photo captured and saved to Firestore
9. Status updated based on result
```

### Firestore Structure

```
login-pictures/
  {documentId}/
    - staffId: "staff-xxx"
    - timestamp: Timestamp
    - imageData: "data:image/jpeg;base64,/9j/4AAQ..."
```

## Testing Instructions

### Prerequisites

1. ✅ Firebase project configured (see `SETUP_FIREBASE.md`)
2. ✅ Test account created: `staff@example.com` / `password123`
3. ✅ Camera permissions enabled in iOS Settings
4. ✅ Physical iOS device (simulator camera is limited)

### Test Steps

1. **Build and Run**

   ```bash
   # Open project in Xcode
   open FaceRecognitionClient.xcodeproj

   # Select your device and run
   # Cmd + R
   ```

2. **Login**

   - School: Select "Main Tuition Center"
   - Email: staff@example.com
   - Password: password123
   - Click "Login"

3. **Camera Screen**

   - Camera should activate automatically
   - You'll see live video feed
   - Face detection box appears when processing

4. **Verify Capture**

   - Wait a few seconds
   - Console should show: "📸 Picture saved to Firestore: {id}"
   - Check Firebase Console → Firestore → `login-pictures` collection
   - Verify image data exists

5. **Check Status**
   - Status should cycle: Scanning → Processing → Face Detected → Scanning
   - Face detection box animates in when processing

## Console Output

Look for these log messages:

```
✅ Camera ready with X students
✅ Camera setup complete
📸 Picture saved to Firestore: abc123xyz
```

## Troubleshooting

### Camera Not Starting

**Problem:** Black screen or "Initializing camera..." stuck
**Solutions:**

1. Check Info.plist for `NSCameraUsageDescription`
2. Reset camera permissions: Settings → Privacy → Camera
3. Rebuild project (Clean Build Folder: Cmd + Shift + K)

### Authorization Denied

**Problem:** "Camera access denied" error
**Solution:**

1. Go to Settings → Privacy & Security → Camera
2. Enable for FaceRecognitionClient
3. Restart app

### Firebase Save Failing

**Problem:** Console shows error saving to Firestore
**Solutions:**

1. Verify Firebase configuration in `GoogleService-Info.plist`
2. Check Firestore rules allow write access
3. Ensure internet connection is active

### No Face Detection

**Problem:** Status stays on "Scanning"
**Expected:** This is normal! The placeholder face recognition randomly succeeds/fails
**Note:** Real face detection will be implemented later with Vision framework

## Firebase Security Rules

For testing, use these Firestore rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to write login pictures
    match /login-pictures/{document} {
      allow read, write: if request.auth != null;
    }

    // Existing rules for other collections...
  }
}
```

## Next Steps

### Phase 1: Enhanced Camera (Current Phase)

- ✅ Implement camera capture
- ✅ Save images to Firestore
- ⏳ Test on physical device
- ⏳ Verify Firestore storage

### Phase 2: Real Face Detection (Next)

- Use Vision framework `VNDetectFaceLandmarksRequest`
- Extract face bounding box
- Improve detection accuracy
- Add face quality checks

### Phase 3: Face Recognition (Future)

- Implement CoreML face recognition model
- Replace placeholder encoding
- Calculate similarity scores
- Match against student database

### Phase 4: Production Polish (Later)

- Error handling improvements
- Offline support
- Performance optimization
- Remove demo controls

## Code References

### Key Files Modified

1. **CameraService.swift** - New camera implementation (200+ lines)
2. **CameraPreviewView.swift** - New preview component
3. **FirebaseService.swift** - Added `saveLoginPicture` method
4. **CameraViewModel.swift** - Integrated camera service
5. **CameraView.swift** - Shows real camera preview

### Dependencies

```swift
import AVFoundation      // Camera capture
import Vision            // Face detection (future)
import FirebaseFirestore // Database
import SwiftUI           // UI framework
import Combine           // Reactive programming
```

## Support

For issues or questions:

1. Check console logs for error messages
2. Verify Firebase configuration
3. Test camera permissions
4. Review this document's troubleshooting section

---

**Status:** ✅ Camera implementation complete and ready for testing
**Last Updated:** [Current Date]
**Version:** 1.0
