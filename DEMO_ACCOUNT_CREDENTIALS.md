# Demo Account for App Review

## ⚠️ IMPORTANT: For App Store Connect Submission

Copy the text below into **App Store Connect → App Review Information → Notes** section.

---

## Demo Account Credentials

```
Email/Username: demo01
Password: helloworld
School Selection: demo01
```

## Login Instructions for Apple Reviewers

**Step-by-Step:**

1. Launch the Face Attendance app
2. On the login screen, enter:
   - **Email/Username:** `demo01`
   - **Password:** `helloworld`
3. When prompted to select a school, choose **"demo01"** from the dropdown
4. Tap "Login" button
5. **IMPORTANT:** When the app loads, you may see a prompt or button to **"Load Latest Face Data"** or **"Sync Face Data"**
   - **Please tap this button** to download the face recognition data for the 5 test students
   - This loads the facial landmarks needed for recognition testing
   - Wait for the sync to complete (usually 5-10 seconds)
6. The app will navigate to the main camera/attendance screen

## Test Data Available

The demo account includes **5 pre-enrolled test students** for face recognition testing:
- Students have been created through the CoMa (Configuration Manager) web application
- Face data is available for recognition testing
- All students are associated with the "demo01" school

## Features to Test

✓ **Secure Authentication** - Login with demo01 credentials  
✓ **School Selection** - Select demo01 from school dropdown  
✓ **Face Recognition** - Camera-based student identification  
✓ **Attendance Logging** - Automatic attendance recording  
✓ **Student Profiles** - View enrolled students  
✓ **Attendance History** - View past attendance records  
✓ **Offline Mode** - Test without internet connection (after initial login)

## Camera Permission

On first launch, the app will request camera permission:
## Testing Face Recognition

**Prerequisites:**
- Ensure you've loaded the latest Face Data (see step 5 in Login Instructions above)
- Grant camera permission when prompted

**Steps:**
1. After login and face data sync, point the camera at any human face
2. The system will attempt to match against the 5 enrolled students
## Important Notes

- **Demo account has full access** to all features
- **Internet connection required** for initial login and face data sync
- **Face data must be loaded** - Look for "Load Latest Face Data" prompt after login
- **Offline mode works** after initial authentication and data sync
- **All test data is isolated** to demo01/dem01 school
- **Account remains active** and will not expire
- Camera permission is granted
- Face is well-lit and looking at cameraagainst the 5 enrolled students
3. When a match is found, you'll see:
   - Green checkmark ✓
   - Student name displayed
   - Attendance automatically logged

## Important Notes

- **Demo account has full access** to all features
- **Internet connection required** for initial login and sync
- **Offline mode works** after initial authentication
- **All test data is isolated** to demo01/dem01 school
- **Account remains active** and will not expire

## Support Contact

If you encounter any issues during review:

**Email:** ianyian@gmail.com  
**Response Time:** Within 2-4 hours during business hours (GMT+8)

## Technical Details

- **Authentication:** Firebase Authentication
- **Database:** Cloud Firestore
- **Face Recognition:** MediaPipe AI (local processing)
- **Minimum iOS:** 15.0
- **Camera Required:** Yes
- **Internet Required:** Initial setup only

---

Thank you for reviewing Face Attendance!

We've designed this app to help educational institutions modernize their attendance tracking with secure, privacy-first face recognition technology.
