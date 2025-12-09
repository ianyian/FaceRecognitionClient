# Login Pictures Feature

## Overview
The login pictures feature automatically saves face detection pictures to Firestore when a successful face recognition occurs. These pictures are stored for parent verification purposes, allowing parents to request attendance verification records from the tuition center.

## Implementation Details

### Firestore Structure
Pictures are saved to the following path:
```
/schools/{schoolId}/login-pictures/{pictureId}
```

Each document contains:
- `id` (String): Unique picture ID (UUID)
- `studentId` (String): ID of the matched student
- `schoolId` (String): ID of the school
- `imageData` (String): Base64-encoded JPEG image (data URI format)
- `capturedAt` (String): ISO 8601 timestamp of capture
- `timestamp` (Timestamp): Server timestamp
- `attendanceId` (String, optional): Associated attendance record ID

### When Pictures Are Saved
Pictures are automatically saved when face recognition succeeds and the user:
1. **Clicks "WhatsApp Parent"** - Opens WhatsApp and saves picture
2. **Clicks "Next Capture"** - Resumes camera and saves picture
3. **Clicks "Screen-Lock"** - Locks screen and saves picture
4. **Auto-lock triggers** - Popup times out and saves picture

### Code Changes

#### 1. FirebaseService.swift
- Updated `saveLoginPicture()` function to accept `studentId` instead of `staffId`
- Added optional `attendanceId` parameter for future attendance linking
- Function compresses and resizes images to fit Firestore limits (~1MB)
- Images are saved as base64-encoded data URIs

#### 2. CameraViewModel.swift
- Added `matchedStudentId` property to track successful matches
- Created `saveLoginPictureIfSuccess()` function to handle picture saving
- Updated `handleLocalMatch()` to store matched student ID
- Updated `runFaceComparison()` to store matched student ID
- Integrated picture saving in:
  - `confirmAndResume()` - Next Capture button
  - `manualLockFromPopup()` - Screen-Lock button
  - `performPopupAutoLock()` - Auto-lock timeout

### Image Processing
- Images are resized to fit Firestore's 1MB per field limit
- Target size: ~600KB before base64 encoding
- JPEG compression quality: 0.7
- Base64-encoded in data URI format: `data:image/jpeg;base64,{data}`

## Usage
The feature works automatically - no configuration required. When face recognition succeeds:
1. Face is detected and matched against student database
2. Success popup appears with student information
3. When user takes any action (WhatsApp, Next Capture, Lock, or auto-lock)
4. Picture is saved to Firestore in background
5. Log entry confirms: "📸 Picture saved for parent verification"

## Reference Implementation
This feature references the "main-tuition-center" Firestore structure, which already contains a `login-pictures` collection with similar document structure.

## Future Enhancements
- Link pictures to attendance records via `attendanceId`
- Add parent portal to view login pictures
- Implement automatic cleanup of old pictures (e.g., after 30 days)
- Add picture count and storage monitoring

## Testing
To test this feature:
1. Login with demo01/helloworld (select demo01 school)
2. Load Face Data from Settings
3. Capture a student's face
4. After successful match, click any button (WhatsApp, Next Capture, or Lock)
5. Check Firestore: `/schools/demo01/login-pictures/` should contain the saved picture
6. Verify document contains: studentId, imageData, capturedAt, timestamp

## Notes
- Picture saving is a background operation - errors won't interrupt user flow
- Failed saves are logged to console but not shown to user
- Pictures are only saved for successful matches (not failures)
- Captured image and matched student ID are cleared after saving
