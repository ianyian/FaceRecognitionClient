# Demo Account Setup Guide for App Review

Apple requires a working demo/test account so reviewers can fully test your app. This is **critical** - many apps get rejected for not providing proper test credentials.

## Quick Summary

**What You Need:**
- Working email/password credentials
- Valid school code
- Pre-loaded test data (students with face data)
- Clear instructions for reviewers
- Account that won't expire during review

**Time Required:** 15-30 minutes

---

## Why Demo Account is Critical

### Apple's Review Process

1. Reviewer downloads your app
2. Tries to use it like a real user
3. Tests all features listed in description
4. **If login fails or there's no test data**, app gets rejected

### Common Rejection Reasons

❌ "Demo account credentials don't work"
❌ "Test account has no data to test with"
❌ "Instructions unclear, couldn't log in"
❌ "School code not provided"
❌ "Account expired during review"
❌ "Cannot test core features without data"

---

## Step 1: Create Test Account in Firebase

### Option A: Using Firebase Console (Easiest)

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to **Authentication** → **Users**
4. Click **"Add User"**
5. Enter:
   ```
   Email: demo@faceattendance.com
   Password: AppReview2025!
   ```
6. Click **"Add User"**

### Option B: Create via Your App

If your app has admin functionality:

1. Use admin account to create new user
2. Set role to **Admin** (so reviewers can see all features)
3. Assign to a test school

### Recommended Credentials

```
Email: demo@faceattendance.com
Password: AppReview2025!
Role: Admin
School: Demo School (or your test school name)
School Code: DEMO2025
```

**Important:** 
- Use a password that's easy to type (no special characters that might confuse)
- Make it memorable but secure
- Don't use your personal accounts

---

## Step 2: Create Test School

### In Firestore Database

1. Go to **Firestore Database** in Firebase Console
2. Navigate to `schools` collection
3. Click **"Add Document"**
4. Create test school:

```json
{
  "id": "demo-school-2025",
  "name": "Demo Tuition Center",
  "code": "DEMO2025",
  "isActive": 1,
  "createdAt": [current timestamp],
  "updatedAt": [current timestamp],
  "address": "123 Education Street, Demo City",
  "contactEmail": "demo@faceattendance.com",
  "contactPhone": "+1-555-0100"
}
```

### Associate User with School

In `users` or `staff` collection:

```json
{
  "uid": "[demo user UID from Authentication]",
  "email": "demo@faceattendance.com",
  "firstName": "Demo",
  "lastName": "Reviewer",
  "displayName": "Demo Reviewer",
  "role": "admin",
  "schoolId": "demo-school-2025",
  "isActive": 1,
  "createdAt": [timestamp],
  "updatedAt": [timestamp]
}
```

---

## Step 3: Add Test Students with Face Data

### Create 5-10 Sample Students

This is **crucial** - reviewers need to test face recognition!

#### Option 1: Pre-populate via Firebase

In `students` collection:

```json
{
  "id": "student-001",
  "firstName": "John",
  "lastName": "Smith",
  "studentId": "STU001",
  "schoolId": "demo-school-2025",
  "grade": "Grade 10",
  "isActive": 1,
  "faceData": {
    "landmarks": [...], // Your face landmark data
    "embedding": [...], // Face embedding vector
    "createdAt": [timestamp],
    "updatedAt": [timestamp]
  },
  "createdAt": [timestamp],
  "updatedAt": [timestamp]
}
```

Repeat for 5-10 students:
- John Smith (STU001)
- Emma Johnson (STU002)
- Michael Chen (STU003)
- Sarah Williams (STU004)
- David Brown (STU005)

#### Option 2: Enroll via App (If You Have Enrollment Feature)

1. Log in with demo account
2. Use your app's enrollment feature
3. Add 5-10 test students with face data
4. Verify they appear in the system

#### Option 3: Note in Review Instructions

If face recognition requires real faces:

```
Note: Face recognition requires actual human faces. 
To test this feature, reviewers can use their own face
to register a new student, then test recognition 
with that enrolled face.

Alternative: We have included 5 pre-enrolled test students.
Use any human face to simulate recognition (the system
will match to closest enrolled student for demo purposes).
```

