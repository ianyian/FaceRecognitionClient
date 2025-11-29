# Firebase Setup Guide

## 🔥 Current Issue: Authentication Error

The error `ERROR_INVALID_CREDENTIAL` means you need to create staff accounts in Firebase first.

## ✅ Quick Setup Steps

### 1. Create Staff Account in Firebase

You have two options:

#### **Option A: Using Firebase Console (Easiest)**

1. Go to [Firebase Console](https://console.firebase.google.com/project/studio-4796520355-68573)
2. Navigate to **Authentication** → **Users** tab
3. Click **"Add User"**
4. Enter:
   - **Email**: `staff@example.com`
   - **Password**: `password123`
5. Click **"Add User"**
6. Note the **User UID** that's generated

#### **Option B: Using Firebase Admin SDK or REST API**

If you have access to your backend/web app, you can create users programmatically.

### 2. Create Staff Profile in Firestore

After creating the auth user, you need to add their profile to Firestore:

1. Go to [Firestore Console](https://console.firebase.google.com/project/studio-4796520355-68573/firestore)
2. Navigate to the `staff` collection (or create it if it doesn't exist)
3. Click **"Add Document"**
4. Set **Document ID** to the **User UID** from step 1
5. Add these fields:

```json
{
  "email": "staff@example.com",
  "firstName": "Ian",
  "lastName": "Wong",
  "role": "reception",
  "schoolId": "main-tuition-center",
  "isActive": true,
  "createdAt": [Current Timestamp]
}
```

### 3. Create School Document (if not exists)

1. In Firestore, navigate to or create the `schools` collection
2. Add a document with ID: `main-tuition-center`
3. Add these fields:

```json
{
  "name": "Main Tuition Center",
  "isActive": true,
  "createdAt": [Current Timestamp]
}
```

### 4. Test Login in iOS App

Now you can use these credentials in your app:

- **School Code**: `main-tuition-center`
- **Email**: `staff@example.com`
- **Password**: `password123`

## 🎯 Quick Test Script (if you have Firebase Admin access)

If you have Node.js and Firebase Admin SDK set up, you can run:

```javascript
const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const auth = admin.auth();
const db = admin.firestore();

async function createTestStaff() {
  try {
    // Create auth user
    const userRecord = await auth.createUser({
      email: "staff@example.com",
      password: "password123",
      displayName: "Ian Wong",
    });

    console.log("✅ Auth user created:", userRecord.uid);

    // Create staff profile
    await db.collection("staff").doc(userRecord.uid).set({
      email: "staff@example.com",
      firstName: "Ian",
      lastName: "Wong",
      role: "reception",
      schoolId: "main-tuition-center",
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log("✅ Staff profile created");

    // Create school if not exists
    await db.collection("schools").doc("main-tuition-center").set(
      {
        name: "Main Tuition Center",
        isActive: true,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    console.log("✅ School created");
    console.log("\n📱 Test with:");
    console.log("   Email: staff@example.com");
    console.log("   Password: password123");
  } catch (error) {
    console.error("❌ Error:", error);
  }
}

createTestStaff();
```

## 🔒 Firebase Security Rules

Make sure your Firestore security rules allow staff to read their own profile:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Staff can read their own profile
    match /staff/{staffId} {
      allow read: if request.auth != null && request.auth.uid == staffId;
    }

    // Staff can read their school
    match /schools/{schoolId} {
      allow read: if request.auth != null &&
                     exists(/databases/$(database)/documents/staff/$(request.auth.uid)) &&
                     get(/databases/$(database)/documents/staff/$(request.auth.uid)).data.schoolId == schoolId &&
                     get(/databases/$(database)/documents/staff/$(request.auth.uid)).data.isActive == true;
    }

    // Students within a school
    match /schools/{schoolId}/students/{studentId} {
      allow read: if request.auth != null &&
                     exists(/databases/$(database)/documents/staff/$(request.auth.uid)) &&
                     get(/databases/$(database)/documents/staff/$(request.auth.uid)).data.schoolId == schoolId &&
                     get(/databases/$(database)/documents/staff/$(request.auth.uid)).data.isActive == true;
    }
  }
}
```

## 🧪 Multiple Test Accounts

Create these additional accounts for testing different roles:

### Admin Account

- **Email**: `admin@example.com`
- **Password**: `admin123`
- **Role**: `admin`

### Teacher Account

- **Email**: `teacher@example.com`
- **Password**: `teacher123`
- **Role**: `teacher`

## ✅ Verification Checklist

- [ ] Firebase Authentication is enabled in console
- [ ] Email/Password provider is enabled
- [ ] Staff user created in Authentication
- [ ] Staff profile document exists in Firestore `staff` collection
- [ ] Staff document ID matches Auth UID
- [ ] School document exists in Firestore
- [ ] `schoolId` in staff profile matches school document ID
- [ ] `isActive` is set to `true`
- [ ] Security rules allow the operations

## 🐛 Troubleshooting

### Error: "The supplied auth credential is malformed or has expired"

- ✅ **Solution**: Create the user account first (see above)

### Error: "Staff profile not found"

- ✅ **Solution**: Make sure Firestore document ID matches Auth UID

### Error: "School not found"

- ✅ **Solution**: Create the school document in Firestore

### Error: "Account is inactive"

- ✅ **Solution**: Set `isActive: true` in staff profile

### Still not working?

1. Check Firebase Console → Authentication to verify user exists
2. Check Firestore → `staff` collection to verify profile exists
3. Verify the document ID matches the Auth UID
4. Check Xcode console for detailed error messages

## 📞 Next Steps

1. Go to Firebase Console
2. Create the test user
3. Create the staff profile
4. Create the school document
5. Try logging in again!

---

**Firebase Project**: studio-4796520355-68573  
**Console URL**: https://console.firebase.google.com/project/studio-4796520355-68573
