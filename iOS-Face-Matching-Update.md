# iOS Face Matching Algorithm Update

## Overview

This document describes the updated face matching algorithm implemented in the CoMa web application. The iOS Swift client should implement the same algorithm to ensure consistent matching results across platforms.

## Changes Summary

| Aspect                    | Before               | After                         |
| ------------------------- | -------------------- | ----------------------------- |
| **Threshold**             | 0.30 (30%)           | 0.65 (65%)                    |
| **Normalization**         | None (raw pixels)    | Geometric normalization       |
| **Distance → Similarity** | `1 - d/100` (linear) | `exp(-d * 2.5)` (exponential) |
| **Landmark Weighting**    | Equal weights        | Weighted by importance        |
| **Min Landmarks**         | Not enforced         | 15 required                   |

---

## Algorithm Details

### 1. Geometric Normalization

Before comparing landmarks, both face encodings are normalized to remove position and scale variance:

**Steps:**

1. Calculate face bounding box center (centerX, centerY, centerZ)
2. Find inter-ocular distance (between LEFT_EYE and RIGHT_EYE) as scale reference
3. Normalize each landmark: `(x - centerX) / scale`

**Why:** This makes the comparison invariant to:

- Distance from camera
- Position in frame
- Face size differences

### 2. Weighted Landmarks

Different facial landmarks contribute differently to identity:

```swift
let WEIGHTED_LANDMARKS: [String: Double] = [
    // Eyes - highly discriminative
    "LEFT_EYE": 2.5,
    "RIGHT_EYE": 2.5,
    "LEFT_EYE_LEFT_CORNER": 2.0,
    "LEFT_EYE_RIGHT_CORNER": 2.0,
    "RIGHT_EYE_LEFT_CORNER": 2.0,
    "RIGHT_EYE_RIGHT_CORNER": 2.0,
    "LEFT_EYE_TOP_BOUNDARY": 1.5,
    "LEFT_EYE_BOTTOM_BOUNDARY": 1.5,
    "RIGHT_EYE_TOP_BOUNDARY": 1.5,
    "RIGHT_EYE_BOTTOM_BOUNDARY": 1.5,

    // Nose - stable reference
    "NOSE_TIP": 2.5,
    "MIDPOINT_BETWEEN_EYES": 2.0,
    "NOSE_BOTTOM_CENTER": 1.8,
    "NOSE_BOTTOM_LEFT": 1.5,
    "NOSE_BOTTOM_RIGHT": 1.5,

    // Mouth - shape varies per person
    "MOUTH_LEFT": 1.8,
    "MOUTH_RIGHT": 1.8,
    "UPPER_LIP": 1.5,
    "LOWER_LIP": 1.5,
    "MOUTH_CENTER": 1.3,

    // Eyebrows
    "RIGHT_OF_LEFT_EYEBROW": 1.6,
    "LEFT_OF_LEFT_EYEBROW": 1.6,
    "LEFT_OF_RIGHT_EYEBROW": 1.6,
    "RIGHT_OF_RIGHT_EYEBROW": 1.6,

    // Face contour
    "CHIN_GNATHION": 2.0,
    "LEFT_CHEEK_CENTER": 1.5,
    "RIGHT_CHEEK_CENTER": 1.5,
    "CHIN_LEFT_GONION": 1.3,
    "CHIN_RIGHT_GONION": 1.3,
    "FOREHEAD_GLABELLA": 1.2,

    // Ears
    "LEFT_EAR_TRAGION": 1.0,
    "RIGHT_EAR_TRAGION": 1.0,
]
```

### 3. Similarity Calculation

**Formula:** `similarity = exp(-averageWeightedDistance * 2.5)`

This exponential decay function:

- Returns 1.0 for perfect match (distance = 0)
- Returns ~0.47 for distance = 0.3
- Returns ~0.29 for distance = 0.5
- Returns ~0.08 for distance = 1.0

### 4. Match Threshold

- **Threshold:** 0.65 (65%)
- **Minimum Landmarks:** 15

---

## Swift Implementation

### FaceLandmark Structure

```swift
struct FaceLandmark: Codable {
    let type: String
    let x: Double
    let y: Double
    let z: Double
}

struct FaceEncoding: Codable {
    let landmarks: [FaceLandmark]
    let confidence: Double
    let timestamp: String
    let encoderType: String
}
```

