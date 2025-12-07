//
//  MediaPipeFaceLandmarkerService.swift
//  FaceRecognitionClient
//
//  Created on December 3, 2025.
//  Uses MediaPipe Face Landmarker for iOS - same as CoMa web app
//

import Foundation
import MediaPipeTasksVision
import UIKit

/// MediaPipe Face Landmarker Service
/// Provides face landmark detection using the same MediaPipe model as CoMa web app
/// This ensures consistent landmark positions for accurate face matching
class MediaPipeFaceLandmarkerService {
    static let shared = MediaPipeFaceLandmarkerService()

    private var faceLandmarker: FaceLandmarker?
    private var isInitialized = false

    // MediaPipe provides 478 landmarks (468 face mesh + 10 iris landmarks)
    // We extract the same key landmarks as CoMa web app

    // MARK: - Key Landmark Indices (same as CoMa web app)

    /// MediaPipe Face Mesh landmark indices for key facial features
    /// These indices match the CoMa web app's KEY_LANDMARKS
    private static let KEY_LANDMARKS: [String: Int] = [
        // Eyes (iris centers)
        "LEFT_EYE_CENTER": 468,  // Iris center
        "RIGHT_EYE_CENTER": 473,  // Iris center
        "LEFT_EYE_INNER": 133,
        "LEFT_EYE_OUTER": 33,
        "RIGHT_EYE_INNER": 362,
        "RIGHT_EYE_OUTER": 263,
        "LEFT_EYE_TOP": 159,
        "LEFT_EYE_BOTTOM": 145,
        "RIGHT_EYE_TOP": 386,
        "RIGHT_EYE_BOTTOM": 374,

        // Eyebrows
        "LEFT_EYEBROW_INNER": 107,
        "LEFT_EYEBROW_OUTER": 70,
        "RIGHT_EYEBROW_INNER": 336,
        "RIGHT_EYEBROW_OUTER": 300,

        // Nose
        "NOSE_TIP": 1,
        "NOSE_BOTTOM": 2,
        "NOSE_LEFT": 129,
        "NOSE_RIGHT": 358,
        "NOSE_BRIDGE": 6,

        // Mouth
        "UPPER_LIP_TOP": 13,
        "LOWER_LIP_BOTTOM": 14,
        "MOUTH_LEFT": 61,
        "MOUTH_RIGHT": 291,
        "UPPER_LIP_CENTER": 0,
        "LOWER_LIP_CENTER": 17,

        // Face contour
        "CHIN": 152,
        "LEFT_CHEEK": 234,
        "RIGHT_CHEEK": 454,
        "LEFT_EAR": 127,
        "RIGHT_EAR": 356,
        "FOREHEAD_CENTER": 10,

        // Jawline
        "JAW_LEFT": 172,
        "JAW_RIGHT": 397,
    ]

    /// Landmark type mapping - converts internal names to CoMa format
    /// Must match exactly with CoMa web app's LANDMARK_TYPE_MAP
    private static let LANDMARK_TYPE_MAP: [String: String] = [
        "LEFT_EYE_CENTER": "LEFT_EYE",
        "RIGHT_EYE_CENTER": "RIGHT_EYE",
        "LEFT_EYE_INNER": "LEFT_EYE_LEFT_CORNER",
        "LEFT_EYE_OUTER": "LEFT_EYE_RIGHT_CORNER",
        "RIGHT_EYE_INNER": "RIGHT_EYE_LEFT_CORNER",
        "RIGHT_EYE_OUTER": "RIGHT_EYE_RIGHT_CORNER",
        "LEFT_EYE_TOP": "LEFT_EYE_TOP_BOUNDARY",
        "LEFT_EYE_BOTTOM": "LEFT_EYE_BOTTOM_BOUNDARY",
        "RIGHT_EYE_TOP": "RIGHT_EYE_TOP_BOUNDARY",
        "RIGHT_EYE_BOTTOM": "RIGHT_EYE_BOTTOM_BOUNDARY",
        "LEFT_EYEBROW_INNER": "RIGHT_OF_LEFT_EYEBROW",
        "LEFT_EYEBROW_OUTER": "LEFT_OF_LEFT_EYEBROW",
        "RIGHT_EYEBROW_INNER": "LEFT_OF_RIGHT_EYEBROW",
        "RIGHT_EYEBROW_OUTER": "RIGHT_OF_RIGHT_EYEBROW",
        "NOSE_TIP": "NOSE_TIP",
        "NOSE_BOTTOM": "NOSE_BOTTOM_CENTER",
        "NOSE_LEFT": "NOSE_BOTTOM_LEFT",
        "NOSE_RIGHT": "NOSE_BOTTOM_RIGHT",
        "NOSE_BRIDGE": "MIDPOINT_BETWEEN_EYES",
        "UPPER_LIP_TOP": "UPPER_LIP",
        "LOWER_LIP_BOTTOM": "LOWER_LIP",
        "MOUTH_LEFT": "MOUTH_LEFT",
        "MOUTH_RIGHT": "MOUTH_RIGHT",
        "UPPER_LIP_CENTER": "MOUTH_CENTER",
        "CHIN": "CHIN_GNATHION",
        "LEFT_CHEEK": "LEFT_CHEEK_CENTER",
        "RIGHT_CHEEK": "RIGHT_CHEEK_CENTER",
        "LEFT_EAR": "LEFT_EAR_TRAGION",
        "RIGHT_EAR": "RIGHT_EAR_TRAGION",
        "FOREHEAD_CENTER": "FOREHEAD_GLABELLA",
        "JAW_LEFT": "CHIN_LEFT_GONION",
        "JAW_RIGHT": "CHIN_RIGHT_GONION",
    ]

    private init() {}

    // MARK: - Initialization

