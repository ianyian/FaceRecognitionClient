# MediaPipe iOS Integration Setup Guide

## Overview

This document explains how to complete the MediaPipe Face Landmarker integration for the iOS app. This integration ensures the iOS app uses the **exact same face detection** as the CoMa web app, resulting in consistent landmark positions and significantly improved face matching accuracy.

## Changes Made

### New Files

- `FaceRecognitionClient/Services/MediaPipeFaceLandmarkerService.swift` - MediaPipe Face Landmarker wrapper
- `Podfile` - CocoaPods configuration with MediaPipeTasksVision

### Modified Files

- `FaceRecognitionClient/Services/FaceRecognitionService.swift` - Updated to use MediaPipe instead of Vision framework

### Key Improvements

- **Same detection model**: Uses MediaPipe Face Landmarker (same as CoMa web app)
- **Consistent landmarks**: 33 key landmarks from 478-point face mesh
- **Matching parameters**: 65% threshold, 15 min landmarks, 2.5 decay constant (same as CoMa)

## Setup Steps

### Step 1: Install CocoaPods (if not already installed)

```bash
sudo gem install cocoapods
```

Or using Homebrew:

```bash
brew install cocoapods
```

### Step 2: Install Pod Dependencies

Navigate to the project directory and run:

```bash
cd /Users/xj/git/schoolAttenance-Client/FaceRecognitionClient
pod install
```

This will:

- Download MediaPipeTasksVision framework
- Create `FaceRecognitionClient.xcworkspace`
- Link the framework to your project

### Step 3: Download the Face Landmarker Model

Download the model file from Google's MediaPipe repository:

```bash
# Create Resources folder if needed
mkdir -p FaceRecognitionClient/Resources

# Download the face_landmarker.task model
curl -L "https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task" -o FaceRecognitionClient/Resources/face_landmarker.task
```

Or download manually from:
https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task

### Step 4: Add Model to Xcode Project

1. Open `FaceRecognitionClient.xcworkspace` (NOT .xcodeproj!)
2. Right-click on the FaceRecognitionClient folder in Xcode
3. Select "Add Files to FaceRecognitionClient..."
4. Navigate to and select `face_landmarker.task`
5. Ensure "Copy items if needed" is checked
6. Ensure "Add to targets: FaceRecognitionClient" is checked
7. Click Add

### Step 5: Verify Bundle Resource

1. Select the project in Xcode Navigator
2. Select the FaceRecognitionClient target
3. Go to "Build Phases" tab
4. Expand "Copy Bundle Resources"
5. Verify `face_landmarker.task` is listed
6. If not, click "+" and add it

### Step 6: Build and Run

1. Select your device or simulator (iOS 15.0+)
2. Press Cmd+B to build
3. Press Cmd+R to run

## Verification

After setup, you should see these logs when detecting a face:

```
🔧 Initializing MediaPipe Face Landmarker...
✅ MediaPipe Face Landmarker initialized successfully
📸 MediaPipe detected 478 landmarks in [width]x[height] image
✅ Extracted 33 key landmarks
📸 Camera encoding (MediaPipe): 33 landmarks
```

## Troubleshooting

### Error: "MediaPipe face_landmarker.task model not found in bundle"

- Verify `face_landmarker.task` is in Copy Bundle Resources
- Clean build folder (Cmd+Shift+K) and rebuild

### Error: "No such module 'MediaPipeTasksVision'"

- Make sure you opened `.xcworkspace`, not `.xcodeproj`
- Run `pod install` again
- Restart Xcode

### Build Error: "Undefined symbols for architecture"

- Clean derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
- Run `pod deintegrate` then `pod install`

### Face Detection Not Working

- Check camera permissions in Info.plist
- Ensure good lighting and clear face visibility
- Verify model file is correctly bundled (~5MB file)

## Technical Details

### Landmark Mapping (iOS → CoMa)

| MediaPipe Index | iOS Name         | CoMa Name     |
| --------------- | ---------------- | ------------- |
| 468             | LEFT_EYE_CENTER  | LEFT_EYE      |
| 473             | RIGHT_EYE_CENTER | RIGHT_EYE     |
| 1               | NOSE_TIP         | NOSE_TIP      |
| 61              | MOUTH_LEFT       | MOUTH_LEFT    |
| 291             | MOUTH_RIGHT      | MOUTH_RIGHT   |
| 152             | CHIN             | CHIN_GNATHION |
| ...             | ...              | ...           |

### Matching Algorithm

1. **Geometric Normalization**: Center landmarks and scale by inter-ocular distance
2. **Weighted Distance**: Different landmarks have different weights (eyes/nose: 2.5, mouth: 1.8, etc.)
3. **Exponential Decay**: `similarity = exp(-distance * 2.5)`
4. **Threshold**: Match accepted if similarity ≥ 65% with ≥ 15 landmarks

## File Size Considerations

- `face_landmarker.task`: ~5MB
- MediaPipeTasksVision framework: ~15MB
- Total app size increase: ~20MB

This is acceptable for modern iOS devices with ample storage.
