//
//  FaceRecognitionService.swift
//  FaceRecognitionClient
//
//  Created on November 28, 2025.
//  Updated on December 3, 2025 - Uses MediaPipe Face Landmarker (same as CoMa web app)
//

import Foundation
import UIKit

class FaceRecognitionService {
    static let shared = FaceRecognitionService()

    private let cacheService = FaceDataCacheService.shared
    private let settingsService = SettingsService.shared
    private let mediaPipeService = MediaPipeFaceLandmarkerService.shared

    private var studentEncodings: [String: String] = [:]  // studentId: encoding
    private var students: [Student] = []

    private init() {}

    // MARK: - Setup

    func loadStudentData(_ students: [Student]) {
        self.students = students
        self.studentEncodings.removeAll()

        for student in students {
            if let encoding = student.faceEncoding, !encoding.isEmpty {
                studentEncodings[student.id] = encoding
            }
        }

        print("✅ Loaded \(studentEncodings.count) student face encodings")
    }

    // MARK: - Face Detection using MediaPipe (same as CoMa web app)

    /// Detect face and extract landmarks from camera image using MediaPipe
    /// This uses the exact same detection model as CoMa web app for consistent matching
    func detectFaceLandmarks(in image: UIImage) async throws -> MediaPipeFaceEncoding {
        // Use MediaPipe Face Landmarker - same as CoMa web app
        return try mediaPipeService.detectFaceLandmarks(in: image)
    }

    // MARK: - Local Face Matching (MediaPipe Landmark-based)

