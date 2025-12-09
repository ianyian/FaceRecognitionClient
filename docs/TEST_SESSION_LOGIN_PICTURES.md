# Test Session: Login Pictures Feature

## Test Account
- **Username:** demo01
- **Password:** helloworld
- **School:** demo01
- **Students:** 5 enrolled students

## Pre-Test Setup ✅
1. [ ] Open Xcode and run the app
2. [ ] Open Xcode Console (View → Debug Area → Show Debug Area)
3. [ ] Open Firebase Console in browser
4. [ ] Navigate to Firestore Database
5. [ ] Locate school "demo01" in the schools collection

## Test Procedure

### Step 1: Login and Sync
1. [ ] Login with demo01/helloworld
2. [ ] Select school "demo01"
3. [ ] Click **sync button** (⭐) to load latest face data
4. [ ] Wait for success message

### Step 2: Test Case A - WhatsApp Parent Button
**Scenario:** Detect student → Click WhatsApp Parent

1. [ ] Position student face in camera
2. [ ] Wait for green checkmark (success)
3. [ ] Note the student name in popup
4. [ ] Click **WhatsApp Parent** button (if available)
5. [ ] Check Xcode Console for:
   ```
   📱 confirmAndResume() called - User clicked Next Capture or WhatsApp
   🔍 saveLoginPictureIfSuccess() called
   ✅ Status is .success
   ✅ All required data present - proceeding to save
   ✅ Login picture saved: {pictureId}
   ```
6. [ ] Check Firestore: `schools/demo01/login-pictures/`
7. [ ] Verify new document with studentId matches detected student

**Result:** ☐ PASS ☐ FAIL  
**Notes:**

---

### Step 3: Test Case B - Next Capture Button
**Scenario:** Detect student → Click Next Capture

1. [ ] Position student face in camera
2. [ ] Wait for green checkmark (success)
3. [ ] Note the student name in popup
4. [ ] Click **Next Capture** button
5. [ ] Check Xcode Console for same logs as Test Case A
6. [ ] Check Firestore for new document
7. [ ] Verify studentId and timestamp

**Result:** ☐ PASS ☐ FAIL  
**Notes:**

---

### Step 4: Test Case C - Screen-Lock Button
**Scenario:** Detect student → Click Screen-Lock

1. [ ] Position student face in camera
2. [ ] Wait for green checkmark (success)
3. [ ] Note the student name in popup
4. [ ] Click **Screen-Lock** button
5. [ ] Check Xcode Console for:
   ```
   🔒 manualLockFromPopup() called - User clicked Screen-Lock
   🔍 saveLoginPictureIfSuccess() called
   ✅ Status is .success
   ✅ All required data present - proceeding to save
   ✅ Login picture saved: {pictureId}
   ```
6. [ ] Check Firestore for new document

**Result:** ☐ PASS ☐ FAIL  
**Notes:**

---

