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
    
    /// Convert Vision framework face observation to MediaPipe-compatible format
    private func convertToMediaPipeEncoding(_ face: VNFaceObservation, imageSize: CGSize) -> MediaPipeFaceEncoding {
        var landmarks: [MediaPipeLandmark] = []
        
        // Helper to convert normalized point to image coordinates
        func convertPoint(_ point: CGPoint, boundingBox: CGRect) -> (x: Double, y: Double) {
            let x = (boundingBox.origin.x + point.x * boundingBox.width) * imageSize.width
            let y = (1 - boundingBox.origin.y - point.y * boundingBox.height) * imageSize.height
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
        
        // Build bounding box points
        let boundingBoxPoints = [
            MediaPipeBoundingBoxPoint(x: Double(bbox.origin.x * imageSize.width), y: Double((1 - bbox.origin.y - bbox.height) * imageSize.height)),
            MediaPipeBoundingBoxPoint(x: Double((bbox.origin.x + bbox.width) * imageSize.width), y: Double((1 - bbox.origin.y - bbox.height) * imageSize.height)),
            MediaPipeBoundingBoxPoint(x: Double((bbox.origin.x + bbox.width) * imageSize.width), y: Double((1 - bbox.origin.y) * imageSize.height)),
            MediaPipeBoundingBoxPoint(x: Double(bbox.origin.x * imageSize.width), y: Double((1 - bbox.origin.y) * imageSize.height))
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
        
        var bestMatch: LocalFaceMatchResult?
        var highestSimilarity: Double = 0
        var bestCandidateName: String?
        
        for faceData in mediaPipeRecords {
            guard let storedEncoding = faceData.parseMediaPipeEncoding() else {
                continue
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
    
    /// Calculate similarity between two MediaPipe face encodings using normalized landmark distances
    /// Landmarks are normalized RELATIVE to bounding box (0-1 range within face)
    private func calculateMediaPipeSimilarity(_ encoding1: MediaPipeFaceEncoding, _ encoding2: MediaPipeFaceEncoding) -> Double {
        // Get bounding box info for both encodings
        let bbox1 = getBoundingBoxRect(encoding1.boundingBox)
        let bbox2 = getBoundingBoxRect(encoding2.boundingBox)
        
        guard bbox1.width > 0 && bbox1.height > 0 && bbox2.width > 0 && bbox2.height > 0 else {
            print("⚠️ Invalid bounding box dimensions")
            return 0
        }
        
        var totalDistance: Double = 0
        var matchingLandmarks = 0
        
        // Match landmarks by type and calculate normalized distances
        for lm1 in encoding1.landmarks {
            if let lm2 = encoding2.landmarks.first(where: { $0.type == lm1.type }) {
                // Normalize coordinates RELATIVE to bounding box (0-1 range within face)
                // This ensures we're comparing face GEOMETRY, not absolute positions
                let x1Norm = (lm1.x - bbox1.minX) / bbox1.width
                let y1Norm = (lm1.y - bbox1.minY) / bbox1.height
                let x2Norm = (lm2.x - bbox2.minX) / bbox2.width
                let y2Norm = (lm2.y - bbox2.minY) / bbox2.height
                
                // Calculate Euclidean distance in normalized space
                let distance = sqrt(pow(x1Norm - x2Norm, 2) + pow(y1Norm - y2Norm, 2))
                totalDistance += distance
                matchingLandmarks += 1
            }
        }
        
        guard matchingLandmarks >= 10 else {
            print("⚠️ Not enough matching landmarks: \(matchingLandmarks) (need at least 10)")
            return 0
        }
        
        let averageDistance = totalDistance / Double(matchingLandmarks)
        
        // Log for debugging
        print("📊 Matching \(matchingLandmarks) landmarks, avg distance: \(String(format: "%.4f", averageDistance))")
        
        // Convert distance to similarity using exponential decay
        // Adjusted k value: smaller distances should give higher similarity
        // k=5 gives: dist=0 → sim=1, dist=0.05 → sim=0.78, dist=0.1 → sim=0.61, dist=0.2 → sim=0.37
        // This is more lenient than k=8 and better for real-world face matching
        let k: Double = 5.0
        let similarity = exp(-k * averageDistance)
        
        print("📊 Calculated similarity: \(String(format: "%.1f%%", similarity * 100))")
        
        return min(max(similarity, 0), 1)
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