    /// Initialize the MediaPipe Face Landmarker
    /// Downloads and loads the face_landmarker model
    nonisolated func initialize() throws {
        guard !isInitialized else { return }

        print("🔧 Initializing MediaPipe Face Landmarker...")

        // Look for the model file in the bundle
        guard let modelPath = Bundle.main.path(forResource: "face_landmarker", ofType: "task")
        else {
            throw MediaPipeError.modelNotFound
        }

        // Configure options
        let options = FaceLandmarkerOptions()
        options.baseOptions.modelAssetPath = modelPath
        options.runningMode = .image
        options.numFaces = 1
        options.minFaceDetectionConfidence = 0.5
        options.minFacePresenceConfidence = 0.5
        options.minTrackingConfidence = 0.5

        // Create the face landmarker
        faceLandmarker = try FaceLandmarker(options: options)
        isInitialized = true

        print("✅ MediaPipe Face Landmarker initialized successfully")
    }

    // MARK: - Face Detection

    /// Detect face landmarks in an image using MediaPipe
    /// Returns encoding in the same format as CoMa web app
    func detectFaceLandmarks(in image: UIImage) throws -> MediaPipeFaceEncoding {
        // Initialize if needed
        if !isInitialized {
            try initialize()
        }

        guard let landmarker = faceLandmarker else {
            throw MediaPipeError.notInitialized
        }

        // Convert UIImage to MPImage
        let mpImage = try MPImage(uiImage: image)

        // Detect face landmarks
        let result = try landmarker.detect(image: mpImage)

        // Check if any face was detected
        guard let faceLandmarks = result.faceLandmarks.first, !faceLandmarks.isEmpty else {
            throw FaceRecognitionError.noFaceDetected
        }

        // Check for multiple faces
        if result.faceLandmarks.count > 1 {
            throw FaceRecognitionError.multipleFacesDetected
        }

        let imageWidth = Double(image.size.width)
        let imageHeight = Double(image.size.height)

        print(
            "📸 MediaPipe detected \(faceLandmarks.count) landmarks in \(Int(imageWidth))x\(Int(imageHeight)) image"
        )

        // Extract key landmarks (matching CoMa web app format)
        var keyLandmarks: [MediaPipeLandmark] = []

        for (name, index) in MediaPipeFaceLandmarkerService.KEY_LANDMARKS {
            if index < faceLandmarks.count {
                let lm = faceLandmarks[index]
                let type = MediaPipeFaceLandmarkerService.LANDMARK_TYPE_MAP[name] ?? name

                // Convert normalized coordinates to pixel coordinates
                // MediaPipe returns normalized [0,1] coordinates
                keyLandmarks.append(
                    MediaPipeLandmark(
                        type: type,
                        x: Double(lm.x) * imageWidth,
                        y: Double(lm.y) * imageHeight,
                        z: Double(lm.z) * imageWidth  // z is relative to width in MediaPipe
                    ))
            }
        }

        print("✅ Extracted \(keyLandmarks.count) key landmarks")

        // Store all 478 landmarks for advanced matching (optional)
        var allLandmarks: [MediaPipePoint3D] = []
        for lm in faceLandmarks {
            allLandmarks.append(
                MediaPipePoint3D(
                    x: Double(lm.x) * imageWidth,
                    y: Double(lm.y) * imageHeight,
                    z: Double(lm.z) * imageWidth
                ))
        }

        // Calculate bounding box from face landmarks
        let boundingBox = calculateBoundingBox(
            faceLandmarks, imageWidth: imageWidth, imageHeight: imageHeight)

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return MediaPipeFaceEncoding(
            landmarks: keyLandmarks,
            allLandmarks: allLandmarks,
            boundingBox: boundingBox,
            confidence: 0.95,  // MediaPipe doesn't provide confidence, use high value
            encoderType: "mediapipe",  // Mark as MediaPipe encoding for compatibility check
            timestamp: isoFormatter.string(from: Date())
        )
    }

    /// Calculate bounding box from landmarks
    private func calculateBoundingBox(
        _ landmarks: [NormalizedLandmark], imageWidth: Double, imageHeight: Double
    ) -> [MediaPipeBoundingBoxPoint] {
        var minX = Double.infinity
        var maxX = -Double.infinity
        var minY = Double.infinity
        var maxY = -Double.infinity

        for lm in landmarks {
            let x = Double(lm.x) * imageWidth
            let y = Double(lm.y) * imageHeight
            minX = min(minX, x)
            maxX = max(maxX, x)
            minY = min(minY, y)
            maxY = max(maxY, y)
        }

        // Add padding
        let paddingX = (maxX - minX) * 0.1
        let paddingY = (maxY - minY) * 0.1

        return [
            MediaPipeBoundingBoxPoint(x: max(0, minX - paddingX), y: max(0, minY - paddingY)),
            MediaPipeBoundingBoxPoint(
                x: min(imageWidth, maxX + paddingX), y: max(0, minY - paddingY)),
            MediaPipeBoundingBoxPoint(
                x: min(imageWidth, maxX + paddingX), y: min(imageHeight, maxY + paddingY)),
            MediaPipeBoundingBoxPoint(
                x: max(0, minX - paddingX), y: min(imageHeight, maxY + paddingY)),
        ]
    }
}

// MARK: - Errors

enum MediaPipeError: Error, LocalizedError {
    case modelNotFound
    case notInitialized
    case detectionFailed(String)

    var errorDescription: String? {
        switch self {
        case .modelNotFound:
            return "MediaPipe face_landmarker.task model not found in bundle"
        case .notInitialized:
            return "MediaPipe Face Landmarker not initialized"
        case .detectionFailed(let message):
            return "Face detection failed: \(message)"
        }
    }
}