---

## Step 4: Add Sample Attendance Records

Populate attendance history so reviewers can see the app in action:

```json
{
  "id": "attendance-001",
  "studentId": "student-001",
  "studentName": "John Smith",
  "schoolId": "demo-school-2025",
  "timestamp": "2025-12-01T09:15:00Z",
  "recordedBy": "demo@faceattendance.com",
  "recognitionConfidence": 0.95,
  "status": "present",
  "createdAt": [timestamp]
}
```

Add 20-30 records across different dates and students so:
- Attendance history looks realistic
- Reports show meaningful data
- Dashboard has statistics to display

---

## Step 5: Write Clear Instructions for Reviewers

Apple allows you to provide review notes in App Store Connect. Be **extremely clear**:

### Template: Review Instructions

```
DEMO ACCOUNT CREDENTIALS

Email: demo@faceattendance.com
Password: AppReview2025!
School Code: DEMO2025

IMPORTANT SETUP STEPS:

1. Launch the Face Attendance app
2. Enter the email and password above
3. When prompted, select "Demo Tuition Center" from the school dropdown
4. Tap "Login"

TESTING FACE RECOGNITION:

The demo account includes 5 pre-enrolled test students:
- John Smith (STU001)
- Emma Johnson (STU002)
- Michael Chen (STU003)
- Sarah Williams (STU004)
- David Brown (STU005)

To test face recognition:
1. After login, the camera view will appear
2. Point the camera at any human face
3. The system will identify the closest matching student from the test database
4. A green checkmark will appear with the student's name
5. Attendance is automatically recorded

Note: Since face recognition uses MediaPipe AI, any human face can be used
to demonstrate the recognition feature with the test students.

FEATURES TO TEST:

✓ Secure login with Firebase Authentication
✓ Multi-school selection
✓ Real-time face recognition (camera required)
✓ Attendance logging and confirmation
✓ Student profile viewing
✓ Attendance history and reports
✓ Offline mode (disable network, record attendance, re-enable to see sync)
✓ Settings and preferences

IMPORTANT NOTES:

- Camera permission will be requested on first use
- Face recognition processes locally on device (privacy-first)
- Internet connection required for initial login
- Offline mode works after initial setup
- All test data is isolated to demo account

CONTACT:

For any issues during review, contact: ianyian@gmail.com
Response time: Within 2 hours during business hours

Thank you for reviewing Face Attendance!
```

---

## Step 6: Test Your Demo Account

**Before submitting**, thoroughly test the demo account yourself:

### Testing Checklist

- [ ] Log in with demo credentials successfully
- [ ] School selection shows demo school
- [ ] Camera activates after login
- [ ] Face recognition works (or clearly documented if simulator)
- [ ] Student profiles load with data
- [ ] Attendance history shows records
- [ ] Reports/analytics display data
- [ ] Logout works
- [ ] Re-login works without issues
- [ ] All features accessible with demo account
- [ ] No crashes or errors during testing
- [ ] Instructions match actual app flow

### Test on Multiple Devices

1. **Test in Simulator**
   - iPhone 15 Pro Max
   - Fresh install
   - Follow your own instructions exactly

2. **Test on Real Device**
   - Install from Xcode
   - Test camera functionality
   - Verify face recognition (if applicable)

3. **Test on Friend's Device**
   - Send TestFlight invite
   - Give them only the instructions (no other help)
   - See if they can successfully test all features

If your friend can't figure it out, **the reviewer won't either**. Revise instructions.

---

## Common Demo Account Mistakes

### ❌ Mistake 1: Account Not Set Up Properly

**Problem:** Credentials don't work
**Solution:** Test login before submission

### ❌ Mistake 2: No Test Data

**Problem:** App looks empty after login
**Solution:** Pre-populate 5-10 students and 20-30 attendance records

### ❌ Mistake 3: School Code Not Provided

**Problem:** Reviewer doesn't know which school to select
**Solution:** Clearly state school name or code in instructions

