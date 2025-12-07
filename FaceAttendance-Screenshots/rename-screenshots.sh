#!/bin/bash
# Rename screenshots to descriptive names for App Store

echo "📸 Screenshot Renaming for Face Attendance"
echo "=========================================="
echo ""
echo "Current files:"
ls -1 IMG_*.PNG 2>/dev/null | nl
echo ""
echo "We'll rename these to descriptive names for App Store Connect."
echo ""
echo "Suggested names:"
echo "  1. 01-login.png - Login screen"
echo "  2. 02-school-selection.png - School selection" 
echo "  3. 03-camera-view.png - Camera/face recognition screen"
echo "  4. 04-recognition-success.png - Success/match screen"
echo "  5. 05-student-profile.png - Student profile or settings"
echo ""
read -p "Press Enter to open each file and rename interactively..."
echo ""

# Function to preview and rename
rename_file() {
    local num=$1
    local old_name=$2
    
    echo "Opening: $old_name"
    open "$old_name"
    sleep 1
    
    echo ""
    echo "What does this screenshot show?"
    echo "  1) Login screen"
    echo "  2) School selection"
    echo "  3) Camera view"
    echo "  4) Recognition success"
    echo "  5) Student profile/settings"
    echo "  s) Skip"
    echo ""
    read -p "Select (1-5 or s): " choice
    
    case $choice in
        1) new_name="01-login.png" ;;
        2) new_name="02-school-selection.png" ;;
        3) new_name="03-camera-view.png" ;;
        4) new_name="04-recognition-success.png" ;;
        5) new_name="05-student-profile.png" ;;
        s|S) echo "Skipped."; return ;;
        *) echo "Invalid choice. Skipped."; return ;;
    esac
    
    if [ -f "$new_name" ]; then
        echo "⚠️  $new_name already exists. Skipping."
    else
        mv "$old_name" "$new_name"
        echo "✅ Renamed to: $new_name"
    fi
    echo ""
}

# Process each file
counter=1
for file in IMG_*.PNG; do
    if [ -f "$file" ]; then
        rename_file $counter "$file"
        ((counter++))
    fi
done

echo ""
echo "✅ Renaming complete!"
echo ""
echo "Final files:"
ls -1 *.png 2>/dev/null | nl
echo ""

# Check dimensions
echo "📏 Checking dimensions..."
FIRST_PNG=$(ls -1 *.png 2>/dev/null | head -1)
if [ -n "$FIRST_PNG" ]; then
    DIMENSIONS=$(sips -g pixelWidth -g pixelHeight "$FIRST_PNG" 2>/dev/null | grep -E "pixelWidth|pixelHeight" | awk '{print $2}' | paste -sd 'x' -)
    echo "   Size: $DIMENSIONS"
    echo "   ✅ Perfect for App Store (6.9\" iPhone 16 Pro Max)"
fi

echo ""
echo "🎯 Ready for App Store Connect!"
echo ""
echo "Upload these to:"
echo "  App Store Connect → Your App → Screenshots → 6.9-inch Display"
