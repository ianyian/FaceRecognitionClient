# Firebase Setup for Test Program

## ⚠️ Important: The test program uses the same authentication as your iOS app

The test program signs in with **staff@example.com** / **password123** (same as iOS app test credentials).

**No additional Firebase setup needed if you already have:**

- ✅ Email/Password authentication enabled
- ✅ Test user created: staff@example.com
- ✅ Firestore rules allowing authenticated users to write

---

## 🔧 Verify Firebase Setup

### Step 1: Check Authentication is Enabled

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **studio-4796520355-68573**
3. Click **Authentication** in the left sidebar
4. Go to **Sign-in method** tab
5. Verify **Email/Password** is **Enabled**

**✅ Should already be enabled for iOS app!**

---

## 🔐 Step 2: Update Firestore Security Rules

### Option A: Permissive Rules (For Testing Only)

1. Go to **Firestore Database** in Firebase Console
2. Click **Rules** tab
3. Replace the rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users (including anonymous) to read/write login-pictures
    match /login-pictures/{document} {
      allow read, write: if request.auth != null;
    }

    // Keep your existing rules for other collections
    match /schools/{schoolId} {
      allow read: if request.auth != null;
    }

    match /staff/{staffId} {
      allow read, write: if request.auth != null;
    }

    match /students/{studentId} {
      allow read, write: if request.auth != null;
    }

    match /attendance/{attendanceId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

4. Click **Publish**

### Option B: More Secure Rules (Recommended for Production)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow authenticated users to read/write their own login pictures
    match /login-pictures/{document} {
      allow create: if request.auth != null;
      allow read: if request.auth != null;
      allow update, delete: if request.auth != null &&
        (resource.data.staffId == request.auth.uid ||
         request.auth.token.email != null);
    }

    // Staff can only access their own data
    match /staff/{staffId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
        request.auth.uid == staffId;
    }

    // Students - read only for authenticated users
    match /students/{studentId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null &&
        request.auth.token.email != null;
    }

    // Schools - read only
    match /schools/{schoolId} {
      allow read: if request.auth != null;
    }

    // Attendance - authenticated users can read/write
    match /attendance/{attendanceId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## 🧪 Step 3: Test the Setup

1. **Start the test server:**

   ```bash
   cd test-camera-firebase
   python3 -m http.server 8080
   ```

2. **Open in browser:**

   ```
   http://localhost:8080
   ```

3. **Watch for authentication:**

   - Status should show: "Authenticating..." → "Authenticated" → "Camera ready"
   - Check browser console (F12) for: "✅ Authenticated with Firebase: [user-id]"

4. **Test capture:**
   - Click "Capture" button
   - Should now succeed without "Missing or insufficient permissions" error

---

## ✅ Verification Checklist

- [ ] Anonymous authentication is enabled in Firebase Console
- [ ] Firestore rules allow authenticated users to write to `login-pictures`
- [ ] Test page shows "✅ Authenticated" status
- [ ] Capture button works without permission errors
- [ ] Images appear in Firestore Console under `login-pictures` collection

---

## 🐛 Troubleshooting

### Error: "Missing or insufficient permissions"

**Cause:** Firestore rules don't allow anonymous users to write

**Fix:**

1. Verify Anonymous auth is enabled (Step 1)
2. Check Firestore rules allow `request.auth != null` (Step 2)
3. Refresh the test page
4. Check browser console for authentication status

### Error: "Authentication failed"

**Cause:** Anonymous auth not enabled in Firebase

**Fix:**

1. Go to Firebase Console → Authentication
2. Enable Anonymous provider
3. Wait 1-2 minutes for changes to propagate
4. Refresh test page

### Error: "Firebase: Error (auth/operation-not-allowed)"

**Cause:** Anonymous sign-in method is not enabled

**Fix:**

1. Firebase Console → Authentication → Sign-in method
2. Click Anonymous → Enable → Save
3. Refresh test page

---

## 🔒 Security Notes

### Anonymous Authentication

- **What it does:** Creates a temporary, anonymous user ID
- **Lifespan:** Persists until browser clears storage
- **Security:** Limited access based on Firestore rules
- **Use case:** Perfect for testing without real user accounts

### For Production

**For iOS App (already implemented):**

- Uses email/password authentication
- Real staff accounts with proper credentials
- More secure and auditable

**For This Test Program:**

- Anonymous auth is fine for testing
- Don't use in production
- Consider adding email/password auth for production web apps

---

## 📊 Check Current Setup

### View Anonymous Users

1. Firebase Console → Authentication → Users tab
2. Look for users with "Anonymous" provider
3. Each test session creates a new anonymous user

### View Firestore Activity

1. Firebase Console → Firestore Database
2. Click on `login-pictures` collection
3. Check documents have correct `staffId` and `imageData`

### Check Console Logs

Browser console (F12) should show:

```
✅ Authenticated with Firebase: [random-user-id]
📸 Image captured, size: 250000 characters
✅ Saved to Firestore with ID: [document-id]
📥 Retrieved from Firestore
```

---

## 🔄 Comparison with iOS App

| Feature              | Web Test (Anonymous)   | iOS App (Email/Password) |
| -------------------- | ---------------------- | ------------------------ |
| **Auth Method**      | Anonymous              | Email/Password           |
| **User ID**          | Random temporary       | Actual staff ID          |
| **Firestore Access** | Through `request.auth` | Through `request.auth`   |
| **Security Rules**   | Same rules apply       | Same rules apply         |
| **Persistence**      | Until browser clear    | Until logout             |

**Both work with the same Firestore rules!** ✅

---

## 📝 Summary

1. **Enable Anonymous Auth** in Firebase Console
2. **Update Firestore Rules** to allow authenticated writes
3. **Test** that authentication works
4. **Verify** images save successfully

After these steps, the "Missing or insufficient permissions" error should be resolved! 🎉

---

**Status:** Setup Required  
**Time:** ~5 minutes  
**Difficulty:** Easy ⭐  
**Last Updated:** November 29, 2025
