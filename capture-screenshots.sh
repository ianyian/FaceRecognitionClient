#!/bin/bash
# Screenshot Capture Helper for Face Attendance App

echo "📸 Face Attendance Screenshot Capture Helper"
echo "=============================================="
echo ""
echo "INSTRUCTIONS:"
echo "1. Your simulator should be running with the app"
echo "2. Navigate to each screen you want to capture"
echo "3. Press ⌘S (Command+S) in Simulator window"
echo "4. Screenshot saves to Desktop automatically"
echo ""
echo "SCREENS TO CAPTURE (in order):"
echo "  1️⃣  Login Screen"
echo "  2️⃣  School Selection"  
echo "  3️⃣  Camera View (face recognition)"
echo "  4️⃣  Success/Match Screen"
echo "  5️⃣  Student Profile or Settings"
echo ""
echo "After capturing all screenshots, press Enter to organize them..."
read -p ""

echo ""
echo "📁 Organizing screenshots..."

# Create directory for screenshots
SCREENSHOT_DIR="$HOME/Desktop/FaceAttendance-Screenshots"
mkdir -p "$SCREENSHOT_DIR"

# Count screenshots on Desktop
SCREENSHOT_COUNT=$(ls "$HOME/Desktop"/Screenshot*.png 2>/dev/null | wc -l | tr -d ' ')

if [ "$SCREENSHOT_COUNT" -gt 0 ]; then
    echo "Found $SCREENSHOT_COUNT screenshot(s) on Desktop"
    
    # Move to organized folder
    mv "$HOME/Desktop"/Screenshot*.png "$SCREENSHOT_DIR/" 2>/dev/null
    
    echo "✅ Screenshots moved to: $SCREENSHOT_DIR"
    echo ""
    
    # Show what we have
    echo "Files:"
    ls -1 "$SCREENSHOT_DIR"/*.png 2>/dev/null | nl
    
    echo ""
    echo "📏 Checking dimensions..."
    FIRST_FILE=$(ls "$SCREENSHOT_DIR"/*.png 2>/dev/null | head -1)
    if [ -n "$FIRST_FILE" ]; then
        DIMENSIONS=$(sips -g pixelWidth -g pixelHeight "$FIRST_FILE" 2>/dev/null | grep -E "pixelWidth|pixelHeight" | awk '{print $2}' | paste -sd 'x' -)
        echo "   Size: $DIMENSIONS"
        
        if [[ "$DIMENSIONS" == "1320x2868" ]] || [[ "$DIMENSIONS" == "1290x2796" ]]; then
            echo "   ✅ Perfect! This is the correct size for App Store"
        else
            echo "   ⚠️  Note: Expected 1290x2796 or 1320x2868 for iPhone Pro Max"
        fi
    fi
    
    echo ""
    read -p "Would you like to rename files in order? (y/n) " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd "$SCREENSHOT_DIR"
        
        echo "Please rename files manually, or enter names:"
        echo "Suggested names:"
        echo "  01-login.png"
        echo "  02-school-selection.png"
        echo "  03-camera-view.png"
        echo "  04-recognition-success.png"
        echo "  05-student-profile.png"
        echo ""
        echo "Files are in: $SCREENSHOT_DIR"
    fi
    
    # Open the folder
    open "$SCREENSHOT_DIR"
    
    echo ""
    echo "✅ Done! Screenshots are ready for App Store Connect"
    echo ""
    echo "Next steps:"
    echo "1. Review screenshots in Finder"
    echo "2. Optional: Add text overlays in Canva/Figma"
    echo "3. Upload to App Store Connect"
    
else
    echo "❌ No screenshots found on Desktop"
    echo ""
    echo "Make sure to:"
    echo "  • Have the simulator in focus"
    echo "  • Press ⌘S (Command+S) to capture"
    echo "  • Wait for the camera shutter sound"
    echo ""
    echo "Try again!"
fi