### Weighted Landmarks Dictionary

```swift
class FaceMatchingService {

    static let CONFIDENCE_THRESHOLD: Double = 0.65
    static let MIN_MATCHING_LANDMARKS: Int = 15

    static let WEIGHTED_LANDMARKS: [String: Double] = [
        // Eyes - highly discriminative
        "LEFT_EYE": 2.5,
        "RIGHT_EYE": 2.5,
        "LEFT_EYE_LEFT_CORNER": 2.0,
        "LEFT_EYE_RIGHT_CORNER": 2.0,
        "RIGHT_EYE_LEFT_CORNER": 2.0,
        "RIGHT_EYE_RIGHT_CORNER": 2.0,
        "LEFT_EYE_TOP_BOUNDARY": 1.5,
        "LEFT_EYE_BOTTOM_BOUNDARY": 1.5,
        "RIGHT_EYE_TOP_BOUNDARY": 1.5,
        "RIGHT_EYE_BOTTOM_BOUNDARY": 1.5,

        // Nose - stable reference
        "NOSE_TIP": 2.5,
        "MIDPOINT_BETWEEN_EYES": 2.0,
        "NOSE_BOTTOM_CENTER": 1.8,
        "NOSE_BOTTOM_LEFT": 1.5,
        "NOSE_BOTTOM_RIGHT": 1.5,

        // Mouth - shape varies per person
        "MOUTH_LEFT": 1.8,
        "MOUTH_RIGHT": 1.8,
        "UPPER_LIP": 1.5,
        "LOWER_LIP": 1.5,
        "MOUTH_CENTER": 1.3,

        // Eyebrows
        "RIGHT_OF_LEFT_EYEBROW": 1.6,
        "LEFT_OF_LEFT_EYEBROW": 1.6,
        "LEFT_OF_RIGHT_EYEBROW": 1.6,
        "RIGHT_OF_RIGHT_EYEBROW": 1.6,

        // Face contour
        "CHIN_GNATHION": 2.0,
        "LEFT_CHEEK_CENTER": 1.5,
        "RIGHT_CHEEK_CENTER": 1.5,
        "CHIN_LEFT_GONION": 1.3,
        "CHIN_RIGHT_GONION": 1.3,
        "FOREHEAD_GLABELLA": 1.2,

        // Ears
        "LEFT_EAR_TRAGION": 1.0,
        "RIGHT_EAR_TRAGION": 1.0,
    ]
}
```

### Normalization Function

```swift
extension FaceMatchingService {

    /// Normalize landmarks to remove position/scale variance
    /// Uses inter-ocular distance as scale reference
    static func normalizeLandmarks(_ landmarks: [FaceLandmark]) -> [FaceLandmark] {
        guard !landmarks.isEmpty else { return landmarks }

        // Find bounding box
        var minX = Double.infinity, maxX = -Double.infinity
        var minY = Double.infinity, maxY = -Double.infinity
        var minZ = Double.infinity, maxZ = -Double.infinity

        for lm in landmarks {
            minX = min(minX, lm.x)
            maxX = max(maxX, lm.x)
            minY = min(minY, lm.y)
            maxY = max(maxY, lm.y)
            minZ = min(minZ, lm.z)
            maxZ = max(maxZ, lm.z)
        }

        // Calculate center
        let centerX = (minX + maxX) / 2
        let centerY = (minY + maxY) / 2
        let centerZ = (minZ + maxZ) / 2

        // Use inter-ocular distance as scale reference
        let leftEye = landmarks.first {
            $0.type == "LEFT_EYE" || $0.type == "LEFT_EYE_LEFT_CORNER"
        }
        let rightEye = landmarks.first {
            $0.type == "RIGHT_EYE" || $0.type == "RIGHT_EYE_RIGHT_CORNER"
        }

        var scale: Double
        if let le = leftEye, let re = rightEye {
            scale = sqrt(pow(re.x - le.x, 2) + pow(re.y - le.y, 2))
            // Prevent division by very small numbers
            if scale < 10 {
                scale = max(maxX - minX, maxY - minY)
            }
        } else {
            scale = max(maxX - minX, maxY - minY)
        }

        if scale == 0 { scale = 1 }

        // Normalize each landmark
        return landmarks.map { lm in
            FaceLandmark(
                type: lm.type,
                x: (lm.x - centerX) / scale,
                y: (lm.y - centerY) / scale,
                z: (lm.z - centerZ) / scale
            )
        }
    }
}
```