### ❌ Mistake 4: Unclear Instructions

**Problem:** Instructions are vague or skip steps
**Solution:** Write step-by-step instructions a non-technical person can follow

### ❌ Mistake 5: Account Expires

**Problem:** Password expires or account gets locked during review
**Solution:** Set account to never expire, disable 2FA

### ❌ Mistake 6: Camera Features Not Documented

**Problem:** Reviewer can't test camera because simulator doesn't have camera
**Solution:** Provide alternative testing method or note simulator limitations

### ❌ Mistake 7: Role Restrictions

**Problem:** Demo account has limited access, can't test all features
**Solution:** Give demo account **Admin** role for full access

---

## Advanced: Multiple Test Accounts

If your app has different roles, provide multiple accounts:

### Admin Account
```
Email: admin-demo@faceattendance.com
Password: AdminReview2025!
Role: Admin
Description: Full access to all features, user management, reports
```

### Reception Account
```
Email: reception-demo@faceattendance.com
Password: ReceptionReview2025!
Role: Reception
Description: Can record attendance, view students, limited settings
```

### Teacher Account
```
Email: teacher-demo@faceattendance.com
Password: TeacherReview2025!
Role: Teacher
Description: View-only access to attendance and student info
```

**In Review Notes:**
```
We provide three demo accounts to test different permission levels:

ADMIN (recommended for review):
Email: admin-demo@faceattendance.com
Password: AdminReview2025!
School: Demo Tuition Center
Access: All features

RECEPTION:
Email: reception-demo@faceattendance.com
Password: ReceptionReview2025!
School: Demo Tuition Center
Access: Attendance recording, student management

TEACHER:
Email: teacher-demo@faceattendance.com
Password: TeacherReview2025!
School: Demo Tuition Center
Access: View-only attendance and student info

Please test with ADMIN account first for full functionality.
```

---

## Security Considerations

### Do's ✅

- Use dedicated test accounts (not real user accounts)
- Use simple, memorable passwords
- Document all credentials clearly
- Set accounts to never expire
- Keep test data obviously fake (use "Demo," "Test," etc.)

### Don'ts ❌

- Don't use real student data
- Don't use your personal email/password
- Don't use overly complex passwords reviewers might mistype
- Don't enable 2FA on demo accounts
- Don't let accounts expire during review (review takes 1-5 days)

---

## Firestore Security Rules for Demo Account

Make sure your Firestore rules allow the demo account to access test data:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Allow demo account full access to demo school data
    match /schools/{schoolId} {
      allow read: if request.auth != null;
      allow write: if request.auth.token.email == 'demo@faceattendance.com' 
                   || request.auth.token.role == 'admin';
    }
    
    match /students/{studentId} {
      allow read: if request.auth != null 
                  && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.schoolId == resource.data.schoolId;
      allow write: if request.auth != null 
                   && (get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin'
                   || get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'reception');
    }
    
    match /attendance/{attendanceId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
    }
  }
}
```

Test that demo account can:
- Read school data
- Read/write student data
- Create attendance records

---

## Quick Setup Script (Firebase Admin SDK)

If you want to automate test data creation:

```javascript
// setup-demo-account.js
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

