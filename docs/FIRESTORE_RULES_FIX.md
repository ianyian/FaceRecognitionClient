# Firestore Rules Fix - Permission Error

## Error Message
```
Listen for query at schools/global/faceDataMeta/version failed: 
Missing or insufficient permissions.
```

## Problem
The app tries to read `schools/{schoolId}/faceDataMeta/version` to check if cached face data is up-to-date, but Firestore security rules were blocking this access.

## Solution

### Option 1: Deploy via Script (Recommended)
```bash
cd /Users/xj/git/schoolAttenance-Client/FaceRecognitionClient
./deploy-firestore-rules.sh
```

This script will:
1. Check if Firebase CLI is installed
2. Show current project
3. Preview the rules
4. Deploy to Firestore

### Option 2: Deploy via Firebase CLI
```bash
firebase deploy --only firestore:rules
```

### Option 3: Manual Update via Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Firestore Database** → **Rules** tab
4. Copy the contents of `firestore.rules` file
5. Paste into the editor
6. Click **Publish**

## What Changed

### Added Permission for faceDataMeta
```javascript
match /faceDataMeta/{document} {
  allow read: if isAuthenticated();
  allow write: if isAdmin();
}
```

This allows all authenticated staff to read the face data version metadata.

### Added Permission for login-pictures
```javascript
match /login-pictures/{pictureId} {
  allow create: if isStaff() && 
                   request.resource.data.schoolId == schoolId;
  allow read: if isAuthenticated();
  allow update, delete: if false;
}
```

This allows staff to create login pictures (immutable records).

## Complete Rules Structure

```
schools/{schoolId}/
  ├── faceDataMeta/           ✅ READ: authenticated, WRITE: admin
  ├── faceData/               ✅ READ/WRITE: staff, DELETE: admin
  ├── students/               ✅ READ/WRITE: staff, DELETE: admin
  ├── login-pictures/         ✅ CREATE: staff, READ: authenticated
  └── attendance/             ✅ READ/WRITE: staff, DELETE: admin

staff/{staffId}               ✅ READ: self or admin, WRITE: admin
```

## Testing After Deployment

1. **Restart the app** (important!)
2. Login as demo01/helloworld
3. Select school demo01
4. Click sync button (⭐)
5. You should NOT see the permission error anymore

### Expected Logs (Success)
```
✅ Loaded face data version: 1
📊 Cache status: 15 records
✅ Face data cache loaded: 15 records
```

### If Error Persists
1. Check rules are deployed: Firebase Console → Firestore → Rules tab
2. Verify you're logged in as authenticated user
3. Check the staff document exists in Firestore
4. Try logging out and back in

## Security Notes

### Current Rules Allow:
- ✅ Authenticated staff can read all schools
- ✅ Authenticated staff can read/write face data
- ✅ Authenticated staff can read/write students
- ✅ Authenticated staff can create login pictures
- ✅ Only admins can delete critical data

### Current Rules Block:
- ❌ Unauthenticated access to any data
- ❌ Non-staff users from accessing school data
- ❌ Updates or deletes to login pictures (immutable)
- ❌ Staff from deleting schools or critical records

## Related Files
- `firestore.rules` - The security rules file
- `deploy-firestore-rules.sh` - Deployment script
- `.firebaserc` - Firebase project configuration (if exists)
- `firebase.json` - Firebase configuration (if exists)

## Need Help?

### Install Firebase CLI
```bash
npm install -g firebase-tools
```

### Login to Firebase
```bash
firebase login
```

### List Projects
```bash
firebase projects:list
```

### Select Project
```bash
firebase use <project-id>
```

### Check Current Rules
Go to: Firebase Console → Firestore Database → Rules tab

## Next Steps

After deploying the rules:
1. ✅ Test face data sync (should work without permission error)
2. ✅ Test login picture saving (should work without permission error)
3. ✅ Verify only authenticated users can access data
4. ✅ Monitor Firebase Console → Firestore → Usage for any unusual activity
