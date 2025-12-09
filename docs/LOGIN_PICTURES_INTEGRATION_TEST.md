# Login Pictures + WhatsApp Integration Test

## Overview
This document covers testing the complete flow:
1. Face detection → Picture saved to Firestore
2. Picture URL shared via WhatsApp to parent

## ⚠️ Important Fix Applied

### Problem (Now Fixed)
The pictures were not being saved because of a **race condition**:
- Status was changed to `.scanning` immediately
- `matchedStudentId` was cleared immediately  
- But `saveLoginPictureIfSuccess()` ran asynchronously
- By the time it checked, status was already `.scanning` (not `.success`)

### Solution Applied
Restructured the flow to:
1. Call `saveLoginPictureIfSuccess()` first
2. **Wait for it to complete**
3. **Then** clear state (status, matchedStudentId)

All three trigger functions now work correctly:
- ✅ `confirmAndResume()` - Next Capture & WhatsApp buttons
- ✅ `manualLockFromPopup()` - Screen-Lock button
- ✅ `performPopupAutoLock()` - Auto-lock timeout

## Test Setup

### Prerequisites
- [x] Xcode running with app installed
- [x] Console open (View → Debug Area)
- [x] Firebase Console open in browser
- [x] Twilio account configured
- [x] Test parent WhatsApp number active

### Test Credentials
- **Username:** demo01
- **Password:** helloworld
- **School:** demo01
- **Test Parent:** +60177383777
- **Students:** 5 enrolled (demo01-student01 to demo01-student05)

## Phase 1: Test Picture Saving to Firestore

### Expected Console Logs (Success)
```
✅ Match found: demo01-student01 demo01-student01-LastName with 71.2% similarity
📱 confirmAndResume() called - User clicked Next Capture or WhatsApp
🔍 saveLoginPictureIfSuccess() called
✅ Status is .success
✅ All required data present - proceeding to save
   - studentId: demo01-student01
   - schoolId: demo01
📊 Image data size: 450 KB
✅ Login picture saved: abc-123-def-456
✅ Login picture saved to /schools/demo01/login-pictures/abc-123-def-456 for student demo01-student01
📸 Picture saved for parent verification
🔄 Resumed camera from popup
```

### Test Case 1: Next Capture Button
1. [ ] Login and select school demo01
2. [ ] Click sync to load face data
3. [ ] Detect demo01-student01 successfully (green checkmark)
4. [ ] Click **Next Capture** button
5. [ ] Check console for logs above
6. [ ] Check Firestore: `schools/demo01/login-pictures/`
7. [ ] Verify new document exists with correct studentId

**Result:** ☐ PASS ☐ FAIL

### Test Case 2: WhatsApp Button
1. [ ] Detect demo01-student01 successfully
2. [ ] Click **WhatsApp Parent** button
3. [ ] Check console for same logs
4. [ ] Check Firestore for new document
5. [ ] Note the document ID (pictureId)

**Picture ID:** ________________

**Result:** ☐ PASS ☐ FAIL

### Test Case 3: Screen-Lock Button
1. [ ] Detect student successfully
2. [ ] Click **Screen-Lock** button
3. [ ] Check console logs (should show `🔒 manualLockFromPopup()`)
4. [ ] Verify picture saved in Firestore

**Result:** ☐ PASS ☐ FAIL

### Test Case 4: Auto-Lock Timeout
1. [ ] Detect student successfully
2. [ ] **Don't click anything** - wait for countdown
3. [ ] Watch popup auto-lock after timeout
4. [ ] Check console logs (should show `⏱️ performPopupAutoLock()`)
5. [ ] Verify picture saved in Firestore

**Result:** ☐ PASS ☐ FAIL

## Phase 2: Verify Firestore Data

### Navigate to Firebase Console
1. [ ] Open Firebase Console → Firestore Database
2. [ ] Path: `schools` → `demo01` → `login-pictures`
3. [ ] You should see multiple documents (one per test)

### Verify Document Structure
Pick any document and verify fields:

```javascript
{
  id: "abc-123-def-456",
  studentId: "demo01-student01",
  schoolId: "demo01",
  imageData: "data:image/jpeg;base64,/9j/4AAQSkZJRg...",
  capturedAt: "2025-12-08T15:18:30.123Z",
  timestamp: December 8, 2025 at 3:18:30 PM UTC+8
}
```

- [ ] `id` - UUID format
- [ ] `studentId` - Matches detected student
- [ ] `schoolId` - "demo01"
- [ ] `imageData` - Starts with "data:image/jpeg;base64,"
- [ ] `capturedAt` - ISO8601 timestamp
- [ ] `timestamp` - Firestore server timestamp

### Test Image Data
1. [ ] Copy the `imageData` value
2. [ ] Paste into browser address bar
3. [ ] Image should display (captured face photo)
4. [ ] Image should be clear and recognizable

**Image Quality:** ☐ Good ☐ Poor ☐ Not visible

## Phase 3: Test WhatsApp Integration

### Method A: Using Test Script
```bash
cd /Users/xj/git/schoolAttenance-Client/FaceRecognitionClient
./test-twilio-whatsapp.sh
```

Expected output:
```json
{
  "sid": "SM...",
  "status": "queued",
  "to": "whatsapp:+60177383777",
  "from": "whatsapp:+14155238886",
  ...
}

HTTP Status: 201
```

