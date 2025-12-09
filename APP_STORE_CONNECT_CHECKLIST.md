# App Store Connect Submission Checklist

## 🎯 Complete Checklist for Face Attendance App

### ✅ Prerequisites (COMPLETED)

- [x] App icon created (1024x1024)
- [x] 5 screenshots captured (1320 x 2868)
- [x] Privacy policy hosted: https://ianyian.github.io/FaceRecognitionClient/privacy.html
- [x] Support page hosted: https://ianyian.github.io/FaceRecognitionClient/support.html
- [x] Demo account created: demo01 / helloworld / demo01
- [x] Test students created (5 students)
- [x] App description written (see APP_STORE_DESCRIPTION.md)

### ⬜ Apple Developer Program

- [ ] Enroll at https://developer.apple.com ($99/year)
- [ ] Wait for approval (1-2 business days)
- [ ] Accept agreements in App Store Connect
- [ ] Set up banking/tax information (for paid apps, optional for free)

### ⬜ App Store Connect Setup

**Navigate to:** https://appstoreconnect.apple.com

#### Create New App

- [ ] Click "My Apps" → "+" → "New App"
- [ ] Select iOS platform
- [ ] App Name: **Face Attendance** (or your preferred name)
- [ ] Primary Language: English (U.S.)
- [ ] Bundle ID: **nano.FaceRecognitionClient**
- [ ] SKU: **faceattendance001** (or unique identifier)

#### App Information

- [ ] **Name:** Face Attendance
- [ ] **Subtitle:** Face Recognition Tracking
- [ ] **Category:** 
  - Primary: Education
  - Secondary: Business (optional)
- [ ] **Content Rights:** Check if you own all rights

#### Pricing and Availability

- [ ] **Price:** Free
- [ ] **Availability:** All countries (or select specific)
- [ ] **Release:** Automatically after approval

### ⬜ Version Information (1.0)

#### App Privacy

- [ ] Click "Get Started" on App Privacy
- [ ] Answer questions about data collection:
  - **Email Address** → Yes (for authentication)
  - **Name** → Yes (staff and student names)
  - **Face Data** → Yes (for face recognition)
  - **Purpose:** App Functionality, Analytics (if applicable)
- [ ] Link to privacy policy: `https://ianyian.github.io/FaceRecognitionClient/privacy.html`

#### Screenshots and Previews

**6.9-inch Display (iPhone 16 Pro Max):**
- [ ] Upload `01-screenshot.png`
- [ ] Upload `02-screenshot.png`
- [ ] Upload `03-screenshot.png`
- [ ] Upload `04-screenshot.png`
- [ ] Upload `05-screenshot.png`

**Optional Captions:** (recommended)
- [ ] Screenshot 1: "Secure staff authentication with Firebase"
- [ ] Screenshot 2: "Multi-school support for flexible management"
- [ ] Screenshot 3: "Advanced AI-powered face recognition"
- [ ] Screenshot 4: "Attendance logged automatically"
- [ ] Screenshot 5: "Complete student profiles and history"

#### Promotional Text (170 chars, optional)

```
Effortlessly track attendance with AI-powered face recognition. Designed for tuition centers, schools, and training programs. Fast, secure, and easy to use.
```

#### Description (Copy from APP_STORE_DESCRIPTION.md)

```
Transform Your Attendance Tracking with Face Attendance

Say goodbye to manual roll calls and time-consuming attendance sheets. Face Attendance brings cutting-edge facial recognition technology to your tuition center, making check-ins instant, accurate, and effortless.

✨ KEY FEATURES

INSTANT FACE RECOGNITION
• Lightning-fast student identification in seconds
• Advanced MediaPipe AI technology for accuracy
• Works in various lighting conditions
• No need for ID cards or manual entry

MULTI-SCHOOL SUPPORT
• Perfect for staff working across multiple locations
• Seamlessly switch between tuition centers
• Global access for administrative users
• School-specific data segregation for privacy

[... rest of description from APP_STORE_DESCRIPTION.md ...]
```

#### Keywords (100 chars)

```
attendance,face recognition,education,school,tuition,check-in,student,tracking,AI,biometric
```

#### Support URL

```
https://ianyian.github.io/FaceRecognitionClient/support.html
```

#### Marketing URL (optional)

```
https://ianyian.github.io/FaceRecognitionClient/
```

### ⬜ Build Upload

#### In Xcode:

1. [ ] Open project: `FaceRecognitionClient.xcworkspace`
2. [ ] Select **Any iOS Device (arm64)** as destination
3. [ ] Product → Archive
4. [ ] Wait for archive to complete
5. [ ] When Organizer opens, click "Distribute App"
6. [ ] Select "App Store Connect"
7. [ ] Select "Upload"
8. [ ] Follow prompts to upload
9. [ ] Wait for processing (10-30 minutes)

#### After Upload:

- [ ] Return to App Store Connect
- [ ] Refresh the page
- [ ] Under "Build", click "+" to select uploaded build
- [ ] Select the build that was just uploaded