async function setupDemoAccount() {
  // 1. Create demo user
  const userRecord = await auth.createUser({
    email: 'demo@faceattendance.com',
    password: 'AppReview2025!',
    displayName: 'Demo Reviewer'
  });
  
  console.log('Created user:', userRecord.uid);
  
  // 2. Create demo school
  await db.collection('schools').doc('demo-school-2025').set({
    name: 'Demo Tuition Center',
    code: 'DEMO2025',
    isActive: 1,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  console.log('Created demo school');
  
  // 3. Create staff profile
  await db.collection('users').doc(userRecord.uid).set({
    email: 'demo@faceattendance.com',
    firstName: 'Demo',
    lastName: 'Reviewer',
    displayName: 'Demo Reviewer',
    role: 'admin',
    schoolId: 'demo-school-2025',
    isActive: 1,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  console.log('Created staff profile');
  
  // 4. Create test students
  const students = [
    { id: 'STU001', firstName: 'John', lastName: 'Smith' },
    { id: 'STU002', firstName: 'Emma', lastName: 'Johnson' },
    { id: 'STU003', firstName: 'Michael', lastName: 'Chen' },
    { id: 'STU004', firstName: 'Sarah', lastName: 'Williams' },
    { id: 'STU005', firstName: 'David', lastName: 'Brown' }
  ];
  
  for (const student of students) {
    await db.collection('students').add({
      studentId: student.id,
      firstName: student.firstName,
      lastName: student.lastName,
      schoolId: 'demo-school-2025',
      grade: 'Grade 10',
      isActive: 1,
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });
    console.log(`Created student: ${student.firstName} ${student.lastName}`);
  }
  
  console.log('Demo account setup complete!');
}

setupDemoAccount().catch(console.error);
```

Run:
```bash
node setup-demo-account.js
```

---

## Checklist Before Submission

- [ ] Demo account created in Firebase Authentication
- [ ] Demo account can log in successfully
- [ ] Demo school created with clear name
- [ ] School code documented in review notes
- [ ] 5-10 test students created with face data (if applicable)
- [ ] 20-30 sample attendance records added
- [ ] Demo account has Admin role for full access
- [ ] Clear step-by-step instructions written
- [ ] Instructions include email, password, and school code
- [ ] Tested demo account on fresh install
- [ ] All features accessible with demo account
- [ ] Account won't expire during review period
- [ ] No 2FA enabled on demo account
- [ ] Contact email provided in review notes
- [ ] Alternative testing method documented (if simulator limitations)

---

## Where to Enter Demo Credentials in App Store Connect

1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Go to **My Apps** → Select your app
3. Click on the version you're submitting
4. Scroll to **App Review Information**
5. Under **Sign-in required**, toggle **YES**
6. Enter credentials:
   - **Username:** demo@faceattendance.com
   - **Password:** AppReview2025!
7. In **Notes** section, paste your detailed instructions (from template above)
8. Click **Save**

---

## Final Tips

1. **Test exactly as reviewer would**
   - Fresh install
   - Follow only the written instructions
   - Don't assume any knowledge

2. **Make it foolproof**
   - Every step documented
   - No assumptions
   - Clear, simple language

3. **Provide alternatives**
   - If camera doesn't work in simulator, explain
   - If some features need specific setup, document it

4. **Be responsive**
   - Check email during review period
   - Apple may reach out with questions
   - Respond within 24 hours

5. **Keep account active**
   - Don't delete demo data during review
   - Don't change password
   - Don't disable account

---

## If Review Gets Rejected for Demo Account

**Common rejection:**
> "We were unable to sign in to your app with the demo account credentials you provided."

**Response template:**

```
Hello App Review Team,

Thank you for your feedback. I apologize for the inconvenience.

I have verified the demo account credentials are working correctly:

Email: demo@faceattendance.com
Password: AppReview2025!
School Code: DEMO2025

Steps to log in:
1. Enter email and password on login screen
2. Select "Demo Tuition Center" from school dropdown
3. Tap Login button

I have successfully logged in with these credentials on multiple devices
today (December 8, 2025) and confirmed all features are accessible.

If you continue to experience issues, please let me know the specific
error message you're seeing, and I will resolve it immediately.

Alternatively, I can provide:
- A screen recording showing successful login
- Alternative test credentials
- Remote support to troubleshoot

Contact: ianyian@gmail.com (response within 2 hours)

Thank you for your patience.
```

---

## Summary

**Essential Demo Account Components:**

1. ✅ **Working credentials** (email + password)
2. ✅ **School code** (if applicable)
3. ✅ **Pre-loaded test data** (students, attendance)
4. ✅ **Clear instructions** (step-by-step)
5. ✅ **Admin access** (full features)
6. ✅ **Won't expire** (during review period)
7. ✅ **Tested personally** (before submission)

**Time investment:** 30 minutes now saves 1-2 weeks of rejection delays!

---

Ready to set up your demo account? Start with creating the Firebase user, then add test data!