    /// Match detected face landmarks against local cache
    /// Returns FaceMatchingResult with best match info (always includes best score for debugging)
    /// Uses 478-landmark matching when available for higher accuracy
    /// Implements multi-sample voting for improved accuracy when students have multiple face samples
    func matchFaceAgainstLocalCache(_ detectedEncoding: MediaPipeFaceEncoding) -> FaceMatchingResult
    {
        let faceDataList = cacheService.getFaceDataForMatching()

        guard !faceDataList.isEmpty else {
            print("⚠️ No face data in cache for matching")
            return FaceMatchingResult(
                match: nil, bestSimilarity: 0, bestCandidateName: nil, candidatesChecked: 0)
        }

        // Filter for MediaPipe format records
        let mediaPipeRecords = faceDataList.filter { $0.isMediaPipeFormat }

        if mediaPipeRecords.isEmpty {
            print("⚠️ No MediaPipe encodings in cache")
            return FaceMatchingResult(
                match: nil, bestSimilarity: 0, bestCandidateName: nil,
                candidatesChecked: faceDataList.count)
        }

        // Check if we have 478 landmarks for enhanced matching
        let hasAllLandmarks =
            detectedEncoding.allLandmarks != nil
            && (detectedEncoding.allLandmarks?.count ?? 0)
                >= FaceRecognitionService.MIN_ALL_LANDMARKS
        let landmarkMode = hasAllLandmarks ? "478-landmark" : "33-landmark"

        print(
            "🔍 Matching against \(mediaPipeRecords.count) faces using \(landmarkMode) mode with threshold \(String(format: "%.0f%%", FaceRecognitionService.CONFIDENCE_THRESHOLD * 100))"
        )

        // Debug: Show detected encoding info
        print(
            "📸 Camera encoding: \(detectedEncoding.landmarks.count) key landmarks, \(detectedEncoding.allLandmarks?.count ?? 0) total landmarks"
        )

        // Collect all scores per student for multi-sample voting
        var studentScores: [String: [(similarity: Double, faceData: FaceDataDocument)]] = [:]
        var isFirstRecord = true
        var hasShownFallbackWarning = false

        for faceData in mediaPipeRecords {
            guard let storedEncoding = faceData.parseMediaPipeEncoding() else {
                continue
            }

            // Debug: Show first stored encoding info
            if isFirstRecord {
                print(
                    "💾 Stored encoding: \(storedEncoding.landmarks.count) key landmarks, \(storedEncoding.allLandmarks?.count ?? 0) total landmarks"
                )
                isFirstRecord = false
            }

            // Try 478-landmark matching first (higher accuracy)
            var similarity: Double
            var matchType: String

            if let allLandmarkSimilarity = calculateAllLandmarksSimilarity(
                detectedEncoding, storedEncoding)
            {
                similarity = allLandmarkSimilarity
                matchType = "478"
            } else {
                // Fall back to 33-landmark matching
                // This happens when stored data doesn't have allLandmarks (need to re-capture in CoMa)
                if !hasShownFallbackWarning {
                    print("⚠️ Falling back to 33-landmark mode (stored data missing allLandmarks)")
                    hasShownFallbackWarning = true
                }
                similarity = calculateMediaPipeSimilarity(detectedEncoding, storedEncoding)
                matchType = "33"

                // Check minimum landmarks requirement for 33-landmark mode
                let matchedCount = countMatchingLandmarks(detectedEncoding, storedEncoding)
                if matchedCount < FaceRecognitionService.MIN_MATCHING_LANDMARKS {
                    print(
                        "   📊 \(faceData.studentName): \(String(format: "%.1f%%", similarity * 100)) (\(matchType) lm, \(matchedCount) matched - SKIP: below min)"
                    )
                    continue
                }
            }

            print(
                "   📊 \(faceData.studentName): \(String(format: "%.1f%%", similarity * 100)) (\(matchType) landmarks)"
            )

            // Collect scores by student ID for voting
            let studentKey = faceData.studentId
            if studentScores[studentKey] == nil {
                studentScores[studentKey] = []
            }
            studentScores[studentKey]?.append((similarity: similarity, faceData: faceData))
        }

        // Apply multi-sample voting
        let votingResult = applyMultiSampleVoting(studentScores)

        // Only return match if above threshold (using algorithm's fixed threshold)
        let effectiveThreshold = FaceRecognitionService.CONFIDENCE_THRESHOLD
        if let result = votingResult, result.finalScore >= effectiveThreshold {
            let match = LocalFaceMatchResult(
                studentId: result.faceData.studentId,
                studentName: result.faceData.studentName,
                className: result.faceData.className,
                parentId: result.faceData.parentId,
                similarity: result.finalScore,
                matchedSampleIndex: result.faceData.sampleIndex,
                matchTimestamp: Date()
            )
            print(
                "✅ Match found: \(match.studentName) with \(match.similarityPercentage) similarity (threshold: \(String(format: "%.0f%%", effectiveThreshold * 100)))"
            )
            return FaceMatchingResult(
                match: match, bestSimilarity: result.finalScore,
                bestCandidateName: result.faceData.studentName,
                candidatesChecked: mediaPipeRecords.count)
        } else {
            let bestScore = votingResult?.finalScore ?? 0
            let bestName = votingResult?.faceData.studentName
            print(
                "❌ No match above threshold. Best: \(String(format: "%.1f%%", bestScore * 100)) (\(bestName ?? "none"))"
            )
            return FaceMatchingResult(
                match: nil, bestSimilarity: bestScore, bestCandidateName: bestName,
                candidatesChecked: mediaPipeRecords.count)
        }
    }

    // MARK: - Multi-Sample Voting