### Similarity Calculation Function

```swift
extension FaceMatchingService {

    struct SimilarityResult {
        let similarity: Double
        let matchedCount: Int
        let qualityScore: Double
    }

    /// Calculate weighted similarity between two face encodings
    static func calculateLandmarkSimilarity(
        _ landmarks1: [FaceLandmark],
        _ landmarks2: [FaceLandmark]
    ) -> SimilarityResult {
        guard !landmarks1.isEmpty, !landmarks2.isEmpty else {
            return SimilarityResult(similarity: 0, matchedCount: 0, qualityScore: 0)
        }

        // Normalize both sets of landmarks
        let normalized1 = normalizeLandmarks(landmarks1)
        let normalized2 = normalizeLandmarks(landmarks2)

        // Create lookup dictionary for O(1) access
        var landmarkMap2: [String: FaceLandmark] = [:]
        for lm in normalized2 {
            landmarkMap2[lm.type] = lm
        }

        var weightedDistanceSum: Double = 0
        var totalWeight: Double = 0
        var matchingLandmarks = 0

        // Match landmarks by type with weights
        for lm1 in normalized1 {
            if let lm2 = landmarkMap2[lm1.type] {
                // Get weight for this landmark type
                let weight = WEIGHTED_LANDMARKS[lm1.type] ?? 1.0

                // Calculate 3D Euclidean distance
                let distance = sqrt(
                    pow(lm1.x - lm2.x, 2) +
                    pow(lm1.y - lm2.y, 2) +
                    pow(lm1.z - lm2.z, 2)
                )

                weightedDistanceSum += distance * weight
                totalWeight += weight
                matchingLandmarks += 1
            }
        }

        guard matchingLandmarks > 0, totalWeight > 0 else {
            return SimilarityResult(similarity: 0, matchedCount: 0, qualityScore: 0)
        }

        // Calculate weighted average distance
        let averageWeightedDistance = weightedDistanceSum / totalWeight

        // Convert distance to similarity using exponential decay
        // exp(-d * 2.5) maps: d=0 → 1.0, d=0.3 → 0.47, d=0.5 → 0.29
        let similarity = exp(-averageWeightedDistance * 2.5)

        // Calculate quality score
        let qualityScore = calculateQualityScore(landmarks1)

        return SimilarityResult(
            similarity: similarity,
            matchedCount: matchingLandmarks,
            qualityScore: qualityScore
        )
    }
}
```

### Quality Score Function

```swift
extension FaceMatchingService {

    /// Calculate face quality score based on symmetry and coverage
    static func calculateQualityScore(_ landmarks: [FaceLandmark]) -> Double {
        guard landmarks.count >= 10 else { return 0 }

        // Check symmetry
        guard let noseTip = landmarks.first(where: { $0.type == "NOSE_TIP" }) else {
            return 0.5
        }

        let pairs: [(String, String)] = [
            ("LEFT_EYE", "RIGHT_EYE"),
            ("LEFT_EYE_LEFT_CORNER", "RIGHT_EYE_RIGHT_CORNER"),
            ("MOUTH_LEFT", "MOUTH_RIGHT"),
            ("LEFT_CHEEK_CENTER", "RIGHT_CHEEK_CENTER"),
        ]

        var symmetrySum: Double = 0
        var pairCount = 0

        for (leftType, rightType) in pairs {
            if let left = landmarks.first(where: { $0.type == leftType }),
               let right = landmarks.first(where: { $0.type == rightType }) {
                let leftDist = abs(left.x - noseTip.x)
                let rightDist = abs(right.x - noseTip.x)
                let maxDist = max(leftDist, rightDist, 1)
                let pairSymmetry = 1 - abs(leftDist - rightDist) / maxDist
                symmetrySum += pairSymmetry
                pairCount += 1
            }
        }

        let symmetryScore = pairCount > 0 ? symmetrySum / Double(pairCount) : 0.5
        let coverageScore = min(1, Double(landmarks.count) / 30.0)

        return symmetryScore * 0.6 + coverageScore * 0.4
    }
}
```

