# Testing Checklist

## Pre-Testing Setup

### ✅ Firebase Configuration

- [ ] `GoogleService-Info.plist` is in project
- [ ] Firebase project ID: `studio-4796520355-68573`
- [ ] Test account created: `staff@example.com` / `password123`
- [ ] Firestore database initialized
- [ ] Firebase SDK installed via Swift Package Manager

### ✅ Xcode Configuration

- [ ] Project builds without errors
- [ ] Camera permissions in Info.plist (`NSCameraUsageDescription`)
- [ ] WhatsApp URL scheme configured (`LSApplicationQueriesSchemes`)
- [ ] Bundle ID: `nano.FaceRecognitionClient`
- [ ] Deployment target: iOS 15.0+

### ✅ Device Setup

- [ ] Physical iOS device connected (recommended)
- [ ] Camera permissions enabled in iOS Settings
- [ ] Internet connection active
- [ ] Xcode developer account configured

---

## Test Scenarios

### 1. Login Flow

**Steps:**

1. Launch app
2. Select school: "Main Tuition Center" from dropdown
3. Enter email: `staff@example.com`
4. Enter password: `password123`
5. Tap "Login" button

**Expected Results:**

- ✅ Loading indicator appears
- ✅ Credentials saved to Keychain
- ✅ Navigation to camera screen
- ✅ Console: "✅ Login successful"

**Error Cases:**

- ❌ Invalid credentials → "Authentication failed" alert
- ❌ No internet → "Network error" message
- ❌ Empty fields → Validation error

---

### 2. Camera Initialization

**Steps:**

1. Successfully login (see Test 1)
2. Wait for camera screen to load

**Expected Results:**

- ✅ Camera permission prompt appears (first time)
- ✅ Loading indicator: "Initializing camera..."
- ✅ Camera feed becomes visible within 2-3 seconds
- ✅ Console: "✅ Camera setup complete"
- ✅ Console: "✅ Camera ready with X students"
- ✅ Status bar shows "Scanning for faces..."

**Error Cases:**

- ❌ Permission denied → "Camera access denied" error
- ❌ Camera unavailable → Error message displayed

---

### 3. Photo Capture & Storage

**Steps:**

1. Camera is running (see Test 2)
2. Position face in view
3. Wait 1-2 seconds

**Expected Results:**

- ✅ Status changes: Scanning → Processing
- ✅ Green face detection box appears
- ✅ Console: "📸 Picture saved to Firestore: {document-id}"
- ✅ Status shows "Face Detected" (may show "Failed" randomly due to placeholder)
- ✅ Status returns to "Scanning" after 2 seconds

**Verify in Firebase Console:**

1. Go to Firebase Console
2. Navigate to Firestore Database
3. Check `login-pictures` collection
4. Verify new document with:
   - `staffId`: "staff-xxx"
   - `timestamp`: Recent timestamp
   - `imageData`: "data:image/jpeg;base64,..." (long string)

---

### 4. Continuous Operation

**Steps:**

1. Camera is running (see Test 2)
2. Let app run for 30 seconds
3. Move face in/out of view

**Expected Results:**

- ✅ Frame processing every ~1 second (throttled)
- ✅ Multiple photos captured and saved
- ✅ UI remains responsive
- ✅ No crashes or freezes
- ✅ Status updates smoothly
- ✅ Face box animates properly

---

### 5. Logout & Cleanup

**Steps:**

1. Camera is running (see Test 2)
2. Tap "Logout" button
3. Confirm logout in alert

**Expected Results:**

- ✅ Camera stops (no more processing)
- ✅ Credentials cleared from Keychain
- ✅ Return to login screen
- ✅ Console: Camera session stopped

---

### 6. Demo Controls (Testing Only)

**Steps:**

1. Camera is running (see Test 2)
2. Tap demo buttons in bottom-right corner

**Test Each Button:**

