//
//  FaceData.swift
//  FaceRecognitionClient
//
//  Created on December 1, 2025.
//  Updated on December 2, 2025 - Uses MediaPipe landmark format for face matching
//

import Foundation

// MARK: - Face Data Document (from Firestore faceData collection)

struct FaceDataDocument: Codable, Identifiable {
    let faceDataId: String
    let studentId: String
    let studentDocId: String
    let studentName: String
    let className: String?
    let parentId: String?
    let sampleIndex: Int
    let encoding: String  // JSON string - MediaPipe landmarks format
    let faceConfidence: Double
    let version: Int
    let createdAt: String
    let updatedAt: String
    let isOrphaned: Bool?
    
    var id: String { faceDataId }
    
    // MARK: - Encoding Type Detection
    
    /// Determines if encoding uses MediaPipe landmark format
    var isMediaPipeFormat: Bool {
        guard !encoding.isEmpty else { return false }
        guard !encoding.hasPrefix("encoded_") else { return false }
        return encoding.contains("landmarks") || encoding.contains("allLandmarks")
    }
    
    // Check if encoding is valid for matching
    var hasValidEncoding: Bool {
        return isMediaPipeFormat
    }
    
    // MARK: - MediaPipe Format: Landmark-based encoding
    
    /// Parse encoding JSON to MediaPipeFaceEncoding struct
    func parseMediaPipeEncoding() -> MediaPipeFaceEncoding? {
        guard isMediaPipeFormat else { return nil }
        guard let data = encoding.data(using: .utf8) else { return nil }
        
        do {
            let decoded = try JSONDecoder().decode(MediaPipeFaceEncoding.self, from: data)
            return decoded
        } catch {
            print("❌ Failed to parse MediaPipe encoding: \(error)")
            return nil
        }
    }
}

// MARK: - MediaPipe Face Encoding (from Firestore)

struct MediaPipeFaceEncoding: Codable {
    let landmarks: [MediaPipeLandmark]      // 34 key facial landmarks
    let allLandmarks: [MediaPipePoint3D]?   // 468 full mesh points (optional)
    let boundingBox: [MediaPipeBoundingBoxPoint]
    let confidence: Double
    let encoderType: String?                // "mediapipe"
    
    // Legacy support
    let timestamp: String?
}

// MARK: - MediaPipe Landmark (34 key points with type label)

struct MediaPipeLandmark: Codable {
    let type: String    // e.g., "LEFT_EYE", "RIGHT_EYE", "NOSE_TIP"
    let x: Double
    let y: Double
    let z: Double
}

// MARK: - MediaPipe 3D Point (for allLandmarks - 468 points)

struct MediaPipePoint3D: Codable {
    let x: Double
    let y: Double
    let z: Double
}

// MARK: - MediaPipe Bounding Box Point

struct MediaPipeBoundingBoxPoint: Codable {
    let x: Double
    let y: Double
}

// MARK: - MediaPipe Landmark Types (34 key points)

enum MediaPipeLandmarkType: String, CaseIterable {
    case LEFT_EYE
    case RIGHT_EYE
    case LEFT_OF_LEFT_EYEBROW
    case RIGHT_OF_LEFT_EYEBROW
    case LEFT_OF_RIGHT_EYEBROW
    case RIGHT_OF_RIGHT_EYEBROW
    case MIDPOINT_BETWEEN_EYES
    case NOSE_TIP
    case UPPER_LIP
    case LOWER_LIP
    case MOUTH_LEFT
    case MOUTH_RIGHT
    case MOUTH_CENTER
    case NOSE_BOTTOM_RIGHT
    case NOSE_BOTTOM_LEFT
    case NOSE_BOTTOM_CENTER
    case LEFT_EYE_TOP_BOUNDARY
    case LEFT_EYE_RIGHT_CORNER
    case LEFT_EYE_BOTTOM_BOUNDARY
    case LEFT_EYE_LEFT_CORNER
    case RIGHT_EYE_TOP_BOUNDARY
    case RIGHT_EYE_RIGHT_CORNER
    case RIGHT_EYE_BOTTOM_BOUNDARY
    case RIGHT_EYE_LEFT_CORNER
    case LEFT_EYEBROW_UPPER_MIDPOINT
    case RIGHT_EYEBROW_UPPER_MIDPOINT
    case LEFT_EAR_TRAGION
    case RIGHT_EAR_TRAGION
    case FOREHEAD_GLABELLA
    case CHIN_GNATHION
    case CHIN_LEFT_GONION
    case CHIN_RIGHT_GONION
    case LEFT_CHEEK_CENTER
    case RIGHT_CHEEK_CENTER
}

// MARK: - Face Data Cache (local storage format)

struct FaceDataCache: Codable {
    let version: Int
    let lastUpdated: String
    let downloadedAt: String
    let totalRecords: Int
    let faceData: [FaceDataDocument]
    
    var downloadDate: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: downloadedAt)
    }
}

// MARK: - Face Match Result (for local matching)

struct LocalFaceMatchResult {
    let studentId: String
    let studentName: String
    let className: String?
    let parentId: String?
    let similarity: Double
    let matchedSampleIndex: Int
    let matchTimestamp: Date
    
    var isMatch: Bool {
        return similarity >= 0.75  // Default threshold, will be configurable
    }
    
    var similarityPercentage: String {
        return String(format: "%.1f%%", similarity * 100)
    }
}

// MARK: - Matching Result (includes best score even when no match)

struct FaceMatchingResult {
    let match: LocalFaceMatchResult?  // nil if no match above threshold
    let bestSimilarity: Double        // Best similarity score found
    let bestCandidateName: String?    // Name of the best candidate (even if below threshold)
    let candidatesChecked: Int        // Number of face records checked
    
    var bestSimilarityPercentage: String {
        return String(format: "%.1f%%", bestSimilarity * 100)
    }
    
    var hasMatch: Bool {
        return match != nil
    }
}

// MARK: - Cache Status

struct FaceDataCacheStatus {
    let hasCache: Bool
    let recordCount: Int
    let studentCount: Int
    let lastUpdated: Date?
    let fileSizeKB: Int
    let version: Int
    
    static var empty: FaceDataCacheStatus {
        return FaceDataCacheStatus(
            hasCache: false,
            recordCount: 0,
            studentCount: 0,
            lastUpdated: nil,
            fileSizeKB: 0,
            version: 0
        )
    }
}
