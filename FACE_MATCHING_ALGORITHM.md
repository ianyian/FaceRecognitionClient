# Face Matching Algorithm - 478 Landmark Mode

This document describes the improved face matching algorithm using MediaPipe's 478 facial landmarks.

## Overview

The algorithm uses a **hybrid approach** combining:

1. **Landmark position matching** (70% weight) - normalized 3D coordinates
2. **Facial ratio matching** (30% weight) - pose-invariant proportions
3. **Multi-sample voting** - leverages multiple stored photos per person

This multi-layered approach provides accuracy while being robust to head pose variations.

## Normalization Process

### 1. Center Point: Nose Tip (Landmark Index 1)

Instead of using bounding box center, we use the **nose tip** as the center point. This is more stable because:

- The nose tip is a consistent anatomical landmark
- Less affected by facial expressions
- Provides better alignment for face comparison

```javascript
// Use nose tip as center
const noseTip = landmarks[1];
const centerX = noseTip.x;
const centerY = noseTip.y;
const centerZ = noseTip.z;
```

### 2. Scale Reference: Inter-Ocular Distance

We use the distance between the outer eye corners (landmarks 33 and 263) as the scale reference:

```javascript
const leftEyeOuter = landmarks[33]; // Left eye outer corner
const rightEyeOuter = landmarks[263]; // Right eye outer corner
const scale = Math.sqrt(
  Math.pow(rightEyeOuter.x - leftEyeOuter.x, 2) +
    Math.pow(rightEyeOuter.y - leftEyeOuter.y, 2)
);
```

### 3. Rotation Alignment: Eye Line Horizontal

We rotate the face so the eye line is horizontal. This compensates for head tilt:

```javascript
// Calculate rotation angle from eye line
const eyeAngle = Math.atan2(
  rightEyeOuter.y - leftEyeOuter.y,
  rightEyeOuter.x - leftEyeOuter.x
);

// Apply inverse rotation to each landmark
const cosAngle = Math.cos(-eyeAngle);
const sinAngle = Math.sin(-eyeAngle);

// For each landmark:
const dx = lm.x - centerX;
const dy = lm.y - centerY;
const rotatedX = dx * cosAngle - dy * sinAngle;
const rotatedY = dx * sinAngle + dy * cosAngle;

// Final normalized coordinates
normalizedX = rotatedX / scale;
normalizedY = rotatedY / scale;
normalizedZ = (lm.z - centerZ) / scale;
```

## Landmark Weighting

Different facial landmarks have different importance for identity recognition. We use a 3-tier weighting system:

### Critical Landmarks (Weight: 4.0)

Most distinctive for identity - eye corners, nose features, mouth corners, chin:

```javascript
const criticalIndices = [
  // Eye corners (very distinctive)
  33, 133, 263, 362,
  // Nose bridge and tip
  1, 2, 4, 5, 6,
  // Mouth corners
  61, 291,
  // Chin point
  152,
];
```

### High Weight Landmarks (Weight: 2.5)

Important facial features:

```javascript
const highWeightIndices = [
  // Eye contours
  159, 145, 386, 374, 160, 144, 387, 373,
  // Iris landmarks (468-477)
  468, 469, 470, 471, 472, 473, 474, 475, 476, 477,
  // Nose sides
  129, 358, 98, 327,
  // Mouth shape
  0, 13, 14, 17, 78, 308,
  // Jaw points
  172, 397, 136, 365,
];
```

### Medium Weight Landmarks (Weight: 1.5)

Secondary features:

```javascript
const mediumWeightIndices = [
  // Eyebrows
  70, 107, 300, 336, 66, 105, 296, 334,
  // Cheekbones
  116, 345, 123, 352,
  // Face contour
  10, 127, 234, 356, 454,
];
```

### All Other Landmarks (Weight: 1.0)

Standard weight for remaining mesh points.

## Distance Calculation

For each pair of corresponding landmarks, calculate the 3D Euclidean distance:

```javascript
const distance = Math.sqrt(
  Math.pow(lm1.x - lm2.x, 2) +
    Math.pow(lm1.y - lm2.y, 2) +
    Math.pow(lm1.z - lm2.z, 2)
);

// Apply weight
weightedDistance += distance * weight;
totalWeight += weight;
```

## Facial Ratio Matching (Pose-Invariant)

To handle head pose variations, we also calculate **facial proportions** that remain consistent regardless of head angle:

### 10 Key Facial Ratios (all normalized by inter-ocular distance)

| Ratio | Landmarks | Description                 |
| ----- | --------- | --------------------------- |
| 1     | 6 → 1     | Nose length (bridge to tip) |
| 2     | 129 → 358 | Nose width                  |
| 3     | 61 → 291  | Mouth width                 |
| 4     | 33 → 61   | Eye to mouth (vertical)     |
| 5     | 33 → 152  | Eye to chin                 |
| 6     | 33 → 1    | Eye to nose tip             |
| 7     | 10 → 1    | Forehead to nose            |
| 8     | 33 → 133  | Left eye width              |
| 9     | 263 → 362 | Right eye width             |
| 10    | 172 → 397 | Jaw width                   |

```javascript
function calculateFacialRatioSimilarity(landmarks1, landmarks2) {
  const iod1 = dist(landmarks1, 33, 263); // Inter-ocular distance
  const iod2 = dist(landmarks2, 33, 263);

  // Calculate each ratio normalized by IOD
  const ratios1 = [
    dist(landmarks1, 6, 1) / iod1, // Nose length
    dist(landmarks1, 129, 358) / iod1, // Nose width
    dist(landmarks1, 61, 291) / iod1, // Mouth width
    // ... etc
  ];

  // Compare ratios
  let totalDiff = 0;
  for (let i = 0; i < ratios1.length; i++) {
    totalDiff += Math.abs(ratios1[i] - ratios2[i]);
  }

  const avgDiff = totalDiff / ratios1.length;
  return Math.exp(-avgDiff * 8.0); // Decay factor 8.0
}
```

## Combined Similarity Score

The final score combines both approaches:

```javascript
// Landmark position similarity (normalized, weighted)
const landmarkSimilarity = Math.exp(-averageWeightedDistance * 4.0);

// Facial ratio similarity (pose-invariant)
const ratioSimilarity = calculateFacialRatioSimilarity(landmarks1, landmarks2);

// Combined: 70% landmark + 30% ratio
const finalSimilarity = landmarkSimilarity * 0.7 + ratioSimilarity * 0.3;
```

### Why This Combination?

| Approach           | Pros           | Cons                   |
| ------------------ | -------------- | ---------------------- |
| Landmark positions | High precision | Sensitive to head pose |
| Facial ratios      | Pose-invariant | Lower precision        |
| **Combined**       | Best of both   | Robust + accurate      |

## Parameter Summary

| Parameter                | Value | Purpose                  |
| ------------------------ | ----- | ------------------------ |
| Landmark decay factor    | 4.0   | Steeper similarity curve |
| Ratio decay factor       | 8.0   | Gentler curve for ratios |
| Landmark weight          | 70%   | Primary matching signal  |
| Ratio weight             | 30%   | Pose-invariance boost    |
| Critical landmark weight | 4.0x  | Eye corners, nose, mouth |
| High landmark weight     | 2.5x  | Eye contours, iris, jaw  |
| Medium landmark weight   | 1.5x  | Eyebrows, cheekbones     |

## Recommended Thresholds

Based on the hybrid algorithm:

| Threshold | Use Case                                      |
| --------- | --------------------------------------------- |
| 70%       | Standard matching - good balance              |
| 75%       | Higher security - fewer false positives       |
| 65%       | Lenient matching - good for varied conditions |

## Complete Normalization Function (JavaScript/TypeScript)

