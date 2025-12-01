//
//  FaceMatch.swift
//  FaceRecognitionClient
//
//  Created on November 28, 2025.
//

import Foundation

struct FaceMatchResult {
    let student: Student
    let confidence: Double
    let matchTimestamp: Date
    let processingTime: TimeInterval
    
    var isValidMatch: Bool {
        return confidence >= SettingsService.shared.matchThreshold
    }
    
    var confidencePercentage: String {
        return String(format: "%.1f%%", confidence * 100)
    }
}

enum FaceRecognitionError: Error, LocalizedError, Equatable {
    case noFaceDetected
    case multipleFacesDetected
    case noMatch
    case encodingFailed
    case databaseError(String)
    case lowConfidence
    case cameraAccessDenied
    case invalidImage
    
    var errorDescription: String? {
        switch self {
        case .noFaceDetected:
            return "No face detected in frame"
        case .multipleFacesDetected:
            return "Multiple faces detected. Please ensure only one person is visible."
        case .noMatch:
            return "Face not recognized. Please try again."
        case .encodingFailed:
            return "Failed to process face data"
        case .databaseError(let message):
            return "Database error: \(message)"
        case .lowConfidence:
            return "Recognition confidence too low"
        case .cameraAccessDenied:
            return "Camera access denied. Please enable in Settings."
        case .invalidImage:
            return "Invalid image format"
        }
    }
}