### Main Matching Function

```swift
extension FaceMatchingService {

    struct MatchResult {
        let isMatch: Bool
        let studentId: String?
        let studentName: String?
        let className: String?
        let confidence: Double
        let matchedLandmarks: Int
        let qualityScore: Double
    }

    /// Find best match from cached encodings
    static func findBestMatch(
        queryEncoding: FaceEncoding,
        storedEncodings: [(studentId: String, studentName: String, className: String, encoding: FaceEncoding)]
    ) -> MatchResult {
        var bestMatch: (studentId: String, studentName: String, className: String)?
        var highestConfidence: Double = 0
        var bestMatchedCount = 0
        var bestQualityScore: Double = 0

        for stored in storedEncodings {
            let result = calculateLandmarkSimilarity(
                queryEncoding.landmarks,
                stored.encoding.landmarks
            )

            // Must have minimum landmarks for valid comparison
            if result.matchedCount >= MIN_MATCHING_LANDMARKS &&
               result.similarity > highestConfidence {
                highestConfidence = result.similarity
                bestMatchedCount = result.matchedCount
                bestQualityScore = result.qualityScore

                if result.similarity >= CONFIDENCE_THRESHOLD {
                    bestMatch = (stored.studentId, stored.studentName, stored.className)
                }
            }
        }

        if let match = bestMatch, highestConfidence >= CONFIDENCE_THRESHOLD {
            return MatchResult(
                isMatch: true,
                studentId: match.studentId,
                studentName: match.studentName,
                className: match.className,
                confidence: highestConfidence,
                matchedLandmarks: bestMatchedCount,
                qualityScore: bestQualityScore
            )
        }

        return MatchResult(
            isMatch: false,
            studentId: nil,
            studentName: nil,
            className: nil,
            confidence: highestConfidence,
            matchedLandmarks: bestMatchedCount,
            qualityScore: bestQualityScore
        )
    }
}
```

---

## Testing Verification

After implementing these changes, verify with these test cases:

| Test Case                       | Expected Result     |
| ------------------------------- | ------------------- |
| Same person, same conditions    | Similarity > 85%    |
| Same person, different distance | Similarity > 75%    |
| Same person, slight head turn   | Similarity > 70%    |
| Different people                | Similarity < 60%    |
| Poor quality capture            | Quality score < 0.5 |

---

## Debugging Tips

Add logging to verify the algorithm is working correctly:

```swift
func debugMatch(query: FaceEncoding, stored: FaceEncoding) {
    print("=== Query Landmarks ===")
    print("Count: \(query.landmarks.count)")
    if let first = query.landmarks.first {
        print("Sample: \(first)")
        print("Range: \(first.x < 2 ? "Normalized" : "Pixel-based")")
    }

    print("\n=== Stored Landmarks ===")
    print("Count: \(stored.landmarks.count)")
    if let first = stored.landmarks.first {
        print("Sample: \(first)")
    }

    let result = FaceMatchingService.calculateLandmarkSimilarity(
        query.landmarks,
        stored.landmarks
    )

    print("\n=== Match Result ===")
    print("Similarity: \(String(format: "%.1f", result.similarity * 100))%")
    print("Matched Landmarks: \(result.matchedCount)")
    print("Quality Score: \(String(format: "%.2f", result.qualityScore))")
    print("Is Match: \(result.similarity >= FaceMatchingService.CONFIDENCE_THRESHOLD)")
}
```

---

## Important Notes

1. **Encoding Format**: The iOS app must produce landmarks with the same `type` names as the web app (e.g., `LEFT_EYE`, `NOSE_TIP`, etc.)

2. **Coordinate Scale**: After normalization, coordinates should be in similar ranges. The normalization handles this.

3. **MediaPipe Model**: Both platforms should use MediaPipe Face Mesh for consistent landmark detection.

4. **Cache Sync**: Ensure the iOS app syncs encodings from Firestore when data changes.

---

## Questions?

Contact the CoMa web development team for:

- Landmark type name clarifications
- Threshold tuning based on testing
- Integration debugging support