### Method B: Manual cURL Test
```bash
curl 'https://api.twilio.com/2010-04-01/Accounts/REDACTED_TWILIO_SID/Messages.json' -X POST \
  --data-urlencode 'To=whatsapp:+60177383777' \
  --data-urlencode 'From=whatsapp:+14155238886' \
  --data-urlencode 'ContentSid=HXb5b62575e6e4ff6129ad7c8efe1f983e' \
  --data-urlencode 'ContentVariables={"1":"12/8","2":"3:15 PM"}' \
  -u REDACTED_TWILIO_SID:REDACTED_TWILIO_TOKEN
```

### Verify WhatsApp Delivery
1. [ ] Check parent's WhatsApp (+60177383777)
2. [ ] Message should arrive within 5-10 seconds
3. [ ] Template should show: "Student checked in on 12/8 at 3:15 PM"
4. [ ] Variables should be properly rendered

**WhatsApp Status:** ☐ Received ☐ Not received ☐ Error

## Phase 4: End-to-End Integration Test

### Complete Flow Test
1. [ ] Start with fresh app session
2. [ ] Login as demo01/helloworld
3. [ ] Select school demo01
4. [ ] Sync face data
5. [ ] Detect demo01-student01 (parent: +60177383777)
6. [ ] Click **WhatsApp Parent** button
7. [ ] Verify picture saved to Firestore
8. [ ] Get picture URL from Firestore document
9. [ ] Send WhatsApp message with picture URL

### Expected Results
- ✅ Picture saved to Firestore within 1 second
- ✅ Picture viewable via imageData URL
- ✅ WhatsApp message sent successfully
- ✅ Parent receives message within 10 seconds
- ✅ Picture URL in message is accessible

## Security Checklist

### Before Production
- [ ] ⚠️ **URGENT**: Rotate Twilio credentials (exposed in this document)
- [ ] Use environment variables for Twilio credentials
- [ ] Remove hardcoded credentials from test scripts
- [ ] Set up Firestore security rules for login-pictures
- [ ] Implement picture URL expiration (signed URLs)
- [ ] Add rate limiting for WhatsApp messages
- [ ] Add parent consent for receiving pictures

### Firestore Security Rules
```javascript
match /schools/{schoolId}/login-pictures/{pictureId} {
  // Only authenticated staff can write
  allow create: if request.auth != null 
    && request.auth.token.role in ['admin', 'staff']
    && request.resource.data.schoolId == schoolId;
  
  // Only authenticated users can read
  allow read: if request.auth != null;
  
  // No updates or deletes allowed
  allow update, delete: if false;
}
```

## Troubleshooting

### Issue: "Cannot save login picture: status is not .success"
**Status:** ✅ FIXED in latest code
**Cause:** Race condition - status changed before async save
**Solution:** State clearing now happens after picture save completes

### Issue: Picture not in Firestore
**Check:**
1. Console shows "✅ Login picture saved: {id}"?
2. Firestore rules allow writes?
3. App Check configured correctly?
4. Network connectivity OK?

### Issue: WhatsApp not delivered
**Check:**
1. HTTP Status: 201 (success)?
2. Parent number in E.164 format (+60...)?
3. Twilio WhatsApp sender approved?
4. Content template approved by WhatsApp?
5. Parent has active WhatsApp session with your number?

### Issue: Image too large error
**Current Limits:**
- Target size: 600KB before base64 encoding
- JPEG quality: 70%
- Firestore limit: 1MB per field
- If error occurs: Reduce quality or dimensions in `FirebaseService.saveLoginPicture()`

## Performance Metrics

### Target Performance
- Picture save time: < 2 seconds
- Image size: 400-600 KB
- WhatsApp delivery: < 10 seconds
- Total flow (detection → parent notification): < 15 seconds

### Actual Measurements
| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Picture save | < 2s | ___s | ☐ |
| Image size | 400-600KB | ___KB | ☐ |
| WhatsApp delivery | < 10s | ___s | ☐ |
| Total flow | < 15s | ___s | ☐ |

## Next Steps

### If All Tests Pass ✅
1. [ ] Document the flow for staff training
2. [ ] Create parent notification templates
3. [ ] Set up monitoring for failed saves
4. [ ] Implement picture cleanup (auto-delete after 30 days)
5. [ ] Add picture gallery view for staff
6. [ ] Implement parent verification UI

### If Tests Fail ❌
1. [ ] Share console logs (all `🔍` and `⚠️` lines)
2. [ ] Share Firestore screenshot
3. [ ] Check network connectivity
4. [ ] Verify Twilio configuration
5. [ ] Review App Check setup

## Test Completion

**Date:** ___________  
**Tester:** ___________  
**Duration:** ___________

**Overall Results:**
- Phase 1 (Picture Saving): ☐ PASS ☐ FAIL
- Phase 2 (Firestore Verify): ☐ PASS ☐ FAIL
- Phase 3 (WhatsApp Test): ☐ PASS ☐ FAIL
- Phase 4 (End-to-End): ☐ PASS ☐ FAIL

**Production Ready:** ☐ YES ☐ NO ☐ WITH MODIFICATIONS

**Notes:**
