#!/bin/bash
# App Store Build and Archive Script
# For FaceAttend - Face Recognition Attendance System

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="FaceRecognitionClient"
SCHEME="FaceRecognitionClient"
WORKSPACE="${PROJECT_NAME}.xcworkspace"
CONFIGURATION="Release"
ARCHIVE_PATH="$HOME/Desktop/${PROJECT_NAME}.xcarchive"
EXPORT_PATH="$HOME/Desktop/${PROJECT_NAME}-AppStore"

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    FaceAttend App Store Build & Archive       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Clean build folder
echo -e "${YELLOW}[1/7]${NC} Cleaning build folder..."
xcodebuild clean \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    | xcpretty || true

echo -e "${GREEN}✓ Clean complete${NC}\n"

# Step 2: Install pods
echo -e "${YELLOW}[2/7]${NC} Installing CocoaPods dependencies..."
if [ -f "Podfile" ]; then
    pod install --repo-update
    echo -e "${GREEN}✓ Pods installed${NC}\n"
else
    echo -e "${YELLOW}⚠ No Podfile found, skipping pod install${NC}\n"
fi

# Step 3: Validate project settings
echo -e "${YELLOW}[3/7]${NC} Validating project settings..."

# Check version and build number
VERSION=$(xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" -showBuildSettings | grep MARKETING_VERSION | awk '{print $3}' | head -1)
BUILD=$(xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" -showBuildSettings | grep CURRENT_PROJECT_VERSION | awk '{print $3}' | head -1)
BUNDLE_ID=$(xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" -showBuildSettings | grep PRODUCT_BUNDLE_IDENTIFIER | awk '{print $3}' | head -1)

echo -e "  Version: ${GREEN}${VERSION}${NC}"
echo -e "  Build: ${GREEN}${BUILD}${NC}"
echo -e "  Bundle ID: ${GREEN}${BUNDLE_ID}${NC}"

# Confirm with user
echo ""
read -p "Continue with these settings? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Build cancelled${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Settings validated${NC}\n"

# Step 4: Build for testing
echo -e "${YELLOW}[4/7]${NC} Building for testing..."
xcodebuild build \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination 'generic/platform=iOS' \
    | xcpretty

echo -e "${GREEN}✓ Build successful${NC}\n"

# Step 5: Run tests (optional - can be skipped)
echo -e "${YELLOW}[5/7]${NC} Running tests..."
read -p "Run unit tests? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    xcodebuild test \
        -workspace "$WORKSPACE" \
        -scheme "$SCHEME" \
        -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
        | xcpretty || echo -e "${YELLOW}⚠ Tests failed or no tests found${NC}"
else
    echo -e "${YELLOW}⚠ Skipping tests${NC}"
fi
echo ""

# Step 6: Create archive
echo -e "${YELLOW}[6/7]${NC} Creating archive..."
echo -e "  Archive path: ${BLUE}${ARCHIVE_PATH}${NC}"

# Remove old archive if exists
if [ -d "$ARCHIVE_PATH" ]; then
    echo "  Removing old archive..."
    rm -rf "$ARCHIVE_PATH"
fi

xcodebuild archive \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -archivePath "$ARCHIVE_PATH" \
    -destination 'generic/platform=iOS' \
    DEVELOPMENT_TEAM="N4Q66J8W25" \
    CODE_SIGN_IDENTITY="Apple Distribution" \
    | xcpretty

echo -e "${GREEN}✓ Archive created successfully${NC}\n"

# Step 7: Validate archive
echo -e "${YELLOW}[7/7]${NC} Validating archive..."

if [ -d "$ARCHIVE_PATH" ]; then
    echo -e "${GREEN}✓ Archive exists at: ${ARCHIVE_PATH}${NC}"
    
    # Show archive info
    INFO_PLIST="${ARCHIVE_PATH}/Info.plist"
    if [ -f "$INFO_PLIST" ]; then
        ARCHIVE_DATE=$(/usr/libexec/PlistBuddy -c "Print :CreationDate" "$INFO_PLIST" 2>/dev/null || echo "Unknown")
        echo -e "  Created: ${ARCHIVE_DATE}"
    fi
else
    echo -e "${RED}✗ Archive not found!${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            Archive Complete! 🎉                ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo -e "  1. Open Xcode → Window → Organizer (Cmd+Option+Shift+O)"
echo -e "  2. Select your archive (${VERSION} - ${BUILD})"
echo -e "  3. Click 'Distribute App'"
echo -e "  4. Select 'App Store Connect'"
echo -e "  5. Click 'Upload'"
echo -e "  6. Follow the wizard to upload to TestFlight"
echo ""
echo -e "${YELLOW}Or run this command to open Organizer:${NC}"
echo -e "  open -a /Applications/Xcode.app $ARCHIVE_PATH"
echo ""
echo -e "${BLUE}Archive location:${NC} ${ARCHIVE_PATH}"
echo ""