    /// Apply multi-sample voting to improve matching accuracy
    /// When a student has multiple face samples, we use voting to boost confidence:
    /// - Multiple high scores from same student = higher confidence
    /// - Consistent scores across samples = more reliable match
    private func applyMultiSampleVoting(
        _ studentScores: [String: [(similarity: Double, faceData: FaceDataDocument)]]
    ) -> (finalScore: Double, faceData: FaceDataDocument, voteCount: Int, avgScore: Double)? {

        var bestResult:
            (finalScore: Double, faceData: FaceDataDocument, voteCount: Int, avgScore: Double)?

        for (_, scores) in studentScores {
            guard !scores.isEmpty else { continue }

            // Sort scores descending
            let sortedScores = scores.sorted { $0.similarity > $1.similarity }

            // Get best individual score
            let bestScore = sortedScores[0].similarity
            let bestFaceData = sortedScores[0].faceData

            // Calculate voting metrics
            let sampleCount = sortedScores.count
            let votingThreshold = FaceRecognitionService.VOTING_THRESHOLD

            // Count how many samples are above voting threshold
            let votesAboveThreshold = sortedScores.filter { $0.similarity >= votingThreshold }.count

            // Calculate average of top scores (use top 3 or all if fewer)
            let topN = min(3, sampleCount)
            let topScores = sortedScores.prefix(topN).map { $0.similarity }
            let avgTopScore = topScores.reduce(0, +) / Double(topN)

            // Calculate final score with voting boost
            var finalScore = bestScore
            var votingBoost: Double = 0

            if sampleCount >= 3 {
                // Multi-sample voting logic
                if votesAboveThreshold >= 3 {
                    // Strong agreement: 3+ samples above threshold
                    // Boost = avg of top 3 scores weighted
                    votingBoost = (avgTopScore - bestScore) * 0.3 + 0.02
                    finalScore = min(bestScore + votingBoost, 0.98)
                    print(
                        "🗳️ Voting [\(bestFaceData.studentName)]: \(sampleCount) samples, \(votesAboveThreshold) votes, boost: +\(String(format: "%.1f%%", votingBoost * 100))"
                    )
                } else if votesAboveThreshold >= 2 {
                    // Moderate agreement: 2 samples above threshold
                    votingBoost = (avgTopScore - bestScore) * 0.15 + 0.01
                    finalScore = min(bestScore + votingBoost, 0.98)
                    print(
                        "🗳️ Voting [\(bestFaceData.studentName)]: \(sampleCount) samples, \(votesAboveThreshold) votes, boost: +\(String(format: "%.1f%%", votingBoost * 100))"
                    )
                }

                // Consistency bonus: if scores are close together, add small bonus
                if sampleCount >= 3 {
                    let scoreRange =
                        sortedScores[0].similarity
                        - sortedScores[min(2, sampleCount - 1)].similarity
                    if scoreRange < 0.05 {
                        // Very consistent scores (within 5%)
                        let consistencyBonus = 0.01
                        finalScore = min(finalScore + consistencyBonus, 0.98)
                        print(
                            "   📊 Consistency bonus: +1% (range: \(String(format: "%.1f%%", scoreRange * 100)))"
                        )
                    }
                }
            }

            // Update best result if this student has higher final score
            if bestResult == nil || finalScore > bestResult!.finalScore {
                bestResult = (
                    finalScore: finalScore, faceData: bestFaceData, voteCount: votesAboveThreshold,
                    avgScore: avgTopScore
                )
            }
        }

        // Log final voting result
        if let result = bestResult {
            print(
                "🏆 Voting winner: \(result.faceData.studentName) - Final: \(String(format: "%.1f%%", result.finalScore * 100)), Votes: \(result.voteCount), AvgTop3: \(String(format: "%.1f%%", result.avgScore * 100))"
            )
        }

        return bestResult
    }

    // MARK: - Face Matching Constants (Aligned with CoMa web app)

    /// Confidence threshold for match acceptance (same as CoMa)
    private static let CONFIDENCE_THRESHOLD: Double = 0.65

    /// Threshold for counting a sample as a "vote" in multi-sample voting
    private static let VOTING_THRESHOLD: Double = 0.60

    /// Minimum number of matching landmarks required for 33-landmark matching
    private static let MIN_MATCHING_LANDMARKS: Int = 15

    /// Minimum number of landmarks required for 478-landmark matching (more strict)
    private static let MIN_ALL_LANDMARKS: Int = 400