### ⬜ App Review Information

**Sign-in Required:** Yes

**Demo Account:**
```
Username: demo01
Password: helloworld
```

**Notes for Reviewer:** (Copy from DEMO_ACCOUNT_CREDENTIALS.md)

```
DEMO ACCOUNT CREDENTIALS

Email/Username: demo01
Password: helloworld
School Selection: dem01

IMPORTANT SETUP STEPS:

1. Launch the Face Attendance app
2. Enter the username and password above
3. When prompted, select "dem01" from the school dropdown
4. Tap "Login"
5. IMPORTANT: When prompted, tap "Load Latest Face Data" or "Sync Face Data" button
   - This downloads the facial recognition data for the 5 test students
   - Wait 5-10 seconds for sync to complete
   - This step is required for face recognition to work

TESTING FACE RECOGNITION:

The demo account includes 5 pre-enrolled test students.

To test face recognition:
1. After login, load the latest Face Data (tap the sync button if prompted)
2. The camera view will appear
3. Grant camera permission when requested
4. Point the camera at any human face
5. The system will identify the closest matching student
6. A green checkmark will appear with the student's name
7. Attendance is automatically recorded

FEATURES TO TEST:

✓ Secure login with Firebase Authentication
✓ Multi-school selection (choose "dem01")
✓ Real-time face recognition (camera required)
✓ Attendance logging and confirmation
✓ Student profile viewing
✓ Attendance history and reports
✓ Offline mode (disable network, record attendance, re-enable)
IMPORTANT NOTES:

- Must load/sync Face Data after login (tap the sync button when prompted)
- Camera permission required for face recognition
- Face processing happens locally on device (privacy-first)
- Internet required for initial login and face data sync
- Offline mode works after initial setup and data sync
- All test data is isolated to demo account
- All test data is isolated to demo account

CONTACT:

For any issues during review:
Email: ianyian@gmail.com
Response time: Within 2-4 hours (GMT+8)

Thank you for reviewing Face Attendance!
```

**Contact Information:**
- [ ] First Name: Your first name
- [ ] Last Name: Your last name
- [ ] Phone: Your phone number
- [ ] Email: ianyian@gmail.com

### ⬜ Age Rating

- [ ] Click "Edit" next to Age Rating
- [ ] Answer questionnaire honestly
- [ ] Likely rating: 4+ or 9+ (depends on content)
- [ ] Save

### ⬜ App Store Connect Agreement

- [ ] Review all information
- [ ] Ensure no "Complete Required Information" warnings
- [ ] Click "Add for Review" or "Submit for Review"
- [ ] Confirm submission

### ⬜ After Submission

- [ ] Status changes to "Waiting for Review"
- [ ] Apple reviews typically take 1-5 days
- [ ] Monitor email for any messages from Apple
- [ ] Respond within 24 hours if Apple asks questions

---

## 🚨 Common Rejection Reasons & How to Avoid

### ❌ Demo Account Issues
**Prevention:** Test demo01/helloworld/dem01 login before submitting ✓

### ❌ Missing Privacy Policy
**Prevention:** Privacy policy URL added ✓

### ❌ App Crashes
**Prevention:** Test on actual device thoroughly before upload

### ❌ Misleading Screenshots
**Prevention:** Screenshots show actual app functionality ✓

### ❌ Incomplete App Information
**Prevention:** Fill out ALL required fields

### ❌ Guideline 2.3.10 - Accurate Metadata
**Prevention:** Description matches actual features ✓

---

## 📧 What Happens Next

### Timeline:

1. **Day 0:** Submit app
2. **Day 1-2:** "In Review" status
3. **Day 2-5:** Apple reviews and tests
4. **Result:** Approved OR Rejected with feedback

### If Approved: 🎉
- App goes live automatically (or on scheduled date)
- Available in App Store within 24 hours
- You'll get congratulations email

### If Rejected: 😔
- Read rejection reason carefully
- Fix the issue
- Respond to Apple if clarification needed
- Resubmit (usually faster second review)

---

## 🎯 Quick Reference

**What You Need Right Now:**
1. Apple Developer account ($99) - enroll first
2. All materials ready (you have these ✓)
3. Xcode archive and upload
4. Fill out App Store Connect
5. Submit for review

**Estimated Time:**
- Apple enrollment: 1-2 days wait
- App Store Connect setup: 1-2 hours
- Xcode archive/upload: 30 minutes
- Apple review: 1-5 days

**Total from start to approval: ~3-7 days**

---

## 📞 Need Help?

**Common Issues:**

**Q: Build fails to upload?**
A: Check code signing, ensure provisioning profile is correct

**Q: Demo account not working?**
A: Verify in Firebase Console that demo01 user exists

**Q: Privacy policy link doesn't work?**
A: Verify GitHub Pages is enabled and URL is correct

**Q: App rejected?**
A: Read Apple's feedback, fix issues, resubmit

---

**Next Step:** Enroll in Apple Developer Program at https://developer.apple.com

Once approved, you can proceed with Xcode archive and App Store Connect setup!
