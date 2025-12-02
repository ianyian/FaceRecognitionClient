# iOS Face Recognition - Encoding Compatibility Issue & Fix Guide

## Issue Summary

The iOS FaceRecognitionClient app shows **super low similarity scores** (near 0%) when comparing captured faces against student encodings stored in Firestore, even when the same person's face should match with high confidence.

**Root Cause**: The web application (CoMa) uses **MediaPipe Face Mesh** to generate face encodings, while the iOS app uses **Apple Vision Framework**. These two systems produce incompatible landmark data.

---

## Technical Analysis

### 1. Web App (CoMa) Encoding Format

The web app stores face encodings using **MediaPipe Face Mesh** with the following characteristics:

```json
{
  "landmarks": [
    {
      "type": "LEFT_EYE",
      "x": 258.72486114501953,
      "y": 241.96380615234375,
      "z": 7.966098189353943
    },
    {
      "type": "RIGHT_EYE",
      "x": 312.5,
      "y": 240.8,
      "z": 6.2
    }
    // ... more landmarks
  ],
  "confidence": 1.0
}
```

**Key characteristics:**

- **Coordinate System**: Pixel-based coordinates (typically 0-512 range)
- **Landmark Count**: 468 face mesh landmarks
- **Z-axis**: Depth estimation in pixel units
- **Landmark Types**: Named types like `LEFT_EYE`, `RIGHT_EYE`, `NOSE_TIP`, etc.

### 2. iOS Vision Framework Encoding Format

Apple's Vision framework produces landmarks with:

- **Coordinate System**: Normalized coordinates (0.0 to 1.0 range)
- **Landmark Count**: 76 face landmarks (VNFaceLandmarks2D)
- **Z-axis**: Not available (2D landmarks only)
- **Landmark Types**: Region-based (leftEye, rightEye, nose, etc.)

### 3. The Mismatch Problem

| Aspect         | Web (MediaPipe) | iOS (Vision)      |
| -------------- | --------------- | ----------------- |
| X coordinate   | 258.72 (pixels) | 0.45 (normalized) |
| Y coordinate   | 241.96 (pixels) | 0.52 (normalized) |
| Z coordinate   | 7.96 (depth)    | N/A               |
| Landmark count | 468             | 76                |

When comparing these incompatible formats:

- Distance calculation produces enormous values
- Similarity formula returns near-zero results

---

## Recommended Solutions

### Solution A: Integrate MediaPipe on iOS (Recommended)

Use Google's MediaPipe SDK for iOS to produce compatible encodings.

#### Step 1: Add MediaPipe Dependency

In `Package.swift` or via CocoaPods:

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/google/mediapipe.git", from: "0.10.0")
]
```

Or CocoaPods:

```ruby
pod 'MediaPipeTasksVision', '~> 0.10.0'
```

#### Step 2: Download MediaPipe Model

Download `face_landmarker.task` from MediaPipe and add to app bundle:

- URL: https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task

#### Step 3: Create MediaPipe Face Encoder Service

```swift
import MediaPipeTasksVision
import UIKit

class MediaPipeFaceEncodingService {
    private var faceLandmarker: FaceLandmarker?

    // Landmark type mapping to match web app format
    private let landmarkTypeMap: [Int: String] = [
        33: "LEFT_EYE_INNER",
        133: "LEFT_EYE_OUTER",
        362: "RIGHT_EYE_INNER",
        263: "RIGHT_EYE_OUTER",
        1: "NOSE_TIP",
        61: "MOUTH_LEFT",
        291: "MOUTH_RIGHT",
        199: "CHIN",
        // Add more mappings as needed based on web app requirements
    ]

    init() throws {
        guard let modelPath = Bundle.main.path(forResource: "face_landmarker", ofType: "task") else {
            throw FaceEncodingError.modelNotFound
        }

        let options = FaceLandmarkerOptions()
        options.baseOptions.modelAssetPath = modelPath
        options.runningMode = .image
        options.numFaces = 1
        options.minFaceDetectionConfidence = 0.5
        options.minFacePresenceConfidence = 0.5
        options.minTrackingConfidence = 0.5
        options.outputFaceBlendshapes = false
        options.outputFacialTransformationMatrixes = false

        faceLandmarker = try FaceLandmarker(options: options)
    }

    func encodeFace(from image: UIImage) throws -> FaceEncoding {
        guard let cgImage = image.cgImage else {
            throw FaceEncodingError.invalidImage
        }

        let mpImage = try MPImage(cgImage: cgImage)
        let result = try faceLandmarker?.detect(image: mpImage)

        guard let landmarks = result?.faceLandmarks.first else {
            throw FaceEncodingError.noFaceDetected
        }

        // Convert to web-compatible format
        var encodedLandmarks: [[String: Any]] = []

        for (index, landmark) in landmarks.enumerated() {
            // MediaPipe returns normalized coords, scale to pixel space (512x512)
            let scaleFactor: Float = 512.0

            let landmarkData: [String: Any] = [
                "type": landmarkTypeMap[index] ?? "LANDMARK_\(index)",
                "x": landmark.x * scaleFactor,
                "y": landmark.y * scaleFactor,
                "z": landmark.z * scaleFactor
            ]
            encodedLandmarks.append(landmarkData)
        }

        return FaceEncoding(
            landmarks: encodedLandmarks,
            confidence: 1.0
        )
    }
}

enum FaceEncodingError: Error {
    case modelNotFound
    case invalidImage
    case noFaceDetected
}
```

#### Step 4: Update FaceRecognitionService

Replace the current Vision-based encoding with MediaPipe:

```swift
// In FaceRecognitionService.swift

class FaceRecognitionService {
    private let mediaEncoder: MediaPipeFaceEncodingService

