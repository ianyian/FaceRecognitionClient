# FaceCheck iOS Client - Interactive Mockup

This is an interactive HTML/CSS/JavaScript mockup of the FaceCheck iOS Client application for testing UI/UX before implementing in SwiftUI.

## 🚀 Features

### Login Screen

- Tuition center code selection (dropdown)
- Email and password authentication
- "Remember Me" functionality with localStorage persistence
- Form validation
- Loading states and error handling
- Auto-login for remembered users
- Responsive design

### Camera Screen

- Full-screen camera preview simulation
- Real-time face detection overlay with animated corners
- Status indicator with color-coded states:
  - 🔍 **Scanning** (Blue) - Looking for faces
  - 👤 **Face Detected** (Blue) - Face found
  - ⏳ **Processing** (Orange) - Analyzing face
  - ✅ **Access OK** (Green) - Student recognized
  - ❌ **Access FAILED** (Red) - Face not recognized
- Attendance details display (last check, student name, processing time)
- Logout functionality
- Staff name display
- Haptic feedback simulation

### Demo Controls

Interactive buttons to test all UI states:

- Scanning
- Face Detected
- Processing
- Success
- Failed
- No Face

## 📱 How to Use

### Option 1: Open in Browser

1. Open `index.html` in any modern web browser
2. The app will load with the login screen

### Option 2: VS Code Live Server

1. Install "Live Server" extension in VS Code
2. Right-click `index.html` and select "Open with Live Server"
3. The app will open in your default browser with auto-reload

### Option 3: Python HTTP Server

```bash
cd mockup
python3 -m http.server 8000
# Open http://localhost:8000 in browser
```

## 🔐 Test Credentials

### Staff Account

- **Email**: `staff@example.com`
- **Password**: `password123`
- **Name**: Ian Wong
- **Role**: Reception

### Admin Account

- **Email**: `admin@example.com`
- **Password**: `admin123`
- **Name**: Sarah Lee
- **Role**: Admin

## 🎯 Testing Scenarios

### Login Flow

1. Select a tuition center from dropdown
2. Enter email and password
3. Check "Remember Me" (optional)
4. Click "LOGIN"
5. Observe loading state
6. See success transition to camera screen

### Camera Flow

1. After login, camera screen automatically starts scanning
2. After 2-4 seconds, a face is automatically detected
3. Processing begins automatically
4. Random success (70%) or failure (30%) result
5. On success:
   - Student details displayed
   - WhatsApp notification logged to console
   - Returns to scanning after 3 seconds
6. On failure:
   - Error message displayed
   - Returns to scanning after 2 seconds

### Manual State Testing

Use the demo controls panel (bottom right) to manually trigger any state:

- Click any button to see that state immediately
- Useful for testing animations, colors, and transitions
- No automatic progression when using manual controls

### Auto-Login Testing

1. Login with "Remember Me" checked
2. Click "Logout"
3. Refresh the page (F5)
4. Observe automatic login after 1 second

## 🎨 Design Highlights

### iOS-Style Design

- **Colors**: iOS system colors (blue, green, red, orange)
- **Fonts**: San Francisco font stack (-apple-system)
- **Shadows**: Subtle iOS-style shadows
- **Animations**: Smooth 0.3s ease transitions
- **Blur Effects**: Backdrop blur on top bar

### Responsive Design

- Works on mobile, tablet, and desktop
- Landscape mode optimizations
- Touch-friendly targets (minimum 44pt)

### Accessibility

- High contrast colors
- Clear visual feedback
- Large, readable text
- Semantic HTML

## 📐 Screen Specifications

### Login Screen

- Max width: 400px
- Centered on screen
- Gradient background
- White card with rounded corners
- Touch-optimized input fields

### Camera Screen

- Full-screen layout
- Top bar: Logout button + Staff info
- Middle: Camera preview with face detection
- Bottom: Status card with details
- Demo controls: Fixed bottom-right

## 🔄 State Machine

```
Login Screen
    ↓ (Login Success)
Camera Screen (Scanning)
    ↓ (Face Detected)
Processing
    ↓
Success / Failure
    ↓ (Auto timeout)
Back to Scanning
```

## 🛠️ Technical Details

### File Structure

```
mockup/
├── index.html      # Main HTML structure
├── styles.css      # All styling and animations
├── app.js          # Application logic and state
└── README.md       # This file
```

### Key Technologies

- Pure HTML/CSS/JavaScript (no frameworks)
- CSS Grid and Flexbox for layouts
- CSS Variables for theming
- LocalStorage for persistence
- Console logging for debugging

### Browser Support

- Chrome/Edge 90+
- Safari 14+
- Firefox 88+
- Mobile browsers (iOS Safari, Chrome Mobile)

## 🎬 Next Steps

Once the mockup is approved:

1. **Review Feedback**

   - Test on different devices
   - Gather user feedback
   - Refine interactions

2. **Convert to SwiftUI**

   - Translate HTML structure to SwiftUI Views
   - Port CSS styles to SwiftUI modifiers
   - Implement real camera functionality
   - Add Firebase integration
   - Implement face recognition

3. **Key Mappings**
   - `<div>` → `VStack/HStack/ZStack`
   - CSS classes → SwiftUI modifiers
   - JavaScript state → `@State` and `@ObservedObject`
   - Animations → `.animation()` modifier

## 💡 Tips

- **Open Browser Console** (F12) to see WhatsApp notifications and debug logs
- **Use Demo Controls** for rapid UI state testing
- **Test on Mobile** by opening on your phone's browser
- **Check Responsiveness** by resizing browser window

## 📝 Notes

- This is a visual mockup only - no real camera or face recognition
- WhatsApp integration is simulated (console logs only)
- Authentication is client-side mock data (not secure)
- Face detection is random/timed simulation
- Designed to match iOS look and feel as closely as possible

## 🐛 Known Limitations

- No actual camera access (placeholder only)
- No real face detection algorithm
- Mock authentication (not production-ready)
- Haptic feedback only works on supported devices
- Demo controls visible in mockup (remove for production)

## ✅ Approval Checklist

Before moving to SwiftUI implementation:

- [ ] Login screen design approved
- [ ] Camera screen layout approved
- [ ] Status states and colors approved
- [ ] Face detection overlay design approved
- [ ] Animations and transitions approved
- [ ] Error handling flows approved
- [ ] Mobile responsiveness verified
- [ ] Accessibility considerations reviewed

---

**Ready to proceed to SwiftUI implementation once approved!** 🚀