### Step 5: Test Case D - Auto-Lock Timeout
**Scenario:** Detect student → Wait for auto-lock (don't click anything)

1. [ ] Position student face in camera
2. [ ] Wait for green checkmark (success)
3. [ ] Note the student name in popup
4. [ ] **DON'T CLICK ANYTHING** - wait for countdown
5. [ ] Observe countdown timer in popup
6. [ ] Wait for auto-lock to trigger
7. [ ] Check Xcode Console for:
   ```
   ⏱️ performPopupAutoLock() called - Auto-lock timeout triggered
   🔍 saveLoginPictureIfSuccess() called
   ✅ Status is .success
   ✅ All required data present - proceeding to save
   ✅ Login picture saved: {pictureId}
   ```
8. [ ] Check Firestore for new document

**Result:** ☐ PASS ☐ FAIL  
**Notes:**

---

### Step 6: Test Case E - Failed Detection (Negative Test)
**Scenario:** Show unknown face → Should NOT save picture

1. [ ] Show an unregistered face to camera
2. [ ] Wait for red X (failed recognition)
3. [ ] Click **Next Capture** button
4. [ ] Check Xcode Console for:
   ```
   📱 confirmAndResume() called - User clicked Next Capture or WhatsApp
   🔍 saveLoginPictureIfSuccess() called
   ⚠️ Cannot save login picture: status is not .success
   ```
5. [ ] Check Firestore - NO new document should appear

**Result:** ☐ PASS ☐ FAIL  
**Expected:** Picture should NOT be saved (this is correct behavior)  
**Notes:**

---

## Firestore Verification

### Check Saved Pictures
1. [ ] Open Firebase Console
2. [ ] Navigate to: `Firestore Database → schools → demo01 → login-pictures`
3. [ ] You should see multiple documents (one for each successful test)

### Verify Document Structure
Each document should have:
- [ ] `id` (UUID string)
- [ ] `studentId` (matches detected student)
- [ ] `schoolId` ("demo01")
- [ ] `imageData` (data:image/jpeg;base64,...)
- [ ] `capturedAt` (ISO8601 timestamp)
- [ ] `timestamp` (Firestore server timestamp)

### Verify Image Data
1. [ ] Copy the `imageData` value from one document
2. [ ] Paste it into browser address bar
3. [ ] You should see the captured face image

**Image displays correctly:** ☐ YES ☐ NO

---

## Test Results Summary

| Test Case | Button/Action | Expected | Result | Notes |
|-----------|--------------|----------|--------|-------|
| A | WhatsApp Parent | Picture saved | ☐ | |
| B | Next Capture | Picture saved | ☐ | |
| C | Screen-Lock | Picture saved | ☐ | |
| D | Auto-Lock | Picture saved | ☐ | |
| E | Failed Detection | NOT saved | ☐ | |

**Total Passed:** ___/5  
**Total Failed:** ___/5

---

## Common Issues Checklist

If pictures are not being saved, check:

### Console Logs
- [ ] Is `saveLoginPictureIfSuccess()` being called?
- [ ] Is status `.success`?
- [ ] Are all required data present? (image, studentId, schoolId)
- [ ] Any error messages in console?

### Firestore
- [ ] Can you access `/schools/demo01/` collection?
- [ ] Do you have write permissions?
- [ ] Check Firestore Rules tab for security rules

### App State
- [ ] Is camera permission granted?
- [ ] Is face data loaded successfully?
- [ ] Is school "demo01" selected?
- [ ] Are students appearing in dropdown?

---

## Screenshot Locations

If you want to attach screenshots to bug reports:
1. Console logs: Screenshot Xcode debug area
2. Firestore: Screenshot Firebase Console
3. App UI: Use iOS simulator screenshot (Cmd+S)

---

## Next Steps After Testing

✅ **If All Tests Pass:**
- Feature is working correctly
- Ready for production use
- Consider adding parent verification UI

❌ **If Any Tests Fail:**
- Share console logs (copy/paste all `🔍` and `⚠️` messages)
- Share Firestore screenshot
- Note which specific test case failed
- Check error messages

---

## Additional Testing (Optional)

### Test with All 5 Students
- [ ] Student 1: Detected and picture saved
- [ ] Student 2: Detected and picture saved
- [ ] Student 3: Detected and picture saved
- [ ] Student 4: Detected and picture saved
- [ ] Student 5: Detected and picture saved

### Test Multiple Pictures per Student
- [ ] Detect same student multiple times
- [ ] Each detection should create a new document
- [ ] Verify multiple pictures per studentId in Firestore

### Test Image Quality
- [ ] Check image file size in console: "📊 Image data size: XXX KB"
- [ ] Should be under 1000 KB (Firestore limit)
- [ ] Image quality should be acceptable for parent verification

---

## Test Completed

**Date:** ___________  
**Tester:** ___________  
**Duration:** ___________  
**Overall Result:** ☐ PASS ☐ FAIL  

**Comments:**
