# Login Pictures Debug Guide

## Overview
This document helps you test and debug the login-pictures feature that saves face detection photos to Firestore for parent verification.

## How It Works

### Trigger Points
The `saveLoginPictureIfSuccess()` function is called when:
1. **WhatsApp Parent** button is clicked → calls `confirmAndResume()`
2. **Next Capture** button is clicked → calls `confirmAndResume()`
3. **Screen-Lock** button is clicked → calls `manualLockFromPopup()`
4. **Auto-lock timeout** triggers → calls `performPopupAutoLock()`

### Requirements for Picture to be Saved
All of the following conditions must be met:

1. ✅ **Status is `.success`** - The face recognition was successful
2. ✅ **`capturedImage` exists** - The captured photo is available
3. ✅ **`matchedStudentId` exists** - The student ID was matched
4. ✅ **`school?.id` exists** - School ID is available

### Firestore Structure
Pictures are saved to:
```
/schools/{schoolId}/login-pictures/{pictureId}
```

**Document Fields:**
- `id`: Unique picture ID (UUID)
- `studentId`: Matched student ID
- `schoolId`: School ID
- `imageData`: Base64-encoded JPEG image (data URI format)
- `capturedAt`: ISO8601 timestamp
- `timestamp`: Firestore server timestamp
- `attendanceId`: (optional) Attendance record ID

## Debug Logs to Watch For

### When Testing, Look for These Console Messages:

#### 1. Button Click Logs
- `📱 confirmAndResume() called - User clicked Next Capture or WhatsApp`
- `🔒 manualLockFromPopup() called - User clicked Screen-Lock`
- `⏱️ performPopupAutoLock() called - Auto-lock timeout triggered`

#### 2. Save Function Entry
- `🔍 saveLoginPictureIfSuccess() called`

#### 3. Status Check
- `✅ Status is .success` - Good, will proceed
- `⚠️ Cannot save login picture: status is not .success (current: ...)` - Won't save

#### 4. Data Validation
If successful:
- `✅ All required data present - proceeding to save`
- `   - studentId: {studentId}`
- `   - schoolId: {schoolId}`

If missing data:
- `⚠️ Cannot save login picture: missing data`
- `   - capturedImage: ✓ or ✗`
- `   - matchedStudentId: {id} or nil`
- `   - school?.id: {id} or nil`

#### 5. Firestore Save Result
- `📊 Image data size: {size} KB` - Image size check
- `✅ Login picture saved: {pictureId}` - Success!
- `✅ Login picture saved to /schools/{schoolId}/login-pictures/{pictureId} for student {studentId}`
- `📸 Picture saved for parent verification` - Logged to status log
- `⚠️ Failed to save login picture: {error}` - Error occurred

## Testing Steps

### Test Case 1: Successful Face Detection → Next Capture
1. Launch app and select school
2. Detect a student's face successfully (green checkmark)
3. Click **Next Capture** button
4. **Expected Logs:**
   ```
   📱 confirmAndResume() called - User clicked Next Capture or WhatsApp
   🔍 saveLoginPictureIfSuccess() called
   ✅ Status is .success
   ✅ All required data present - proceeding to save
      - studentId: {id}
      - schoolId: {id}
   📊 Image data size: XXX KB
   ✅ Login picture saved: {pictureId}
   📸 Picture saved for parent verification
   ```

### Test Case 2: Successful Face Detection → WhatsApp Parent
1. Detect a student with parent phone number
2. Click **WhatsApp Parent** button
3. **Expected:** Same logs as Test Case 1

### Test Case 3: Successful Face Detection → Screen-Lock
1. Detect a student successfully
2. Click **Screen-Lock** button
3. **Expected Logs:**
   ```
   🔒 manualLockFromPopup() called - User clicked Screen-Lock
   🔍 saveLoginPictureIfSuccess() called
   ...
   ```

### Test Case 4: Successful Face Detection → Auto-Lock
1. Detect a student successfully
2. Wait for auto-lock timeout (don't click anything)
3. **Expected Logs:**
   ```
   ⏱️ performPopupAutoLock() called - Auto-lock timeout triggered
   🔍 saveLoginPictureIfSuccess() called
   ...
   ```

### Test Case 5: Failed Face Detection
1. Show an unknown face (recognition fails)
2. Click any button
3. **Expected Logs:**
   ```
   📱 confirmAndResume() called - User clicked Next Capture or WhatsApp
   🔍 saveLoginPictureIfSuccess() called
   ⚠️ Cannot save login picture: status is not .success (current: ...)
   ```
   - Picture should **NOT** be saved (correct behavior)

## Firestore Verification

### Check if Pictures are Saved:
1. Open Firebase Console
2. Go to Firestore Database
3. Navigate to: `schools → {your-school-id} → login-pictures`
4. You should see documents with:
   - Auto-generated document IDs (UUIDs)
   - Fields: `id`, `studentId`, `schoolId`, `imageData`, `capturedAt`, `timestamp`

### Query Example (Firebase Console):
```javascript
// Get all login pictures for a school
db.collection('schools')
  .doc('{schoolId}')
  .collection('login-pictures')
  .orderBy('timestamp', 'desc')
  .limit(10)
```

### Check Image Data:
The `imageData` field should contain a data URI like:
```
data:image/jpeg;base64,/9j/4AAQSkZJRg...
```

You can copy this string and paste it in a browser's address bar to view the image.

## Common Issues & Solutions

### Issue 1: "Cannot save login picture: status is not .success"
**Cause:** Face recognition failed or status changed before save
**Solution:** Check that face recognition is working correctly

### Issue 2: "Cannot save login picture: missing data"
**Possible Causes:**
- `capturedImage = nil`: Camera capture failed
- `matchedStudentId = nil`: Student ID wasn't set during match
- `school?.id = nil`: No school selected

**Solution:** Check the specific missing field in the logs

### Issue 3: "Image too large after compression"
**Cause:** Image exceeds Firestore 1MB limit
**Solution:** Image is automatically resized to 600KB target. If this error occurs, the compression settings may need adjustment in `FirebaseService.saveLoginPicture()`

### Issue 4: Pictures not appearing in Firestore
**Possible Causes:**
1. Firestore security rules blocking write
2. Network connectivity issue
3. App Check blocking the request

**Solution:**
- Check Firestore rules allow writes to `login-pictures` subcollection
- Check network connectivity
- Verify App Check is configured correctly

## Firestore Rules
Ensure your `firestore.rules` allows writes to login-pictures:

```javascript
match /schools/{schoolId}/login-pictures/{pictureId} {
  allow create: if request.auth != null;
  allow read: if request.auth != null;
}
```

## Image Size Optimization
Current settings in `FirebaseService.saveLoginPicture()`:
- **Max size target:** 600KB before base64 encoding
- **JPEG quality:** 0.7 (70%)
- **Firestore limit:** 1MB per field

Images are automatically resized to fit within these limits.

## Next Steps After Testing

1. **Run through all test cases** and collect console logs
2. **Verify pictures in Firestore** Console
3. **Check image quality** by viewing saved data URIs
4. **Monitor Firestore usage** (storage and reads/writes)
5. **Test with different students** and scenarios
6. **Verify parent verification workflow** can read these pictures

## Support
If pictures are not being saved:
1. Share the console logs (especially the `⚠️` warnings)
2. Check Firestore security rules
3. Verify network connectivity
4. Confirm App Check is working
