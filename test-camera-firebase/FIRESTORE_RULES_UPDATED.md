# Firestore Security Rules - Updated for Nested Structure

## ⚠️ Important: Collection Path Structure

This app now uses **nested collections** to match your existing system structure:

```
/schools/{schoolId}/login-pictures/{documentId}
```

**Not:** `/login-pictures/{documentId}` (flat structure)

This matches the structure from your working app in `key.md`.

---

## Problem

Error: "Missing or insufficient permissions"

This happens because:

1. Firestore rules don't allow writes to the collection path, OR
2. The collection path in the code doesn't match the rules

---

## Solution: Update Firestore Rules

### Step 1: Go to Firebase Console

1. Open [Firebase Console](https://console.firebase.google.com/)
2. Select project: **studio-4796520355-68573**
3. Click **Firestore Database** in left sidebar
4. Click **Rules** tab

---

### Step 2: Update the Rules for Nested Structure

Replace your current rules with these:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Schools collection and subcollections
    match /schools/{schoolId} {
      // School document - authenticated users can read
      allow read: if request.auth != null;

      // Login pictures subcollection - authenticated users can read/write
      match /login-pictures/{pictureId} {
        allow read, write: if request.auth != null;
      }

      // Students subcollection - authenticated users can read/write
      match /students/{studentId} {
        allow read, write: if request.auth != null;
      }

      // Staff subcollection - authenticated users can read/write
      match /staff/{staffId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && request.auth.uid == staffId;
      }

      // Attendance subcollection - authenticated users can read/write
      match /attendance/{attendanceId} {
        allow read, write: if request.auth != null;
      }
    }

    // Deny all other paths by default
    match /{document=**} {
      allow read, write: if false;
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

The rules now support the nested structure:

| Path                                 | Read                      | Write                     |
| ------------------------------------ | ------------------------- | ------------------------- |
| `/schools/{id}`                      | ✅ Any authenticated user | ❌ No one                 |
| `/schools/{id}/login-pictures/{doc}` | ✅ Any authenticated user | ✅ Any authenticated user |
| `/schools/{id}/students/{doc}`       | ✅ Any authenticated user | ✅ Any authenticated user |
| `/schools/{id}/staff/{doc}`          | ✅ Any authenticated user | ✅ Owner only             |
| `/schools/{id}/attendance/{doc}`     | ✅ Any authenticated user | ✅ Any authenticated user |

---

## How the App Saves Data

The test program now saves to:

```javascript
/schools/main-tuition-center/login-pictures/{documentId}
```

With document structure:

```javascript
{
  staffId: "user-uid",
  staffEmail: "staff@example.com",
  schoolId: "main-tuition-center",
  timestamp: ServerTimestamp,
  imageData: "data:image/jpeg;base64,..."
}
```

---

## Diagnostic Tools

The test program now includes diagnostic buttons to verify:

1. **🔐 Test Auth** - Check if you're authenticated
2. **📖 Test Read** - Try reading from Firestore
3. **✍️ Test Write** - Try writing a test document
4. **🏫 Test Schools** - Check if the school document exists

Use these to identify where the permission issue is occurring.

---

## Creating the School Document

If diagnostic tests show the school document doesn't exist, create it in Firebase Console:

1. Go to **Firestore Database**
2. Click **Start collection**
3. Collection ID: `schools`
4. Document ID: `main-tuition-center`
5. Add fields:
   - `name` (string): "Main Tuition Center"
   - `active` (boolean): true
6. Click **Save**

---

## Alternative: Temporary Test Rules (Less Secure)

For quick testing only:

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

⚠️ **Use production rules before deploying!**

---

## Test After Updating Rules

1. **Wait 30 seconds** for rules to propagate
2. **Refresh the test page**: http://localhost:8080
3. **Login** with credentials
4. **Run diagnostic tests** to verify connectivity
5. **Click "Capture"** button
6. Should now succeed! ✅

---

## Verify in Firebase Console

After successful save, check:

1. Go to Firestore Database
2. Navigate to: `schools` → `main-tuition-center` → `login-pictures`
3. You should see your captured images there!

---

## Summary

✅ Updated rules support nested structure: `/schools/{schoolId}/login-pictures`  
✅ Matches your existing system structure from key.md  
✅ Test program now saves to correct path  
✅ Diagnostic tools help identify issues  
✅ School-based organization for better data management

---

**Last Updated:** December 2024
