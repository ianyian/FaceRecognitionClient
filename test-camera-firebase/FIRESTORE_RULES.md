# Fix Firestore Security Rules

## Problem

Error: "Missing or insufficient permissions"

This means your Firestore security rules don't allow the authenticated user to write to the `login-pictures` collection.

---

## Solution: Update Firestore Rules

### Step 1: Go to Firebase Console

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select project: **studio-4796520355-68573**
3. Click **Firestore Database** in left sidebar
4. Click **Rules** tab

---

### Step 2: Update the Rules

Replace your current rules with these:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Allow any authenticated user to read/write login-pictures
    match /login-pictures/{document} {
      allow read, write: if request.auth != null;
    }

    // Schools - read only for authenticated users
    match /schools/{schoolId} {
      allow read: if request.auth != null;
      allow write: if false; // Only admins should write (add admin check later)
    }

    // Staff - authenticated users can read, only owner can write
    match /staff/{staffId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == staffId;
    }

    // Students - authenticated users can read and write
    match /students/{studentId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }

    // Attendance - authenticated users can read and write
    match /attendance/{attendanceId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

---

### Step 3: Publish the Rules

1. Click **Publish** button
2. Wait for confirmation message
3. Rules are now active!

---

## What These Rules Do

| Collection         | Read                      | Write                     | Explanation                                  |
| ------------------ | ------------------------- | ------------------------- | -------------------------------------------- |
| **login-pictures** | ✅ Any authenticated user | ✅ Any authenticated user | Test photos can be saved by anyone logged in |
| **schools**        | ✅ Any authenticated user | ❌ No one                 | Read-only for security                       |
| **staff**          | ✅ Any authenticated user | ✅ Owner only             | Staff can only edit their own data           |
| **students**       | ✅ Any authenticated user | ✅ Any authenticated user | Can be managed by staff                      |
| **attendance**     | ✅ Any authenticated user | ✅ Any authenticated user | Staff can record attendance                  |

---

## Alternative: Temporary Test Rules (Less Secure)

If you just want to test quickly, use these **temporary** rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // WARNING: Allow all authenticated users to read/write everything
    // Only use for testing!
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

⚠️ **Remember to change these back to secure rules before production!**

---

## Test After Updating Rules

1. **Wait 10-30 seconds** for rules to propagate
2. **Refresh the test page**: http://localhost:8080
3. **Login** with your credentials
4. **Click "Capture"** button
5. Should now succeed! ✅

---

## Verify Rules Work

Check browser console (F12) for:

```
✅ Authenticated with Firebase: your-email@example.com
📸 Image captured, size: 250000 characters
✅ Saved to Firestore with ID: abc123xyz...
📥 Retrieved from Firestore
```

---

## Common Issues

### Still getting permission error?

1. **Clear browser cache** (Cmd+Shift+R or Ctrl+Shift+R)
2. **Wait 1 minute** for rules to fully propagate
3. **Check you're logged in** - look for "✅ Authenticated" status
4. **Verify rules are published** in Firebase Console

### Rules not updating?

1. Make sure you clicked **Publish** button
2. Check for syntax errors in rules editor
3. Try signing out and back in to the test page

---

## Security Notes

### Production Rules (More Secure)

For production iOS app, use stricter rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /login-pictures/{document} {
      // Only allow creating new pictures
      allow create: if request.auth != null;
      // Only allow reading your own pictures
      allow read: if request.auth != null &&
        resource.data.staffId == request.auth.uid;
      // No updates or deletes
      allow update, delete: if false;
    }

    match /staff/{staffId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == staffId;
    }

    // ... other collections with specific rules
  }
}
```

---

## Summary

1. ✅ Go to Firebase Console → Firestore → Rules
2. ✅ Copy and paste the rules from "Step 2" above
3. ✅ Click "Publish"
4. ✅ Wait 30 seconds
5. ✅ Test again - should work!

The key rule is:

```javascript
match /login-pictures/{document} {
  allow read, write: if request.auth != null;
}
```

This allows ANY authenticated user to read/write the login-pictures collection, which is what you need for testing! 🎉

---

**Last Updated:** November 29, 2025
