# Firebase Camera Test Program

## Overview

This is a standalone web application to test the camera capture and Firebase Firestore storage functionality. It verifies that:

1. Camera can be accessed from the browser
2. Images can be captured and converted to base64
3. Images can be saved to Firestore `login-pictures` collection
4. Images can be retrieved and displayed from Firestore

## Setup Instructions

### 1. Configure Firebase

Edit `app.js` and replace the Firebase configuration with your actual credentials from `GoogleService-Info.plist`:

```javascript
const firebaseConfig = {
  apiKey: "YOUR_API_KEY",
  authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
  projectId: "studio-4796520355-68573",
  storageBucket: "YOUR_PROJECT_ID.appspot.com",
  messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
  appId: "YOUR_APP_ID",
};
```

**To find these values:**

1. Open `GoogleService-Info.plist` in the iOS project
2. Look for these keys:
   - `API_KEY` → `apiKey`
   - `PROJECT_ID` → `projectId` and `authDomain`
   - `STORAGE_BUCKET` → `storageBucket`
   - `GCM_SENDER_ID` → `messagingSenderId`
   - `GOOGLE_APP_ID` → `appId`

### 2. Run the Test

**Option A: Simple Python Server (Recommended)**

```bash
cd test-camera-firebase
python3 -m http.server 8080
```

Then open: http://localhost:8080

**Option B: VS Code Live Server**

1. Install "Live Server" extension
2. Right-click `index.html`
3. Select "Open with Live Server"

**Option C: Node.js HTTP Server**

```bash
cd test-camera-firebase
npx http-server -p 8080
```

### 3. Test the Application

1. **Camera Access**

   - Browser will prompt for camera permission
   - Allow access to continue
   - You should see live video feed

2. **Capture Image**

   - Click the "Capture" button
   - Watch status messages:
     - "Capturing image from camera"
     - "Saving to Firestore..."
     - "Retrieving from Firestore..."
     - "Success!"

3. **Verify Display**

   - Retrieved image appears below
   - Document metadata shown (ID, Staff ID, Timestamp)
   - Image should match what camera captured

4. **Download Test**

   - Click "Download Image" button
   - Image file downloads to your computer
   - Open file to verify it's correct

5. **Verify in Firebase Console**
   - Go to Firebase Console
   - Navigate to Firestore Database
   - Open `login-pictures` collection
   - You should see new documents with:
     - `staffId`: "test-web-user"
     - `timestamp`: Recent timestamp
     - `imageData`: Base64 data URI (long string starting with "data:image/jpeg;base64,...")

## What This Tests

### ✅ Camera Functionality

- Camera initialization
- Video stream capture
- Still photo capture from stream
- Base64 image encoding (JPEG, 80% quality)

### ✅ Firebase Integration

- Firestore connection
- Document creation in `login-pictures` collection
- Server timestamp generation
- Large data storage (base64 images)

### ✅ Data Integrity

- Capture → Save → Retrieve cycle
- Image data remains intact through Firebase
- Document ID generation and retrieval
- Metadata storage

### ✅ iOS App Compatibility

- Uses same image format (JPEG, 80%)
- Uses same base64 encoding (data URI)
- Uses same Firestore collection name
- Uses same document structure

## File Structure

```
test-camera-firebase/
├── index.html          # Main HTML page
├── styles.css          # Styling and layout
├── app.js             # JavaScript logic and Firebase integration
└── README.md          # This file
```

## Troubleshooting

### Camera Not Working

**Problem:** Black screen or "Camera error" message
**Solutions:**

1. Ensure HTTPS or localhost (camera requires secure context)
2. Check browser permissions: Settings → Privacy → Camera
3. Try different browser (Chrome, Firefox, Safari)
4. Restart browser

### Firebase Connection Error

**Problem:** "Failed to save" or connection timeout
**Solutions:**

1. Verify Firebase config is correct in `app.js`
2. Check Firebase project is active in console
3. Verify Firestore database is created
4. Check Firestore security rules allow writes

### CORS Errors

**Problem:** "Cross-Origin Request Blocked" in console
**Solutions:**

1. Use a local server (not file:// protocol)
2. Use Python server or Live Server extension
3. Don't open HTML file directly in browser

### Image Not Displaying

**Problem:** Image captured but not shown
**Solutions:**

1. Check browser console for errors
2. Verify data retrieved from Firestore
3. Check image data URI format is correct
4. Try downloading image to verify data

## Firestore Security Rules

For testing, ensure your Firestore rules allow writes:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /login-pictures/{document} {
      // Allow read/write for testing (restrict in production)
      allow read, write: if true;
    }
  }
}
```

**⚠️ Important:** These permissive rules are for testing only. In production, require authentication:

```javascript
match /login-pictures/{document} {
  allow read, write: if request.auth != null;
}
```

## Expected Console Output

When everything works correctly, you should see:

```
📸 Image captured, size: 123456 characters
✅ Saved to Firestore with ID: abcd1234xyz
📥 Retrieved from Firestore
📥 Image downloaded (when download button clicked)
```

## Differences from iOS App

| Feature          | Web Test        | iOS App                    |
| ---------------- | --------------- | -------------------------- |
| Staff ID         | "test-web-user" | Actual staff ID from login |
| Camera           | Browser API     | AVFoundation               |
| Face Detection   | None            | Vision framework (planned) |
| Face Recognition | None            | CoreML model (planned)     |
| Image Processing | Direct base64   | UIImage → JPEG → base64    |

## Next Steps

After verifying this test works:

1. ✅ Confirms Firebase connection is correct
2. ✅ Confirms Firestore collection is accessible
3. ✅ Confirms image format is compatible
4. ➡️ Test iOS app with same Firestore collection
5. ➡️ Verify iOS app can read images saved by web test
6. ➡️ Verify web test can read images saved by iOS app

## Cleanup

To remove test data:

1. Go to Firebase Console
2. Navigate to Firestore Database
3. Open `login-pictures` collection
4. Delete documents with `staffId: "test-web-user"`

Or use this JavaScript in browser console:

```javascript
// Delete all test documents (run in browser console on test page)
const testDocs = await getDocs(
  query(
    collection(db, "login-pictures"),
    where("staffId", "==", "test-web-user")
  )
);
testDocs.forEach(async (doc) => {
  await deleteDoc(doc.ref);
  console.log("Deleted:", doc.id);
});
```

---

**Status:** Ready for Testing
**Last Updated:** November 29, 2025
**Version:** 1.0