```javascript
function normalizeAllLandmarksImproved(landmarks) {
  if (landmarks.length <= 263) return landmarks;

  // 1. Use nose tip as center
  const noseTip = landmarks[1];
  const centerX = noseTip.x;
  const centerY = noseTip.y;
  const centerZ = noseTip.z;

  // 2. Calculate inter-ocular distance as scale
  const leftEye = landmarks[33];
  const rightEye = landmarks[263];
  let scale = Math.sqrt(
    Math.pow(rightEye.x - leftEye.x, 2) + Math.pow(rightEye.y - leftEye.y, 2)
  );

  // Fallback if eyes too close
  if (scale < 10) {
    const xs = landmarks.map((l) => l.x);
    scale = Math.max(...xs) - Math.min(...xs);
  }
  if (scale === 0) scale = 1;

  // 3. Calculate rotation angle to align eyes horizontally
  const eyeAngle = Math.atan2(rightEye.y - leftEye.y, rightEye.x - leftEye.x);
  const cosAngle = Math.cos(-eyeAngle);
  const sinAngle = Math.sin(-eyeAngle);

  // 4. Normalize each landmark
  return landmarks.map((lm) => {
    // Translate to nose-tip center
    const dx = lm.x - centerX;
    const dy = lm.y - centerY;
    const dz = lm.z - centerZ;

    // Rotate to align eyes horizontally
    const rotatedX = dx * cosAngle - dy * sinAngle;
    const rotatedY = dx * sinAngle + dy * cosAngle;

    // Scale by inter-ocular distance
    return {
      x: rotatedX / scale,
      y: rotatedY / scale,
      z: dz / scale,
    };
  });
}
```

## Complete Facial Ratio Function (JavaScript/TypeScript)

```javascript
function calculateFacialRatioSimilarity(landmarks1, landmarks2) {
  if (landmarks1.length < 400 || landmarks2.length < 400) return 0.5;

  function dist(lm, i1, i2) {
    const p1 = lm[i1],
      p2 = lm[i2];
    return Math.sqrt(
      Math.pow(p2.x - p1.x, 2) +
        Math.pow(p2.y - p1.y, 2) +
        Math.pow(p2.z - p1.z, 2)
    );
  }

  // Inter-ocular distance (baseline)
  const iod1 = dist(landmarks1, 33, 263);
  const iod2 = dist(landmarks2, 33, 263);
  if (iod1 === 0 || iod2 === 0) return 0.5;

  // Calculate 10 key facial ratios
  const ratios1 = [
    dist(landmarks1, 6, 1) / iod1, // Nose length
    dist(landmarks1, 129, 358) / iod1, // Nose width
    dist(landmarks1, 61, 291) / iod1, // Mouth width
    dist(landmarks1, 33, 61) / iod1, // Eye to mouth
    dist(landmarks1, 33, 152) / iod1, // Eye to chin
    dist(landmarks1, 33, 1) / iod1, // Eye to nose tip
    dist(landmarks1, 10, 1) / iod1, // Forehead to nose
    dist(landmarks1, 33, 133) / iod1, // Left eye width
    dist(landmarks1, 263, 362) / iod1, // Right eye width
    dist(landmarks1, 172, 397) / iod1, // Jaw width
  ];

  const ratios2 = [
    dist(landmarks2, 6, 1) / iod2,
    dist(landmarks2, 129, 358) / iod2,
    dist(landmarks2, 61, 291) / iod2,
    dist(landmarks2, 33, 61) / iod2,
    dist(landmarks2, 33, 152) / iod2,
    dist(landmarks2, 33, 1) / iod2,
    dist(landmarks2, 10, 1) / iod2,
    dist(landmarks2, 33, 133) / iod2,
    dist(landmarks2, 263, 362) / iod2,
    dist(landmarks2, 172, 397) / iod2,
  ];

  // Calculate average ratio difference
  let totalDiff = 0;
  for (let i = 0; i < ratios1.length; i++) {
    totalDiff += Math.abs(ratios1[i] - ratios2[i]);
  }
  const avgDiff = totalDiff / ratios1.length;

  // Convert to similarity with decay factor 8.0
  return Math.exp(-avgDiff * 8.0);
}
```

