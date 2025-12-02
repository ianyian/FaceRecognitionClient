//
//  FaceRecognitionService.swift
//  FaceRecognitionClient
//
//  Created on November 28, 2025.
//  Updated on December 2, 2025 - Uses MediaPipe landmark format for face matching
//

import Foundation
import Vision
import CoreML
import UIKit

class FaceRecognitionService {
    static let shared = FaceRecognitionService()
    
    private let cacheService = FaceDataCacheService.shared
    private let settingsService = SettingsService.shared
    
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
    
    // MARK: - Face Detection (Vision Framework → MediaPipe-compatible landmarks)
    
    /// Detect face and extract landmarks from camera image
    /// Generates landmarks compatible with MediaPipe format for matching
    func detectFaceLandmarks(in image: UIImage) async throws -> MediaPipeFaceEncoding {
        guard let cgImage = image.cgImage else {
            throw FaceRecognitionError.invalidImage
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            var isResumed = false
            
            let request = VNDetectFaceLandmarksRequest { request, error in
                guard !isResumed else { return }
                
                if let error = error {
                    isResumed = true
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let results = request.results as? [VNFaceObservation],
                      let face = results.first else {
                    isResumed = true
                    if (request.results as? [VNFaceObservation])?.isEmpty ?? true {
                        continuation.resume(throwing: FaceRecognitionError.noFaceDetected)
                    } else {
                        continuation.resume(throwing: FaceRecognitionError.multipleFacesDetected)
                    }
                    return
                }
                
                // Check for multiple faces
                if results.count > 1 {
                    isResumed = true
                    continuation.resume(throwing: FaceRecognitionError.multipleFacesDetected)
                    return
                }
                
                // Convert VNFaceObservation to MediaPipe-compatible format
                let encoding = self.convertToMediaPipeEncoding(face, imageSize: CGSize(width: cgImage.width, height: cgImage.height))
                
                isResumed = true
                continuation.resume(returning: encoding)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    guard !isResumed else { return }
                    isResumed = true
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Constants for MediaPipe compatibility
    
    /// Standard scale used by MediaPipe web app (512x512 normalized coordinate space)
    private let mediaPipeScale: Double = 512.0
    
    /// Convert Vision framework face observation to MediaPipe-compatible format
    /// Coordinates are scaled to 512x512 pixel space to match web app format
    private func convertToMediaPipeEncoding(_ face: VNFaceObservation, imageSize: CGSize) -> MediaPipeFaceEncoding {
        var landmarks: [MediaPipeLandmark] = []
        
        // Helper to convert Vision landmark point to MediaPipe 512x512 coordinate space
        // Vision landmarks are normalized WITHIN the bounding box (0-1 range)
        // MediaPipe coordinates are in 512x512 pixel space
        func convertPoint(_ point: CGPoint, boundingBox: CGRect) -> (x: Double, y: Double) {
            // Step 1: Convert from bounding box relative (0-1) to image relative (0-1)
            // Vision bounding box origin is bottom-left, y increases upward
            // Vision landmark points within bounding box: origin is also bottom-left
            let imageRelativeX = boundingBox.origin.x + point.x * boundingBox.width
            let imageRelativeY = boundingBox.origin.y + point.y * boundingBox.height
            
            // Step 2: Convert to MediaPipe coordinate system
            // MediaPipe uses top-left origin, y increases downward, in 512x512 space
            let x = imageRelativeX * mediaPipeScale
            let y = (1.0 - imageRelativeY) * mediaPipeScale  // Flip Y axis
            
            return (Double(x), Double(y))
        }
        
        let bbox = face.boundingBox
        
        // Extract landmarks from Vision framework and map to MediaPipe types
        if let allPoints = face.landmarks {
            // Left eye
            if let leftEye = allPoints.leftEye?.normalizedPoints.first {
                let pos = convertPoint(leftEye, boundingBox: bbox)
                landmarks.append(MediaPipeLandmark(type: "LEFT_EYE", x: pos.x, y: pos.y, z: 0))
            }
            
            // Right eye
            if let rightEye = allPoints.rightEye?.normalizedPoints.first {
                let pos = convertPoint(rightEye, boundingBox: bbox)
                landmarks.append(MediaPipeLandmark(type: "RIGHT_EYE", x: pos.x, y: pos.y, z: 0))
            }
            
            // Left eye corners
            if let leftEye = allPoints.leftEye {
                let points = leftEye.normalizedPoints
                if points.count >= 4 {
                    let leftCorner = convertPoint(points[0], boundingBox: bbox)
                    landmarks.append(MediaPipeLandmark(type: "LEFT_EYE_LEFT_CORNER", x: leftCorner.x, y: leftCorner.y, z: 0))
                    
                    let rightCorner = convertPoint(points[points.count/2], boundingBox: bbox)
                    landmarks.append(MediaPipeLandmark(type: "LEFT_EYE_RIGHT_CORNER", x: rightCorner.x, y: rightCorner.y, z: 0))
                    
                    // Top and bottom
                    if points.count >= 6 {
                        let top = convertPoint(points[1], boundingBox: bbox)
                        landmarks.append(MediaPipeLandmark(type: "LEFT_EYE_TOP_BOUNDARY", x: top.x, y: top.y, z: 0))
                        
                        let bottom = convertPoint(points[points.count - 2], boundingBox: bbox)
                        landmarks.append(MediaPipeLandmark(type: "LEFT_EYE_BOTTOM_BOUNDARY", x: bottom.x, y: bottom.y, z: 0))
                    }
                }
            }
            
            // Right eye corners
            if let rightEye = allPoints.rightEye {
                let points = rightEye.normalizedPoints
                if points.count >= 4 {
                    let leftCorner = convertPoint(points[0], boundingBox: bbox)
                    landmarks.append(MediaPipeLandmark(type: "RIGHT_EYE_LEFT_CORNER", x: leftCorner.x, y: leftCorner.y, z: 0))
                    
                    let rightCorner = convertPoint(points[points.count/2], boundingBox: bbox)
                    landmarks.append(MediaPipeLandmark(type: "RIGHT_EYE_RIGHT_CORNER", x: rightCorner.x, y: rightCorner.y, z: 0))
                    
                    if points.count >= 6 {
                        let top = convertPoint(points[1], boundingBox: bbox)
                        landmarks.append(MediaPipeLandmark(type: "RIGHT_EYE_TOP_BOUNDARY", x: top.x, y: top.y, z: 0))
                        
                        let bottom = convertPoint(points[points.count - 2], boundingBox: bbox)
                        landmarks.append(MediaPipeLandmark(type: "RIGHT_EYE_BOTTOM_BOUNDARY", x: bottom.x, y: bottom.y, z: 0))
                    }
                }
            }
            
            // Eyebrows
            if let leftBrow = allPoints.leftEyebrow?.normalizedPoints {
                if leftBrow.count >= 2 {
                    let left = convertPoint(leftBrow[0], boundingBox: bbox)
                    landmarks.append(MediaPipeLandmark(type: "LEFT_OF_LEFT_EYEBROW", x: left.x, y: left.y, z: 0))
                    
                    let right = convertPoint(leftBrow[leftBrow.count - 1], boundingBox: bbox)
                    landmarks.append(MediaPipeLandmark(type: "RIGHT_OF_LEFT_EYEBROW", x: right.x, y: right.y, z: 0))
                    
                    let mid = convertPoint(leftBrow[leftBrow.count / 2], boundingBox: bbox)
                    landmarks.append(MediaPipeLandmark(type: "LEFT_EYEBROW_UPPER_MIDPOINT", x: mid.x, y: mid.y, z: 0))
                }
            }
            
            if let rightBrow = allPoints.rightEyebrow?.normalizedPoints {
                if rightBrow.count >= 2 {
                    let left = convertPoint(rightBrow[0], boundingBox: bbox)
                    landmarks.append(MediaPipeLandmark(type: "LEFT_OF_RIGHT_EYEBROW", x: left.x, y: left.y, z: 0))
                    
                    let right = convertPoint(rightBrow[rightBrow.count - 1], boundingBox: bbox)
                    landmarks.append(MediaPipeLandmark(type: "RIGHT_OF_RIGHT_EYEBROW", x: right.x, y: right.y, z: 0))
                    
                    let mid = convertPoint(rightBrow[rightBrow.count / 2], boundingBox: bbox)
                    landmarks.append(MediaPipeLandmark(type: "RIGHT_EYEBROW_UPPER_MIDPOINT", x: mid.x, y: mid.y, z: 0))
                }
            }
            
            // Midpoint between eyes
            if let leftEye = allPoints.leftEye?.normalizedPoints.first,
               let rightEye = allPoints.rightEye?.normalizedPoints.first {
                let midX = (leftEye.x + rightEye.x) / 2
                let midY = (leftEye.y + rightEye.y) / 2
                let pos = convertPoint(CGPoint(x: midX, y: midY), boundingBox: bbox)
                landmarks.append(MediaPipeLandmark(type: "MIDPOINT_BETWEEN_EYES", x: pos.x, y: pos.y, z: 0))
            }
            
            // Nose
            if let nose = allPoints.nose?.normalizedPoints {
                if let tip = nose.last {
                    let pos = convertPoint(tip, boundingBox: bbox)
                    landmarks.append(MediaPipeLandmark(type: "NOSE_TIP", x: pos.x, y: pos.y, z: 0))
                }
                if nose.count >= 3 {
                    let bottomCenter = convertPoint(nose[nose.count - 1], boundingBox: bbox)
                    landmarks.append(MediaPipeLandmark(type: "NOSE_BOTTOM_CENTER", x: bottomCenter.x, y: bottomCenter.y, z: 0))
                }
            }
            
            if let noseCrest = allPoints.noseCrest?.normalizedPoints {
                if noseCrest.count >= 2 {
                    let left = convertPoint(noseCrest[0], boundingBox: bbox)
                    landmarks.append(MediaPipeLandmark(type: "NOSE_BOTTOM_LEFT", x: left.x, y: left.y, z: 0))
                    
                    let right = convertPoint(noseCrest[noseCrest.count - 1], boundingBox: bbox)
                    landmarks.append(MediaPipeLandmark(type: "NOSE_BOTTOM_RIGHT", x: right.x, y: right.y, z: 0))
                }
            }
            
            // Mouth/Lips
            if let outerLips = allPoints.outerLips?.normalizedPoints {
                if outerLips.count >= 6 {
                    let left = convertPoint(outerLips[0], boundingBox: bbox)
                    landmarks.append(MediaPipeLandmark(type: "MOUTH_LEFT", x: left.x, y: left.y, z: 0))
                    
                    let right = convertPoint(outerLips[outerLips.count / 2], boundingBox: bbox)
                    landmarks.append(MediaPipeLandmark(type: "MOUTH_RIGHT", x: right.x, y: right.y, z: 0))
                    
                    // Upper lip (top of outer lips)
                    let upper = convertPoint(outerLips[outerLips.count / 4], boundingBox: bbox)
                    landmarks.append(MediaPipeLandmark(type: "UPPER_LIP", x: upper.x, y: upper.y, z: 0))
                    
                    // Lower lip (bottom of outer lips)
                    let lower = convertPoint(outerLips[3 * outerLips.count / 4], boundingBox: bbox)
                    landmarks.append(MediaPipeLandmark(type: "LOWER_LIP", x: lower.x, y: lower.y, z: 0))
                }
            }
            
            if let innerLips = allPoints.innerLips?.normalizedPoints {
                if innerLips.count >= 2 {
                    // Mouth center (average of inner lips)
                    var sumX: CGFloat = 0
                    var sumY: CGFloat = 0
                    for p in innerLips {
                        sumX += p.x
                        sumY += p.y
                    }
                    let centerPoint = CGPoint(x: sumX / CGFloat(innerLips.count), y: sumY / CGFloat(innerLips.count))
                    let center = convertPoint(centerPoint, boundingBox: bbox)
                    landmarks.append(MediaPipeLandmark(type: "MOUTH_CENTER", x: center.x, y: center.y, z: 0))
                }
            }
            
            // Face contour for chin/cheeks
            if let faceContour = allPoints.faceContour?.normalizedPoints {
                if faceContour.count >= 5 {
                    // Chin (bottom of face contour)
                    let chin = convertPoint(faceContour[faceContour.count / 2], boundingBox: bbox)
                    landmarks.append(MediaPipeLandmark(type: "CHIN_GNATHION", x: chin.x, y: chin.y, z: 0))
                    
                    // Left and right gonion (jaw corners)
                    let leftGonion = convertPoint(faceContour[0], boundingBox: bbox)
                    landmarks.append(MediaPipeLandmark(type: "CHIN_LEFT_GONION", x: leftGonion.x, y: leftGonion.y, z: 0))
                    
                    let rightGonion = convertPoint(faceContour[faceContour.count - 1], boundingBox: bbox)
                    landmarks.append(MediaPipeLandmark(type: "CHIN_RIGHT_GONION", x: rightGonion.x, y: rightGonion.y, z: 0))
                    
                    // Cheek centers
                    let leftCheek = convertPoint(faceContour[faceContour.count / 4], boundingBox: bbox)
                    landmarks.append(MediaPipeLandmark(type: "LEFT_CHEEK_CENTER", x: leftCheek.x, y: leftCheek.y, z: 0))
                    
                    let rightCheek = convertPoint(faceContour[3 * faceContour.count / 4], boundingBox: bbox)
                    landmarks.append(MediaPipeLandmark(type: "RIGHT_CHEEK_CENTER", x: rightCheek.x, y: rightCheek.y, z: 0))
                }
            }
            
            // Forehead (using median line if available)
            if let medianLine = allPoints.medianLine?.normalizedPoints {
                if let forehead = medianLine.first {
                    let pos = convertPoint(forehead, boundingBox: bbox)
                    landmarks.append(MediaPipeLandmark(type: "FOREHEAD_GLABELLA", x: pos.x, y: pos.y, z: 0))
                }
            }
        }
        
        // Build bounding box points in 512x512 coordinate space (matching web app)
        let boundingBoxPoints = [
            MediaPipeBoundingBoxPoint(x: Double(bbox.origin.x) * mediaPipeScale, y: Double(1 - bbox.origin.y - bbox.height) * mediaPipeScale),
            MediaPipeBoundingBoxPoint(x: Double(bbox.origin.x + bbox.width) * mediaPipeScale, y: Double(1 - bbox.origin.y - bbox.height) * mediaPipeScale),
            MediaPipeBoundingBoxPoint(x: Double(bbox.origin.x + bbox.width) * mediaPipeScale, y: Double(1 - bbox.origin.y) * mediaPipeScale),
            MediaPipeBoundingBoxPoint(x: Double(bbox.origin.x) * mediaPipeScale, y: Double(1 - bbox.origin.y) * mediaPipeScale)
        ]
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return MediaPipeFaceEncoding(
            landmarks: landmarks,
            allLandmarks: nil,  // Vision framework doesn't provide 468 mesh points
            boundingBox: boundingBoxPoints,
            confidence: Double(face.confidence),
            encoderType: "vision",  // Indicate this was generated by Vision framework
            timestamp: isoFormatter.string(from: Date())
        )
    }
    
    // MARK: - Local Face Matching (MediaPipe Landmark-based)
    
    /// Match detected face landmarks against local cache
    /// Returns FaceMatchingResult with best match info (always includes best score for debugging)
    func matchFaceAgainstLocalCache(_ detectedEncoding: MediaPipeFaceEncoding) -> FaceMatchingResult {
        let faceDataList = cacheService.getFaceDataForMatching()
        let threshold = settingsService.matchThreshold
        
        guard !faceDataList.isEmpty else {
            print("⚠️ No face data in cache for matching")
            return FaceMatchingResult(match: nil, bestSimilarity: 0, bestCandidateName: nil, candidatesChecked: 0)
        }
        
        // Filter for MediaPipe format records
        let mediaPipeRecords = faceDataList.filter { $0.isMediaPipeFormat }
        
        if mediaPipeRecords.isEmpty {
            print("⚠️ No MediaPipe encodings in cache")
            return FaceMatchingResult(match: nil, bestSimilarity: 0, bestCandidateName: nil, candidatesChecked: faceDataList.count)
        }
        
        print("🔍 Matching against \(mediaPipeRecords.count) MediaPipe face records with threshold \(String(format: "%.0f%%", threshold * 100))")
        
        // Debug: Show first detected encoding sample
        print("📸 Camera encoding: \(detectedEncoding.landmarks.count) landmarks, type=\(detectedEncoding.encoderType ?? "unknown")")
        if let leftEye = detectedEncoding.landmarks.first(where: { $0.type == "LEFT_EYE" }) {
            print("   LEFT_EYE: x=\(String(format: "%.1f", leftEye.x)), y=\(String(format: "%.1f", leftEye.y))")
        }
        
        var bestMatch: LocalFaceMatchResult?
        var highestSimilarity: Double = 0
        var bestCandidateName: String?
        var isFirstRecord = true
        
        for faceData in mediaPipeRecords {
            guard let storedEncoding = faceData.parseMediaPipeEncoding() else {
                continue
            }
            
            // Debug: Show first stored encoding sample
            if isFirstRecord {
                print("💾 Stored encoding: \(storedEncoding.landmarks.count) landmarks, type=\(storedEncoding.encoderType ?? "unknown")")
                if let leftEye = storedEncoding.landmarks.first(where: { $0.type == "LEFT_EYE" }) {
                    print("   LEFT_EYE: x=\(String(format: "%.1f", leftEye.x)), y=\(String(format: "%.1f", leftEye.y))")
                }
                isFirstRecord = false
            }
            
            let similarity = calculateMediaPipeSimilarity(detectedEncoding, storedEncoding)
            print("   📊 \(faceData.studentName): \(String(format: "%.1f%%", similarity * 100))")
            
            if similarity > highestSimilarity {
                highestSimilarity = similarity
                bestCandidateName = faceData.studentName
                bestMatch = LocalFaceMatchResult(
                    studentId: faceData.studentId,
                    studentName: faceData.studentName,
                    className: faceData.className,
                    parentId: faceData.parentId,
                    similarity: similarity,
                    matchedSampleIndex: faceData.sampleIndex,
                    matchTimestamp: Date()
                )
            }
        }
        
        // Only return match if above threshold
        if let match = bestMatch, match.similarity >= threshold {
            print("✅ Match found: \(match.studentName) with \(match.similarityPercentage) similarity")
            return FaceMatchingResult(match: match, bestSimilarity: highestSimilarity, bestCandidateName: bestCandidateName, candidatesChecked: mediaPipeRecords.count)
        } else {
            print("❌ No match above threshold. Best: \(String(format: "%.1f%%", highestSimilarity * 100))")
            return FaceMatchingResult(match: nil, bestSimilarity: highestSimilarity, bestCandidateName: bestCandidateName, candidatesChecked: mediaPipeRecords.count)
        }
    }
    
    /// Calculate similarity between two face encodings using FACIAL GEOMETRY RATIOS
    /// This approach works across different landmark detectors (Vision vs MediaPipe)
    /// because it compares relative proportions, not absolute positions
    private func calculateMediaPipeSimilarity(_ encoding1: MediaPipeFaceEncoding, _ encoding2: MediaPipeFaceEncoding) -> Double {
        // Extract key facial measurements as ratios
        let ratios1 = extractFacialRatios(encoding1)
        let ratios2 = extractFacialRatios(encoding2)
        
        guard !ratios1.isEmpty && !ratios2.isEmpty else {
            print("⚠️ Could not extract facial ratios")
            return 0
        }
        
        // Compare common ratios
        var totalDifference: Double = 0
        var comparedRatios = 0
        
        for (name, value1) in ratios1 {
            if let value2 = ratios2[name] {
                // Percentage difference between ratios
                let diff = abs(value1 - value2) / max(value1, value2, 0.001)
                totalDifference += diff
                comparedRatios += 1
                print("   📐 \(name): \(String(format: "%.3f", value1)) vs \(String(format: "%.3f", value2)) (diff: \(String(format: "%.1f%%", diff * 100)))")
            }
        }
        
        guard comparedRatios >= 3 else {
            print("⚠️ Not enough comparable ratios: \(comparedRatios)")
            return 0
        }
        
        let averageDifference = totalDifference / Double(comparedRatios)
        
        // Convert difference to similarity
        // If ratios differ by 0% → 100% similar
        // If ratios differ by 10% → 90% similar
        // If ratios differ by 30% → 70% similar
        let similarity = max(0, 1 - averageDifference)
        
        print("📊 Geometry matching: \(comparedRatios) ratios, avg difference: \(String(format: "%.1f%%", averageDifference * 100))")
        print("📊 Calculated similarity: \(String(format: "%.1f%%", similarity * 100))")
        
        return similarity
    }
    
    /// Extract facial geometry ratios that are invariant to position, scale, and detector type
    private func extractFacialRatios(_ encoding: MediaPipeFaceEncoding) -> [String: Double] {
        var ratios: [String: Double] = [:]
        
        // Get key landmarks
        let leftEye = encoding.landmarks.first { $0.type == "LEFT_EYE" }
        let rightEye = encoding.landmarks.first { $0.type == "RIGHT_EYE" }
        let noseTip = encoding.landmarks.first { $0.type == "NOSE_TIP" }
        let mouthLeft = encoding.landmarks.first { $0.type == "MOUTH_LEFT" }
        let mouthRight = encoding.landmarks.first { $0.type == "MOUTH_RIGHT" }
        let chin = encoding.landmarks.first { $0.type == "CHIN_GNATHION" }
        let mouthCenter = encoding.landmarks.first { $0.type == "MOUTH_CENTER" }
        let midpointEyes = encoding.landmarks.first { $0.type == "MIDPOINT_BETWEEN_EYES" }
        let leftEyeLeftCorner = encoding.landmarks.first { $0.type == "LEFT_EYE_LEFT_CORNER" }
        let leftEyeRightCorner = encoding.landmarks.first { $0.type == "LEFT_EYE_RIGHT_CORNER" }
        let rightEyeLeftCorner = encoding.landmarks.first { $0.type == "RIGHT_EYE_LEFT_CORNER" }
        let rightEyeRightCorner = encoding.landmarks.first { $0.type == "RIGHT_EYE_RIGHT_CORNER" }
        let noseBottomCenter = encoding.landmarks.first { $0.type == "NOSE_BOTTOM_CENTER" }
        
        // Calculate inter-ocular distance (reference measurement)
        guard let le = leftEye, let re = rightEye else {
            return ratios
        }
        let eyeDistance = distance(le, re)
        guard eyeDistance > 0 else { return ratios }
        
        // Ratio 1: Eye width to inter-ocular distance
        if let lel = leftEyeLeftCorner, let ler = leftEyeRightCorner {
            let leftEyeWidth = distance(lel, ler)
            ratios["leftEyeWidth"] = leftEyeWidth / eyeDistance
        }
        if let rel = rightEyeLeftCorner, let rer = rightEyeRightCorner {
            let rightEyeWidth = distance(rel, rer)
            ratios["rightEyeWidth"] = rightEyeWidth / eyeDistance
        }
        
        // Ratio 2: Nose to eye distance
        if let nose = noseTip {
            let noseToEyeMid = distance(nose, MediaPipeLandmark(type: "", x: (le.x + re.x)/2, y: (le.y + re.y)/2, z: 0))
            ratios["noseToEyeRatio"] = noseToEyeMid / eyeDistance
        }
        if let noseBottom = noseBottomCenter {
            let noseBottomToEyeMid = distance(noseBottom, MediaPipeLandmark(type: "", x: (le.x + re.x)/2, y: (le.y + re.y)/2, z: 0))
            ratios["noseBottomToEyeRatio"] = noseBottomToEyeMid / eyeDistance
        }
        
        // Ratio 3: Mouth width to inter-ocular distance
        if let ml = mouthLeft, let mr = mouthRight {
            let mouthWidth = distance(ml, mr)
            ratios["mouthWidthRatio"] = mouthWidth / eyeDistance
        }
        
        // Ratio 4: Chin to eye distance
        if let c = chin {
            let chinToEyeMid = distance(c, MediaPipeLandmark(type: "", x: (le.x + re.x)/2, y: (le.y + re.y)/2, z: 0))
            ratios["chinToEyeRatio"] = chinToEyeMid / eyeDistance
        }
        
        // Ratio 5: Mouth to nose vertical distance
        if let mc = mouthCenter, let nose = noseTip {
            let mouthToNose = abs(mc.y - nose.y)
            ratios["mouthToNoseRatio"] = mouthToNose / eyeDistance
        }
        
        // Ratio 6: Nose width (using nose bottom points if available)
        let noseLeft = encoding.landmarks.first { $0.type == "NOSE_BOTTOM_LEFT" }
        let noseRight = encoding.landmarks.first { $0.type == "NOSE_BOTTOM_RIGHT" }
        if let nl = noseLeft, let nr = noseRight {
            let noseWidth = distance(nl, nr)
            ratios["noseWidthRatio"] = noseWidth / eyeDistance
        }
        
        // Ratio 7: Face height to width (using chin and bounding box or eye-to-chin vs mouth width)
        if let c = chin, let ml = mouthLeft, let mr = mouthRight {
            let faceWidth = distance(ml, mr) * 1.5  // Approximate face width
            let eyeY = (le.y + re.y) / 2
            let faceHeight = abs(c.y - eyeY)
            if faceWidth > 0 {
                ratios["faceHeightToWidthRatio"] = faceHeight / faceWidth
            }
        }
        
        return ratios
    }
    
    /// Calculate 2D distance between two landmarks
    private func distance(_ lm1: MediaPipeLandmark, _ lm2: MediaPipeLandmark) -> Double {
        return sqrt(pow(lm1.x - lm2.x, 2) + pow(lm1.y - lm2.y, 2))
    }
    
    /// Get bounding box as a rect with minX, minY, width, height
    private func getBoundingBoxRect(_ boundingBox: [MediaPipeBoundingBoxPoint]) -> (minX: Double, minY: Double, width: Double, height: Double) {
        guard boundingBox.count >= 4 else {
            return (minX: 0, minY: 0, width: 1, height: 1)
        }
        
        let xs = boundingBox.map { $0.x }
        let ys = boundingBox.map { $0.y }
        
        let minX = xs.min() ?? 0
        let maxX = xs.max() ?? 1
        let minY = ys.min() ?? 0
        let maxY = ys.max() ?? 1
        
        return (minX: minX, minY: minY, width: max(maxX - minX, 1), height: max(maxY - minY, 1))
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
            let student = students.first { $0.id == match.studentId } ?? Student(
                id: match.studentId,
                firstName: match.studentName.components(separatedBy: " ").first ?? match.studentName,
                lastName: match.studentName.components(separatedBy: " ").dropFirst().joined(separator: " "),
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
