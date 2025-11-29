#!/bin/bash

# Script to extract Firebase configuration from GoogleService-Info.plist
# This helps configure the web test app with the same Firebase project as iOS app

PLIST_FILE="../FaceRecognitionClient/GoogleService-Info.plist"

if [ ! -f "$PLIST_FILE" ]; then
    echo "❌ Error: GoogleService-Info.plist not found at $PLIST_FILE"
    exit 1
fi

echo "📄 Extracting Firebase configuration from GoogleService-Info.plist..."
echo ""
echo "Copy this configuration into app.js:"
echo ""
echo "const firebaseConfig = {"

# Extract API_KEY
API_KEY=$(/usr/libexec/PlistBuddy -c "Print :API_KEY" "$PLIST_FILE" 2>/dev/null)
echo "    apiKey: \"$API_KEY\","

# Extract PROJECT_ID
PROJECT_ID=$(/usr/libexec/PlistBuddy -c "Print :PROJECT_ID" "$PLIST_FILE" 2>/dev/null)
echo "    authDomain: \"$PROJECT_ID.firebaseapp.com\","
echo "    projectId: \"$PROJECT_ID\","

# Extract STORAGE_BUCKET
STORAGE_BUCKET=$(/usr/libexec/PlistBuddy -c "Print :STORAGE_BUCKET" "$PLIST_FILE" 2>/dev/null)
echo "    storageBucket: \"$STORAGE_BUCKET\","

# Extract GCM_SENDER_ID
GCM_SENDER_ID=$(/usr/libexec/PlistBuddy -c "Print :GCM_SENDER_ID" "$PLIST_FILE" 2>/dev/null)
echo "    messagingSenderId: \"$GCM_SENDER_ID\","

# Extract GOOGLE_APP_ID
GOOGLE_APP_ID=$(/usr/libexec/PlistBuddy -c "Print :GOOGLE_APP_ID" "$PLIST_FILE" 2>/dev/null)
echo "    appId: \"$GOOGLE_APP_ID\""

echo "};"
echo ""
echo "✅ Configuration extracted successfully!"
echo ""
echo "Next steps:"
echo "1. Copy the configuration above"
echo "2. Open app.js in an editor"
echo "3. Replace the firebaseConfig object (lines 8-15)"
echo "4. Save the file"
echo "5. Run: python3 -m http.server 8080"
echo "6. Open: http://localhost:8080"
