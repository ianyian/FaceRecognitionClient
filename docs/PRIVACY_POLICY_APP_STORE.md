# Privacy Policy for FaceAttend
**Face Recognition Attendance System**

**Effective Date:** December 9, 2025  
**Last Updated:** December 9, 2025

---

## Introduction

Welcome to FaceAttend ("we," "our," or "us"). We are committed to protecting the privacy and security of all users, especially children. This Privacy Policy explains how we collect, use, store, and protect information when you use our mobile application.

FaceAttend is designed exclusively for educational institutions and schools to track student attendance using face recognition technology. We take our responsibility to protect student data very seriously.

---

## Information We Collect

### 1. Face Recognition Data
- **What:** Facial images and biometric face templates of students
- **Why:** To identify students for attendance tracking
- **How:** Captured via device camera during check-in/check-out
- **Storage:** Securely stored in Firebase/Firestore with encryption

### 2. Student Information
- **Name, ID, grade level**
- **Parent/guardian contact information (phone numbers for WhatsApp notifications)**
- **Check-in/check-out timestamps**
- **Attendance history**

### 3. Staff Information
- **Email address (for authentication)**
- **Name and role**
- **School affiliation**
- **Login activity logs**

### 4. Technical Information
- **Device type and operating system**
- **App version**
- **IP address (for security)**
- **Error logs and crash reports**

---

## How We Use Information

We use collected information ONLY for the following purposes:

1. **Attendance Tracking:** Identify students and record check-in/check-out times
2. **Parent Notifications:** Send WhatsApp messages to parents when students check in/out
3. **Security:** Authenticate staff members and prevent unauthorized access
4. **Improvement:** Analyze usage patterns to improve app performance
5. **Compliance:** Meet legal requirements for data retention

**We do NOT:**
- Sell or rent any data to third parties
- Use face data for advertising or marketing
- Share data with anyone except authorized school staff and parents
- Use face recognition for any purpose other than attendance

---

## Legal Basis for Processing (GDPR)

For users in the European Economic Area (EEA), we process data based on:

1. **Consent:** Parental consent for processing children's face data
2. **Legitimate Interest:** School's legitimate interest in tracking attendance
3. **Legal Obligation:** Compliance with education regulations

---

## Parental Consent (COPPA Compliance)

**For Children Under 13:**

We comply with the Children's Online Privacy Protection Act (COPPA). Before any student under 13 is enrolled:

1. **Written Consent Required:** Schools must obtain written parental/guardian consent
2. **Consent Form:** Parents must sign a consent form explaining:
   - What data is collected (face images, personal information)
   - How it's used (attendance tracking, notifications)
   - How long it's kept (see Data Retention below)
   - Rights to access and delete data
3. **Opt-Out Option:** Parents can opt-out and use alternative attendance methods

**Consent Verification:** Schools are responsible for obtaining and maintaining consent documentation.

---

## Data Storage and Security

### Security Measures

1. **Encryption:**
   - All data encrypted in transit (TLS/SSL)
   - Face data encrypted at rest in Firebase/Firestore
   
2. **Access Control:**
   - Staff-only access with authentication
   - Multi-factor authentication available
   - Role-based permissions
   
3. **Firebase Security:**
   - Firestore security rules restrict data access
   - App Check validates requests from legitimate app instances
   - Regular security audits
   
4. **Data Isolation:**
   - Each school's data is completely isolated
   - No cross-school data sharing

### Data Location

Data is stored on Google Cloud Platform (Firebase) servers located in:
- United States (primary)
- Backed up to multiple regions for redundancy

---

## Data Retention

| Data Type | Retention Period |
|-----------|-----------------|
| Face Images | Until student graduates or is unenrolled, or upon parent request |
| Attendance Records | As required by school policy (typically 3-7 years) |
| Student Information | Until student graduates or is unenrolled |
| Staff Accounts | Until employment ends or account is deleted |
| Audit Logs | 1 year |

**Deletion:** When retention period expires or upon request, data is permanently deleted within 30 days.

---

## Third-Party Services

We use the following third-party services:

### Firebase (Google)
- **Purpose:** Database, authentication, storage
- **Privacy Policy:** https://firebase.google.com/support/privacy
- **Data Shared:** All app data
- **Certification:** SOC 2, ISO 27001, GDPR compliant

### Twilio (WhatsApp Integration)
- **Purpose:** Send parent notifications via WhatsApp
- **Privacy Policy:** https://www.twilio.com/legal/privacy
- **Data Shared:** Parent phone numbers, notification messages
- **Note:** Messages are transactional only (attendance notifications)

### MediaPipe (Google)
- **Purpose:** Face detection and recognition processing
- **Privacy:** Runs locally on device, no data sent to Google
- **Open Source:** https://github.com/google/mediapipe

---

## Your Rights

### Parents/Guardians Have the Right To:

1. **Access:** View all data collected about your child
2. **Rectification:** Correct inaccurate information
3. **Deletion:** Request deletion of your child's data
4. **Data Portability:** Receive a copy of your child's data in a portable format
5. **Withdraw Consent:** Opt-out of face recognition (alternative attendance methods available)
6. **Object:** Object to data processing for specific purposes

### How to Exercise Rights:

Contact your school administrator or email us at: **ianyian@gmail.com**

We will respond within 30 days.

---

## Children's Privacy

We are committed to complying with COPPA and protecting children's privacy:

1. **No Marketing to Children:** We never use data for advertising
2. **Minimal Data Collection:** We collect only what's necessary for attendance
3. **Parental Control:** Parents control consent and can request deletion
4. **Age Verification:** Schools verify ages and obtain appropriate consent
5. **Staff Training:** Schools must train staff on privacy requirements

---

## Data Breach Notification

In the unlikely event of a data breach:

1. We will notify affected schools within 72 hours
2. Schools must notify parents as required by law
3. We will provide details about what data was affected
4. We will explain steps taken to mitigate the breach

---

## Changes to This Policy

We may update this Privacy Policy from time to time. Changes will be:

1. Posted on this page with a new "Last Updated" date
2. Sent via email to all school administrators
3. Displayed in the app when significant changes occur

Continued use of the app after changes constitutes acceptance of the new policy.

---

## International Data Transfers

If you are located outside the United States:

- Your data may be transferred to and processed in the US
- We ensure appropriate safeguards are in place
- Standard Contractual Clauses (SCCs) used for GDPR compliance

---

## Contact Information

**For Privacy Questions or Requests:**

**Email:** ianyian@gmail.com  
**Website:** https://ianyian.github.io/FaceRecognitionClient  
**Support:** https://ianyian.github.io/FaceRecognitionClient/support

**School Administrators:**
Please maintain your own records of parental consent and communicate with parents about this Privacy Policy.

---

## Specific State Privacy Rights

### California Residents (CCPA/CPRA)
- Right to know what personal information is collected
- Right to delete personal information
- Right to opt-out of sale (note: we do NOT sell data)
- Right to non-discrimination

### Virginia, Colorado, Connecticut Residents
- Similar rights to CCPA
- Right to opt-out of targeted advertising (not applicable)
- Right to correct inaccurate information

**To exercise these rights:** Contact ianyian@gmail.com

---

## Supervisory Authority

EEA residents have the right to lodge a complaint with a supervisory authority if you believe we've violated GDPR.

---

## App Store Privacy Labels

### Data Collected and Linked to User:
- **Contact Info:** Email, phone number
- **Photos:** Face images for recognition
- **Identifiers:** Student ID, parent ID
- **Usage Data:** Attendance records, check-in times

### Data Not Collected:
- Location data
- Financial information
- Health data
- Browsing history
- Search history

### Tracking:
- **We do NOT track users across other apps or websites**

---

## Acknowledgment and Consent

By using FaceAttend:

1. Schools acknowledge they have obtained proper parental consent
2. Staff acknowledge they will use the app only for legitimate attendance purposes
3. All users agree to this Privacy Policy

---

**Questions?** Contact us at ianyian@gmail.com

**Last Updated:** December 9, 2025

---

*This privacy policy was created specifically for FaceAttend and complies with COPPA, GDPR, CCPA, and other major privacy regulations. Schools using this app are responsible for ensuring compliance with local regulations.*