- 🔍 "Scanning" → Status: Scanning, no face box
- 👤 "Face Detected" → Status: Face Detected, green box
- ⏳ "Processing" → Status: Processing, green box
- ✅ "Success" → Status: Success with student name, details populate
- ❌ "Failed" → Status: Failed with error message

**Expected Results:**

- ✅ Status updates immediately
- ✅ UI reflects correct state
- ✅ Face box shows/hides appropriately
- ✅ Details section updates (for success case)

---

## Performance Checks

### Camera Performance

- [ ] Video preview is smooth (30 FPS)
- [ ] No lag or stuttering
- [ ] Frame processing doesn't block UI
- [ ] Memory usage stays stable (<100 MB)

### Firebase Performance

- [ ] Image upload completes within 2 seconds
- [ ] No failed writes to Firestore
- [ ] Base64 encoding efficient
- [ ] Multiple rapid captures handled gracefully

### UI Responsiveness

- [ ] All buttons respond immediately
- [ ] Animations are smooth
- [ ] Status transitions are clear
- [ ] No frozen interface

---

## Known Issues & Limitations

### Expected Behaviors (Not Bugs)

1. **Random Recognition Results**

   - Face recognition is placeholder
   - Success/failure is randomized (80% success rate)
   - This is intentional for testing

2. **No Actual Face Matching**

   - Current implementation doesn't compare faces
   - Just captures and saves images
   - Real recognition coming in Phase 3

3. **High Firebase Storage**
   - Each capture saves full JPEG image
   - Base64 encoding increases size by ~33%
   - Consider cleanup scripts for testing data

### To Be Implemented

- [ ] Real face detection with Vision framework
- [ ] Face recognition with CoreML model
- [ ] Student matching algorithm
- [ ] Attendance record creation
- [ ] Parent WhatsApp notifications
- [ ] Offline support

---

## Troubleshooting Guide

### Camera Won't Start

**Symptoms:** Black screen, stuck on "Initializing..."
**Solutions:**

1. Check iOS Settings → Privacy → Camera
2. Enable camera for FaceRecognitionClient
3. Restart app
4. Clean build: Cmd + Shift + K, then rebuild

### Firebase Errors

**Symptoms:** "Failed to save" errors in console
**Solutions:**

1. Verify `GoogleService-Info.plist` exists
2. Check Firebase project is active
3. Verify Firestore rules allow writes
4. Ensure internet connection

### Build Errors

**Symptoms:** Xcode shows compile errors
**Solutions:**

1. Install Firebase SDK via Package Manager
2. Verify all import statements present
3. Clean derived data: ~/Library/Developer/Xcode/DerivedData
4. Restart Xcode

### Permission Issues

**Symptoms:** "Camera access denied" alert
**Solutions:**

1. Go to iOS Settings
2. Privacy & Security → Camera
3. Toggle on for FaceRecognitionClient
4. Return to app (it may need restart)

---

## Test Results Template

**Date:** ******\_\_\_\_******
**Tester:** ******\_\_\_\_******
**Device:** ******\_\_\_\_******
**iOS Version:** ******\_\_\_\_******

| Test          | Pass | Fail | Notes |
| ------------- | ---- | ---- | ----- |
| Login Flow    | ☐    | ☐    |       |
| Camera Init   | ☐    | ☐    |       |
| Photo Capture | ☐    | ☐    |       |
| Continuous Op | ☐    | ☐    |       |
| Logout        | ☐    | ☐    |       |
| Demo Controls | ☐    | ☐    |       |
| Performance   | ☐    | ☐    |       |

**Overall Status:** ☐ Pass ☐ Fail

**Additional Notes:**

---

---

---

---

## Next Testing Phase

After this phase is validated:

1. Implement real face detection
2. Add CoreML face recognition model
3. Test actual face matching
4. Verify student identification
5. Test attendance recording
6. Test WhatsApp notifications

---

**Status:** Ready for Testing
**Last Updated:** [Current Date]
**Version:** 1.0 - Camera Implementation