    /// Weighted landmarks - different facial landmarks contribute differently to identity
    private static let WEIGHTED_LANDMARKS: [String: Double] = [
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
        "LEFT_EYEBROW_UPPER_MIDPOINT": 1.4,
        "RIGHT_EYEBROW_UPPER_MIDPOINT": 1.4,

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

    /// Normalize landmarks to remove position/scale variance
    /// Uses inter-ocular distance as scale reference
    private func normalizeLandmarks(_ landmarks: [MediaPipeLandmark]) -> [MediaPipeLandmark] {
        guard !landmarks.isEmpty else { return landmarks }

        // Find bounding box
        var minX = Double.infinity
        var maxX = -Double.infinity
        var minY = Double.infinity
        var maxY = -Double.infinity
        var minZ = Double.infinity
        var maxZ = -Double.infinity

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
            MediaPipeLandmark(
                type: lm.type,
                x: (lm.x - centerX) / scale,
                y: (lm.y - centerY) / scale,
                z: (lm.z - centerZ) / scale
            )
        }
    }

    /// Calculate weighted similarity between two face encodings
    /// Uses geometric normalization and exponential decay formula
    private func calculateMediaPipeSimilarity(
        _ encoding1: MediaPipeFaceEncoding, _ encoding2: MediaPipeFaceEncoding
    ) -> Double {
        guard !encoding1.landmarks.isEmpty, !encoding2.landmarks.isEmpty else {
            return 0
        }

        // Normalize both sets of landmarks
        let normalized1 = normalizeLandmarks(encoding1.landmarks)
        let normalized2 = normalizeLandmarks(encoding2.landmarks)

        // Create lookup dictionary for O(1) access
        var landmarkMap2: [String: MediaPipeLandmark] = [:]
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
                let weight = FaceRecognitionService.WEIGHTED_LANDMARKS[lm1.type] ?? 1.0

                // Calculate 3D Euclidean distance
                let distance = sqrt(
                    pow(lm1.x - lm2.x, 2) + pow(lm1.y - lm2.y, 2) + pow(lm1.z - lm2.z, 2)
                )

                weightedDistanceSum += distance * weight
                totalWeight += weight
                matchingLandmarks += 1
            }
        }

        guard matchingLandmarks > 0, totalWeight > 0 else {
            return 0
        }

        // Calculate weighted average distance
        let averageWeightedDistance = weightedDistanceSum / totalWeight

        // Convert distance to similarity using exponential decay (same as CoMa web app)
        // exp(-d * 2.5) maps: d=0 → 1.0, d=0.2 → 0.61, d=0.4 → 0.37, d=0.6 → 0.22
        let similarity = exp(-averageWeightedDistance * 2.5)

        // Calculate quality score
        let qualityScore = calculateQualityScore(encoding1.landmarks)

        print(
            "📊 Similarity: \(String(format: "%.1f%%", similarity * 100)) | Matched: \(matchingLandmarks) landmarks | Quality: \(String(format: "%.2f", qualityScore)) | AvgDist: \(String(format: "%.3f", averageWeightedDistance))"
        )

        return similarity
    }

    /// Calculate face quality score based on symmetry and coverage
    private func calculateQualityScore(_ landmarks: [MediaPipeLandmark]) -> Double {
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
                let right = landmarks.first(where: { $0.type == rightType })
            {
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

    /// Calculate 2D distance between two landmarks
    private func distance(_ lm1: MediaPipeLandmark, _ lm2: MediaPipeLandmark) -> Double {
        return sqrt(pow(lm1.x - lm2.x, 2) + pow(lm1.y - lm2.y, 2))
    }

    /// Count matching landmarks between two encodings
    private func countMatchingLandmarks(
        _ encoding1: MediaPipeFaceEncoding, _ encoding2: MediaPipeFaceEncoding
    ) -> Int {
        let types2 = Set(encoding2.landmarks.map { $0.type })
        return encoding1.landmarks.filter { types2.contains($0.type) }.count
    }

    // MARK: - 478 Landmark Matching (All Landmarks - Same as CoMa)

    /// Calculate similarity using all 478 face mesh landmarks
    /// This provides much higher accuracy than the 33-landmark matching
    /// Uses geometric normalization with inter-ocular distance as scale reference
    /// Also incorporates facial ratio matching for pose-invariance
    private func calculateAllLandmarksSimilarity(
        _ detected: MediaPipeFaceEncoding, _ stored: MediaPipeFaceEncoding
    ) -> Double? {
        guard let detectedAll = detected.allLandmarks,
            let storedAll = stored.allLandmarks,
            detectedAll.count >= FaceRecognitionService.MIN_ALL_LANDMARKS,
            storedAll.count >= FaceRecognitionService.MIN_ALL_LANDMARKS
        else {
            return nil  // Fall back to 33-landmark matching
        }

        // Normalize both sets of landmarks using improved algorithm
        let normalized1 = normalizeAllLandmarksImproved(detectedAll)
        let normalized2 = normalizeAllLandmarksImproved(storedAll)

        // Match landmarks by index (MediaPipe provides consistent ordering)
        let matchCount = min(normalized1.count, normalized2.count)

        var totalDistance: Double = 0
        var weightedDistance: Double = 0
        var totalWeight: Double = 0

        // Key facial feature indices with high discriminative power
        // These landmarks are most stable and distinctive for face identification
        let criticalIndices: Set<Int> = [
            // Eye corners (very distinctive)
            33, 133, 263, 362,
            // Nose bridge and tip (unique per person)
            1, 2, 4, 5, 6,
            // Mouth corners (distinctive shape)
            61, 291,
            // Chin point
            152,
        ]

        let highWeightIndices: Set<Int> = [
            // Eye contours
            159, 145, 386, 374, 160, 144, 387, 373,
            // Iris landmarks (if available)
            468, 469, 470, 471, 472, 473, 474, 475, 476, 477,
            // Nose sides
            129, 358, 98, 327,
            // Mouth shape
            0, 13, 14, 17, 78, 308,
            // Jaw points
            172, 397, 136, 365,
        ]

        let mediumWeightIndices: Set<Int> = [
            // Eyebrows
            70, 107, 300, 336, 66, 105, 296, 334,
            // Cheekbones
            116, 345, 123, 352,
            // Face contour
            10, 127, 234, 356, 454,
        ]

        for i in 0..<matchCount {
            let lm1 = normalized1[i]
            let lm2 = normalized2[i]

            // Calculate 3D Euclidean distance
            let distance = sqrt(
                pow(lm1.x - lm2.x, 2) + pow(lm1.y - lm2.y, 2) + pow(lm1.z - lm2.z, 2)
            )

            // Apply weights based on landmark importance for identity
            let weight: Double
            if criticalIndices.contains(i) {
                weight = 4.0  // Critical landmarks get highest weight
            } else if highWeightIndices.contains(i) {
                weight = 2.5
            } else if mediumWeightIndices.contains(i) {
                weight = 1.5
            } else {
                weight = 1.0
            }

            weightedDistance += distance * weight
            totalWeight += weight
            totalDistance += distance
        }

        guard matchCount > 0, totalWeight > 0 else {
            return nil
        }

        // Calculate weighted average distance
        let averageWeightedDistance = weightedDistance / totalWeight
        let averageDistance = totalDistance / Double(matchCount)

        // Convert distance to similarity using steeper exponential decay
        // Steeper curve = more separation between similar and different faces
        // exp(-d * 4.0) maps: d=0 → 1.0, d=0.1 → 0.67, d=0.2 → 0.45, d=0.3 → 0.30
        let decayFactor = 4.0
        let landmarkSimilarity = exp(-averageWeightedDistance * decayFactor)

        // Calculate facial ratio similarity (more pose-invariant)
        let ratioSimilarity = calculateFacialRatioSimilarity(detectedAll, storedAll)

        // Combine: 70% landmark matching + 30% ratio matching
        // Ratio matching helps when head pose varies
        let combinedSimilarity = landmarkSimilarity * 0.7 + ratioSimilarity * 0.3

        print(
            "📊 All-478 Similarity: \(String(format: "%.1f%%", combinedSimilarity * 100)) | Matched: \(matchCount) landmarks | AvgDist: \(String(format: "%.4f", averageDistance)) | WeightedAvg: \(String(format: "%.4f", averageWeightedDistance))"
        )

        return combinedSimilarity
    }

    /// Calculate similarity based on facial proportions/ratios
    /// These ratios are more invariant to head pose changes
    private func calculateFacialRatioSimilarity(
        _ landmarks1: [MediaPipePoint3D], _ landmarks2: [MediaPipePoint3D]
    ) -> Double {
        guard landmarks1.count > 400, landmarks2.count > 400 else { return 0.5 }

        // Helper function to calculate distance between two landmarks
        func dist(_ lm: [MediaPipePoint3D], _ i1: Int, _ i2: Int) -> Double {
            let p1 = lm[i1]
            let p2 = lm[i2]
            return sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2) + pow(p2.z - p1.z, 2))
        }

        // Calculate key facial ratios that are relatively pose-invariant
        // All ratios are normalized by inter-ocular distance

        // Inter-ocular distance (baseline)
        let iod1 = dist(landmarks1, 33, 263)
        let iod2 = dist(landmarks2, 33, 263)

        guard iod1 > 0, iod2 > 0 else { return 0.5 }

        // Calculate ratios relative to inter-ocular distance
        var ratios1: [Double] = []
        var ratios2: [Double] = []

        // 1. Nose length / IOD (nose bridge to tip)
        ratios1.append(dist(landmarks1, 6, 1) / iod1)
        ratios2.append(dist(landmarks2, 6, 1) / iod2)

        // 2. Nose width / IOD
        ratios1.append(dist(landmarks1, 129, 358) / iod1)
        ratios2.append(dist(landmarks2, 129, 358) / iod2)

        // 3. Mouth width / IOD
        ratios1.append(dist(landmarks1, 61, 291) / iod1)
        ratios2.append(dist(landmarks2, 61, 291) / iod2)

        // 4. Eye to mouth distance / IOD (vertical proportion)
        ratios1.append(dist(landmarks1, 33, 61) / iod1)
        ratios2.append(dist(landmarks2, 33, 61) / iod2)

        // 5. Eye to chin / IOD
        ratios1.append(dist(landmarks1, 33, 152) / iod1)
        ratios2.append(dist(landmarks2, 33, 152) / iod2)

        // 6. Eye to nose tip / IOD
        ratios1.append(dist(landmarks1, 33, 1) / iod1)
        ratios2.append(dist(landmarks2, 33, 1) / iod2)

        // 7. Forehead to nose / IOD (estimate using landmarks 10 and 1)
        ratios1.append(dist(landmarks1, 10, 1) / iod1)
        ratios2.append(dist(landmarks2, 10, 1) / iod2)

        // 8. Left eye width / IOD
        ratios1.append(dist(landmarks1, 33, 133) / iod1)
        ratios2.append(dist(landmarks2, 33, 133) / iod2)

        // 9. Right eye width / IOD
        ratios1.append(dist(landmarks1, 263, 362) / iod1)
        ratios2.append(dist(landmarks2, 263, 362) / iod2)

        // 10. Jaw width / IOD (gonion to gonion estimate using landmarks 172 and 397)
        ratios1.append(dist(landmarks1, 172, 397) / iod1)
        ratios2.append(dist(landmarks2, 172, 397) / iod2)

        // Calculate ratio similarity
        var totalRatioDiff: Double = 0
        for i in 0..<ratios1.count {
            let diff = abs(ratios1[i] - ratios2[i])
            totalRatioDiff += diff
        }

        let avgRatioDiff = totalRatioDiff / Double(ratios1.count)

        // Convert to similarity (lower diff = higher similarity)
        // Use gentler decay for ratio matching since differences are typically small
        let ratioSimilarity = exp(-avgRatioDiff * 8.0)

        return ratioSimilarity
    }

    /// Improved normalization using nose tip as center and eye-line for rotation
    private func normalizeAllLandmarksImproved(_ landmarks: [MediaPipePoint3D])
        -> [MediaPipePoint3D]
    {
        guard landmarks.count > 263 else { return landmarks }

        // Use nose tip (landmark 1) as center point - more stable than bounding box center
        let noseTip = landmarks[1]
        let centerX = noseTip.x
        let centerY = noseTip.y
        let centerZ = noseTip.z

        // Use inter-ocular distance as scale reference (landmarks 33 and 263)
        let leftEye = landmarks[33]  // Left eye outer corner
        let rightEye = landmarks[263]  // Right eye outer corner
        var scale = sqrt(pow(rightEye.x - leftEye.x, 2) + pow(rightEye.y - leftEye.y, 2))

        // Prevent division by very small numbers
        if scale < 10 {
            // Fall back to face width
            var minX = Double.infinity
            var maxX = -Double.infinity
            for lm in landmarks {
                minX = min(minX, lm.x)
                maxX = max(maxX, lm.x)
            }
            scale = maxX - minX
        }
        if scale == 0 { scale = 1 }

        // Calculate rotation angle from eye line to horizontal
        let eyeAngle = atan2(rightEye.y - leftEye.y, rightEye.x - leftEye.x)
        let cosAngle = cos(-eyeAngle)
        let sinAngle = sin(-eyeAngle)

        // Normalize each landmark: center, rotate, scale
        return landmarks.map { lm in
            // Translate to nose-tip center
            let dx = lm.x - centerX
            let dy = lm.y - centerY
            let dz = lm.z - centerZ

            // Rotate to align eyes horizontally (2D rotation in xy plane)
            let rotatedX = dx * cosAngle - dy * sinAngle
            let rotatedY = dx * sinAngle + dy * cosAngle

            // Scale by inter-ocular distance
            return MediaPipePoint3D(
                x: rotatedX / scale,
                y: rotatedY / scale,
                z: dz / scale
            )
        }
    }

    /// Original normalization (kept for reference)
    private func normalizeAllLandmarks(_ landmarks: [MediaPipePoint3D]) -> [MediaPipePoint3D] {
        guard landmarks.count >= 2 else { return landmarks }

        // Find bounding box
        var minX = Double.infinity
        var maxX = -Double.infinity
        var minY = Double.infinity
        var maxY = -Double.infinity
        var minZ = Double.infinity
        var maxZ = -Double.infinity

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

        // Use inter-ocular distance as scale reference (landmarks 33 and 263)
        var scale: Double
        if landmarks.count > 263 {
            let leftEye = landmarks[33]  // Left eye outer corner
            let rightEye = landmarks[263]  // Right eye outer corner
            scale = sqrt(pow(rightEye.x - leftEye.x, 2) + pow(rightEye.y - leftEye.y, 2))
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
            MediaPipePoint3D(
                x: (lm.x - centerX) / scale,
                y: (lm.y - centerY) / scale,
                z: (lm.z - centerZ) / scale
            )
        }
    }

    // MARK: - Main Face Detection & Recognition

    func detectAndRecognizeFace(in image: UIImage) async throws -> FaceMatchResult {
        let startTime = Date()

        // Step 1: Detect face and generate MediaPipe-compatible landmarks
        let detectedEncoding = try await detectFaceLandmarks(in: image)

        print("📍 Detected \(detectedEncoding.landmarks.count) landmarks from camera")

        // Step 2: Match against local cache
        let matchResult = matchFaceAgainstLocalCache(detectedEncoding)
        if let match = matchResult.match {
            // Find corresponding student object
            let student =
                students.first { $0.id == match.studentId }
                ?? Student(
                    id: match.studentId,
                    firstName: match.studentName.components(separatedBy: " ").first
                        ?? match.studentName,
                    lastName: match.studentName.components(separatedBy: " ").dropFirst().joined(
                        separator: " "),
                    className: match.className ?? "",
                    parentId: match.parentId ?? "",
                    status: .registered
                )

            let processingTime = Date().timeIntervalSince(startTime)

            return FaceMatchResult(
                student: student,
                confidence: match.similarity,
                matchTimestamp: match.matchTimestamp,
                processingTime: processingTime
            )
        } else {
            throw FaceRecognitionError.noMatch
        }
    }
}