## Complete Similarity Function (JavaScript/TypeScript)

```javascript
function calculateAllLandmarksSimilarity(detected, stored) {
  const detectedAll = detected.allLandmarks;
  const storedAll = stored.allLandmarks;

  if (
    !detectedAll ||
    !storedAll ||
    detectedAll.length < 400 ||
    storedAll.length < 400
  ) {
    return null; // Fall back to 33-landmark mode
  }

  // Normalize both sets
  const normalized1 = normalizeAllLandmarksImproved(detectedAll);
  const normalized2 = normalizeAllLandmarksImproved(storedAll);

  const matchCount = Math.min(normalized1.length, normalized2.length);

  // Weight definitions
  const criticalIndices = new Set([
    33, 133, 263, 362, 1, 2, 4, 5, 6, 61, 291, 152,
  ]);
  const highWeightIndices = new Set([
    159, 145, 386, 374, 160, 144, 387, 373, 468, 469, 470, 471, 472, 473, 474,
    475, 476, 477, 129, 358, 98, 327, 0, 13, 14, 17, 78, 308, 172, 397, 136, 365,
  ]);
  const mediumWeightIndices = new Set([
    70, 107, 300, 336, 66, 105, 296, 334, 116, 345, 123, 352, 10, 127, 234, 356,
    454,
  ]);

  let weightedDistance = 0;
  let totalWeight = 0;

  for (let i = 0; i < matchCount; i++) {
    const lm1 = normalized1[i];
    const lm2 = normalized2[i];

    // 3D Euclidean distance
    const distance = Math.sqrt(
      Math.pow(lm1.x - lm2.x, 2) +
        Math.pow(lm1.y - lm2.y, 2) +
        Math.pow(lm1.z - lm2.z, 2)
    );

    // Apply weight
    let weight = 1.0;
    if (criticalIndices.has(i)) {
      weight = 4.0;
    } else if (highWeightIndices.has(i)) {
      weight = 2.5;
    } else if (mediumWeightIndices.has(i)) {
      weight = 1.5;
    }

    weightedDistance += distance * weight;
    totalWeight += weight;
  }

  const averageWeightedDistance = weightedDistance / totalWeight;

  // Landmark similarity with decay factor 4.0
  const landmarkSimilarity = Math.exp(-averageWeightedDistance * 4.0);

  // Facial ratio similarity (pose-invariant)
  const ratioSimilarity = calculateFacialRatioSimilarity(
    detectedAll,
    storedAll
  );

  // Combined: 70% landmark + 30% ratio
  return landmarkSimilarity * 0.7 + ratioSimilarity * 0.3;
}
```

## Key Differences from Previous Algorithm

| Aspect                  | v1.0 Algorithm      | v2.0 Hybrid Algorithm          |
| ----------------------- | ------------------- | ------------------------------ |
| Center point            | Bounding box center | Nose tip (landmark 1)          |
| Rotation                | None                | Eye-line aligned to horizontal |
| Critical weight         | 2.5x                | 4.0x                           |
| Decay factor            | 2.5                 | 4.0                            |
| **Ratio matching**      | None                | 30% weight (10 ratios)         |
| **Multi-sample voting** | None                | Yes (3-5 samples recommended)  |
| Pose sensitivity        | High                | Low                            |
| Score spread            | Narrow (61-81%)     | Wider (45-85%)                 |

## Multi-Sample Voting

### Why Capture 3-5 Photos?

The system is designed to capture **3-5 photos per person** during registration. This provides:

1. **Coverage of different angles** - slight head tilts, different expressions
2. **Voting confidence** - multiple samples agreeing = higher confidence
3. **Robustness** - one bad photo doesn't ruin matching

### How Voting Works

When matching a face against stored samples, we:

1. **Calculate similarity** for each stored sample of each person
2. **Group scores by student** - each student may have 3-5 samples
3. **Count votes** - samples with similarity ≥60% count as a "vote"
4. **Apply boost** based on vote count and score consistency

### Voting Algorithm

```javascript
function applyMultiSampleVoting(studentScores) {
  const VOTING_THRESHOLD = 0.6; // 60% to count as a vote

  for (const [studentId, scores] of Object.entries(studentScores)) {
    // Sort by similarity (highest first)
    scores.sort((a, b) => b.similarity - a.similarity);

    const bestScore = scores[0].similarity;
    const sampleCount = scores.length;

    // Count votes (samples above threshold)
    const votes = scores.filter((s) => s.similarity >= VOTING_THRESHOLD).length;

    // Calculate average of top 3 scores
    const topN = Math.min(3, sampleCount);
    const avgTop3 =
      scores.slice(0, topN).reduce((sum, s) => sum + s.similarity, 0) / topN;

    let finalScore = bestScore;
    let boost = 0;

    if (sampleCount >= 3) {
      if (votes >= 3) {
        // Strong agreement: 3+ samples above threshold
        boost = (avgTop3 - bestScore) * 0.3 + 0.02;
      } else if (votes >= 2) {
        // Moderate agreement: 2 samples above threshold
        boost = (avgTop3 - bestScore) * 0.15 + 0.01;
      }

      // Consistency bonus: if top 3 scores are within 5%
      const scoreRange =
        scores[0].similarity - scores[Math.min(2, sampleCount - 1)].similarity;
      if (scoreRange < 0.05) {
        boost += 0.01; // +1% consistency bonus
      }

      finalScore = Math.min(bestScore + boost, 0.98);
    }

    return { studentId, finalScore, votes, avgTop3 };
  }
}
```

### Voting Boost Table

| Votes (≥60%) | Sample Count | Boost Applied              |
| ------------ | ------------ | -------------------------- |
| 3+           | 3-5          | +2-4% (strong agreement)   |
| 2            | 3-5          | +1-2% (moderate agreement) |
| 1            | any          | No boost                   |
| 0            | any          | No boost                   |

**Consistency bonus**: +1% if top 3 scores are within 5% of each other

### Example: test70 with 5 Samples

From log output:

```
test70 samples: 83.3%, 82.7%, 82.0%, 80.7%, 77.6%
- Votes (≥60%): 5/5 ✓
- Avg top 3: 82.7%
- Score range (top 3): 1.3% (very consistent)
- Voting boost: +2.5%
- Consistency bonus: +1%
- Final score: 83.3% + 3.5% = 86.8%
```

### Benefits of Multi-Sample Voting

| Benefit                   | Description                                              |
| ------------------------- | -------------------------------------------------------- |
| **Higher confidence**     | Multiple agreeing samples = more reliable match          |
| **Fewer false positives** | Single high score from wrong person won't win            |
| **Pose tolerance**        | Different angles captured → at least one will match well |
| **Expression tolerance**  | Neutral + slight smile → covers common expressions       |

### Recommended Sample Count

| Samples | Quality             | Notes                                   |
| ------- | ------------------- | --------------------------------------- |
| 1-2     | Poor                | Not enough for voting, prone to errors  |
| **3**   | Good                | Minimum for voting, covers basic angles |
| **4-5** | Excellent           | Best accuracy, covers more variations   |
| 6+      | Diminishing returns | Storage overhead, minimal accuracy gain |

## Testing Recommendations

1. **Same person, different photos**: Should get 70%+ similarity
2. **Same person, head tilted**: Should still get 65%+ (ratio matching helps)
3. **Same person, 5 samples**: Should get 80%+ with voting boost
4. **Different people**: Should get <60% similarity
5. **Different distances**: Should be normalized by scale factor

---

_Last updated: December 4, 2025_
_Algorithm version: 2.1 - Hybrid approach with landmark + ratio matching + multi-sample voting_
