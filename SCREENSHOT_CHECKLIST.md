# Screenshot Capture Checklist

## Quick Instructions

1. In Xcode, select **iPhone 15 Pro Max** simulator
2. Press **⌘R** to run the app
3. Navigate to each screen below
4. Press **⌘S** to save screenshot (saves to Desktop)

## Screenshots to Capture (in order)

### ✅ Screenshot 1: Login Screen
**What to show:** Clean login interface with app branding
- [ ] Captured
- Caption: "Secure login with Firebase authentication"

### ✅ Screenshot 2: School Selection  
**What to show:** Dropdown with schools or school selected
- [ ] Captured
- Caption: "Multi-school support for flexible management"

### ✅ Screenshot 3: Camera View
**What to show:** Camera active, ready to scan
- [ ] Captured  
- Caption: "Instant face recognition in any lighting"

### ✅ Screenshot 4: Recognition Success
**What to show:** Green checkmark, student name displayed
- [ ] Captured
- Caption: "Attendance recorded automatically"

### ✅ Screenshot 5: Student Profile/Settings
**What to show:** Student details or app settings
- [ ] Captured
- Caption: "Complete student information and history"

## After Capturing

Screenshots will be on your Desktop named like:
- `Screenshot 2025-12-08 at XX.XX.XX.png`

### Organize Files
```bash
cd ~/Desktop
mkdir FaceAttendance-Screenshots
mv Screenshot*.png FaceAttendance-Screenshots/
cd FaceAttendance-Screenshots
```

### Rename Files (optional)
```bash
# Rename in order
mv "Screenshot 2025-12-08 at 10.30.45.png" "01-login.png"
mv "Screenshot 2025-12-08 at 10.31.12.png" "02-school-selection.png"
# ... etc
```

## Check Screenshot Size

```bash
sips -g pixelWidth -g pixelHeight 01-login.png
```

Should show: **1290 x 2796** (iPhone 15 Pro Max)

## Next: Upload to App Store Connect

Once you have 5 screenshots:
1. Log in to App Store Connect
2. Go to your app → Screenshots
3. Upload to "6.7-inch Display" section
4. Add captions (optional)
5. Save

---

**Ready?** Press ⌘R in Xcode to start!