    init() throws {
        self.mediaEncoder = try MediaPipeFaceEncodingService()
    }

    func processFrame(_ image: UIImage) async throws -> [FaceMatch] {
        // Use MediaPipe for encoding
        let encoding = try mediaEncoder.encodeFace(from: image)

        // Compare with cached face data
        return compareFaceEncoding(encoding)
    }
}
```

---

### Solution B: Coordinate Normalization (Fallback Option)

If integrating MediaPipe is not feasible, normalize coordinates during comparison.

**⚠️ Warning**: This approach has limitations due to different landmark counts and types.

```swift
// In FaceRecognitionService.swift

struct NormalizedLandmark {
    let type: String
    let x: Double
    let y: Double
    let z: Double
}

func normalizeMediaPipeLandmark(_ landmark: [String: Any], targetScale: Double = 1.0) -> NormalizedLandmark? {
    guard let type = landmark["type"] as? String,
          let x = landmark["x"] as? Double,
          let y = landmark["y"] as? Double,
          let z = landmark["z"] as? Double else {
        return nil
    }

    // MediaPipe uses ~512 pixel scale, normalize to 0-1
    let sourceScale: Double = 512.0

    return NormalizedLandmark(
        type: type,
        x: (x / sourceScale) * targetScale,
        y: (y / sourceScale) * targetScale,
        z: (z / sourceScale) * targetScale
    )
}

func normalizeVisionLandmark(point: CGPoint, imageSize: CGSize, targetScale: Double = 512.0) -> (x: Double, y: Double) {
    // Vision uses 0-1 normalized, scale to MediaPipe pixel coords
    return (
        x: Double(point.x) * targetScale,
        y: Double(point.y) * targetScale
    )
}
```

---

### Solution C: Server-Side Comparison (Alternative)

Send the captured image to a backend service that uses MediaPipe for both encoding and comparison.

```swift
// POST captured image to server for comparison
func matchFaceOnServer(image: UIImage) async throws -> [FaceMatch] {
    guard let imageData = image.jpegData(compressionQuality: 0.8) else {
        throw FaceMatchError.invalidImage
    }

    let base64Image = imageData.base64EncodedString()

    var request = URLRequest(url: URL(string: "\(serverURL)/api/match-face")!)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body: [String: Any] = [
        "image": "data:image/jpeg;base64,\(base64Image)",
        "schoolId": currentSchoolId
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode([FaceMatch].self, from: data)
}
```

---

## Similarity Calculation Reference

Ensure the iOS app uses the same similarity formula as the web app:

```swift
func calculateSimilarity(_ encoding1: FaceEncoding, _ encoding2: FaceEncoding) -> Double {
    var totalDistance: Double = 0
    var matchingCount = 0

    for lm1 in encoding1.landmarks {
        guard let type = lm1["type"] as? String,
              let x1 = lm1["x"] as? Double,
              let y1 = lm1["y"] as? Double,
              let z1 = lm1["z"] as? Double else {
            continue
        }

        // Find matching landmark by type
        if let lm2 = encoding2.landmarks.first(where: { ($0["type"] as? String) == type }),
           let x2 = lm2["x"] as? Double,
           let y2 = lm2["y"] as? Double,
           let z2 = lm2["z"] as? Double {

            let distance = sqrt(
                pow(x1 - x2, 2) +
                pow(y1 - y2, 2) +
                pow(z1 - z2, 2)
            )

            totalDistance += distance
            matchingCount += 1
        }
    }

    guard matchingCount > 0 else { return 0 }

    let averageDistance = totalDistance / Double(matchingCount)

    // IMPORTANT: Match web app's normalization factor (100)
    let similarity = max(0, 1 - averageDistance / 100)

    return similarity
}
```

---

## Testing & Validation

### Debug Logging

Add logging to verify encoding format compatibility:

```swift
func debugPrintEncoding(_ encoding: FaceEncoding, label: String) {
    print("=== \(label) ===")
    print("Landmark count: \(encoding.landmarks.count)")

    if let firstLandmark = encoding.landmarks.first {
        print("Sample landmark: \(firstLandmark)")
        if let x = firstLandmark["x"] as? Double {
            print("X range indication: \(x < 1.5 ? "Normalized (0-1)" : "Pixel-based")")
        }
    }
}

// Usage
debugPrintEncoding(capturedEncoding, label: "iOS Captured")
debugPrintEncoding(storedEncoding, label: "Firestore Stored")
```

### Expected Output After Fix

```
=== iOS Captured ===
Landmark count: 468
Sample landmark: ["type": "LEFT_EYE", "x": 258.5, "y": 241.9, "z": 8.1]
X range indication: Pixel-based

=== Firestore Stored ===
Landmark count: 468
Sample landmark: ["type": "LEFT_EYE", "x": 258.7, "y": 241.9, "z": 7.9]
X range indication: Pixel-based

Similarity: 0.92 ✅
```

---

## Implementation Checklist

- [ ] Add MediaPipe SDK to project dependencies
- [ ] Download and bundle `face_landmarker.task` model file
- [ ] Implement `MediaPipeFaceEncodingService`
- [ ] Update `FaceRecognitionService` to use MediaPipe encoder
- [ ] Update similarity calculation to match web app formula
- [ ] Add debug logging for verification
- [ ] Test with enrolled student faces
- [ ] Verify similarity scores > 0.70 for same person

---

## Resources

- [MediaPipe Face Landmarker Guide](https://developers.google.com/mediapipe/solutions/vision/face_landmarker)
- [MediaPipe iOS Setup](https://developers.google.com/mediapipe/solutions/setup_ios)
- [Face Landmark Model Download](https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task)

---

## Questions?

Contact the CoMa development team for clarification on:

- Specific landmark type mappings
- Similarity threshold requirements
- Backend API integration options
