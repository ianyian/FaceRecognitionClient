# iOS Client Integration Guide

## Overview

This document provides the complete API reference, data structures, and implementation guide for the iOS face recognition client application. The iOS app is responsible for:

1. **Downloading face data** from Firebase Firestore to local storage
2. **Performing local face detection** using device Vision framework
3. **Matching detected faces** against downloaded face encodings
4. **Triggering WhatsApp notification** to parent upon successful recognition

---

## Firebase Configuration

### Connection Details

```swift
// Firebase Configuration
let firebaseConfig = [
    "projectId": "studio-4796520355-68573",
    "appId": "1:749344629546:web:703d99a87371cab385f453",
    "apiKey": "AIzaSyD1v8MYDb8HJ2fosj9H8eytWgmzWs-nwa8",
    "authDomain": "studio-4796520355-68573.firebaseapp.com",
    "messagingSenderId": "749344629546"
]
```

### School ID

```swift
let schoolId = "main-tuition-center"
```

### Firestore Database Structure

```
schools/
  └── {schoolId}/
      ├── students/           # Student records
      │   └── {studentId}/
      │       └── faceSamples/  # Original face sample images
      ├── faceData/           # ⭐ Face encodings for recognition
      │   └── {faceDataId}
      └── faceDataMeta/       # Version control
          └── version
```

---

## Data Models

### FaceDataDocument (Primary - for face recognition)

```swift
struct FaceDataDocument: Codable {
    // Primary identification
    let faceDataId: String        // Auto-generated unique ID
    let studentId: String         // Links to student document
    let studentDocId: String      // Firestore document ID

    // Face sample details
    let faceSampleDocId: String   // Original faceSample document ID
    let sampleIndex: Int          // Order index (0, 1, 2...)

    // Core face data - ⭐ IMPORTANT FOR MATCHING
    let encoding: String          // JSON string with face landmarks
    let originalImage: String     // Data URI (base64) for display
    let faceConfidence: Double    // Detection confidence (0-1)

    // Version control
    let version: Int              // Global version number
    let lastUpdated: Date         // Last modification timestamp

    // Student metadata
    let studentName: String       // Full name for display
    let className: String?        // Optional class filter

    // Audit trail
    let createdAt: Date
    let updatedAt: Date
    let createdBy: String         // Staff UID
    let updatedBy: String         // Staff UID

    // Sync tracking
    let isOrphaned: Bool?         // True if source no longer exists
}
```

### Face Encoding Structure (JSON inside `encoding` field)

```swift
struct FaceEncoding: Codable {
    let landmarks: [FaceLandmark]
    let boundingBox: [BoundingBoxPoint]
    let confidence: Double
    let timestamp: String
}

struct FaceLandmark: Codable {
    let type: String    // e.g., "LEFT_EYE", "RIGHT_EYE", "NOSE_TIP"
    let x: Double       // X coordinate
    let y: Double       // Y coordinate
    let z: Double       // Z coordinate (depth)
}

struct BoundingBoxPoint: Codable {
    let x: Int
    let y: Int
}
```

### Available Landmark Types (34 total)

```swift
enum LandmarkType: String {
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
```

### Student Model

```swift
struct Student: Codable {
    let id: String
    let firstName: String
    let lastName: String
    let `class`: String           // Note: 'class' is reserved, use backticks
    let status: String            // "Registered" | "Pending" | "Deleted"
    let registrationDate: String
    let avatarUrl: String?
}
```

### Parent Model (for WhatsApp notification)

```swift
struct Parent: Codable {
    let id: String
    let firstName: String
    let lastName: String
    let phoneNumber: String       // Format: international (e.g., "+60123456789")
}
```

---

## API Endpoints & Queries

### 1. Download Face Data (⭐ Primary API)

**Purpose**: Download all face encodings for registered students to local storage.

**Firestore Query**:

```swift
// Step 1: Get registered student IDs
let studentsRef = db.collection("schools/\(schoolId)/students")
let registeredQuery = studentsRef.whereField("status", isEqualTo: "Registered")

// Step 2: Get face data for registered students only
let faceDataRef = db.collection("schools/\(schoolId)/faceData")
let faceDataQuery = faceDataRef.order(by: "studentId")
```

**Filter Logic** (client-side):

```swift
// Only include face data where studentId is in registeredStudentIds set
// AND encoding is valid (not empty, not starting with "encoded_")
func isValidEncoding(_ encoding: String) -> Bool {
    return !encoding.isEmpty &&
           !encoding.hasPrefix("encoded_") &&
           encoding.contains("landmarks")
}
```

**Response Structure**:

```json
{
  "faceData": [
    {
      "faceDataId": "abc123_0_1701388800000",
      "studentId": "abc123",
      "studentName": "John Doe",
      "className": "Class1",
      "encoding": "{\"landmarks\":[...],\"confidence\":0.99}",
      "originalImage": "data:image/jpeg;base64,...",
      "faceConfidence": 0.99,
      "version": 1
    }
  ],
  "version": 5,
  "lastUpdated": "2025-12-01T10:00:00Z",
  "totalRecords": 15
}
```

### 2. Get Version Info

**Purpose**: Check if local cache needs update.

**Firestore Path**:

```
schools/{schoolId}/faceDataMeta/version
```

**Document Structure**:

```swift
struct FaceDataVersion: Codable {
    let currentVersion: Int
    let lastUpdated: Date
    let totalRecords: Int
    let studentsCount: Int
}
```

### 3. Get Student Details

**Firestore Path**:

```
schools/{schoolId}/students/{studentId}
```

### 4. Get Parent Phone Number

**Firestore Path**:

```
schools/{schoolId}/students/{studentId}
// Parent phone is stored in student document or related parent collection
```

---

## iOS Implementation Guide

### 1. Download Face Data Button

```swift
class FaceDataDownloader {
    private let db = Firestore.firestore()
    private let schoolId = "main-tuition-center"
    private let localCacheKey = "facedata_cache"

    /// Download button action - clears cache and downloads fresh data
    func downloadFaceData(completion: @escaping (Result<Int, Error>) -> Void) {
        // Step 1: Clear existing local cache
        clearLocalCache()

        // Step 2: Fetch registered students
        fetchRegisteredStudentIds { [weak self] result in
            switch result {
            case .success(let registeredIds):
                // Step 3: Download and filter face data
                self?.fetchFaceData(registeredIds: registeredIds, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func clearLocalCache() {
        UserDefaults.standard.removeObject(forKey: localCacheKey)
        print("🗑️ Local face data cache cleared")
    }

    private func fetchRegisteredStudentIds(completion: @escaping (Result<Set<String>, Error>) -> Void) {
        db.collection("schools/\(schoolId)/students")
            .whereField("status", isEqualTo: "Registered")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                var ids = Set<String>()
                snapshot?.documents.forEach { ids.insert($0.documentID) }
                print("✅ Found \(ids.count) registered students")
                completion(.success(ids))
            }
    }

    private func fetchFaceData(registeredIds: Set<String>, completion: @escaping (Result<Int, Error>) -> Void) {
        db.collection("schools/\(schoolId)/faceData")
            .order(by: "studentId")
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                var faceDataList: [FaceDataDocument] = []

                snapshot?.documents.forEach { doc in
                    let data = doc.data()
                    guard let studentId = data["studentId"] as? String,
                          registeredIds.contains(studentId),
                          let encoding = data["encoding"] as? String,
                          self?.isValidEncoding(encoding) == true else {
                        return
                    }

                    // Parse and add to list
                    if let faceData = self?.parseFaceData(doc) {
                        faceDataList.append(faceData)
                    }
                }

                // Save to local storage
                self?.saveToLocalCache(faceDataList)
                print("✅ Downloaded \(faceDataList.count) face records")
                completion(.success(faceDataList.count))
            }
    }

    private func isValidEncoding(_ encoding: String) -> Bool {
        return !encoding.isEmpty &&
               !encoding.hasPrefix("encoded_") &&
               encoding.contains("landmarks")
    }

    private func saveToLocalCache(_ faceData: [FaceDataDocument]) {
        // Save to UserDefaults, Core Data, or local file
        if let encoded = try? JSONEncoder().encode(faceData) {
            UserDefaults.standard.set(encoded, forKey: localCacheKey)
        }
    }
}
```

### 2. Local Face Detection & Matching

```swift
import Vision

class LocalFaceRecognition {
    private let confidenceThreshold: Double = 0.3  // Match threshold

    /// Recognize face from camera image
    func recognizeFace(from image: UIImage, completion: @escaping (Result<RecognitionResult, Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(RecognitionError.invalidImage))
            return
        }

        // Step 1: Detect face landmarks using Vision framework
        let request = VNDetectFaceLandmarksRequest { [weak self] request, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let observations = request.results as? [VNFaceObservation],
                  let face = observations.first else {
                completion(.failure(RecognitionError.noFaceDetected))
                return
            }

            // Step 2: Convert to encoding format
            let encoding = self?.convertToEncoding(face)

            // Step 3: Match against local database
            self?.matchAgainstLocalData(encoding: encoding, completion: completion)
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
    }

    /// Convert Vision landmarks to encoding format compatible with stored data
    private func convertToEncoding(_ face: VNFaceObservation) -> FaceEncoding {
        var landmarks: [FaceLandmark] = []

        if let allPoints = face.landmarks?.allPoints {
            // Map Vision landmarks to our format
            // Note: You need to map VNFaceLandmarks2D to our landmark types
        }

        return FaceEncoding(
            landmarks: landmarks,
            boundingBox: [],
            confidence: Double(face.confidence),
            timestamp: ISO8601DateFormatter().string(from: Date())
        )
    }

    /// Match encoding against local face data
    private func matchAgainstLocalData(encoding: FaceEncoding?, completion: @escaping (Result<RecognitionResult, Error>) -> Void) {
        guard let encoding = encoding else {
            completion(.failure(RecognitionError.encodingFailed))
            return
        }

        // Load from local cache
        guard let cachedData = UserDefaults.standard.data(forKey: "facedata_cache"),
              let faceDataList = try? JSONDecoder().decode([FaceDataDocument].self, from: cachedData) else {
            completion(.failure(RecognitionError.noCacheData))
            return
        }

        var bestMatch: (studentId: String, studentName: String, confidence: Double)?

        for faceData in faceDataList {
            guard let storedEncoding = try? JSONDecoder().decode(FaceEncoding.self, from: Data(faceData.encoding.utf8)) else {
                continue
            }

            let similarity = calculateSimilarity(encoding, storedEncoding)

            if similarity > confidenceThreshold {
                if bestMatch == nil || similarity > bestMatch!.confidence {
                    bestMatch = (faceData.studentId, faceData.studentName, similarity)
                }
            }
        }

        if let match = bestMatch {
            completion(.success(RecognitionResult(
                isMatch: true,
                studentId: match.studentId,
                studentName: match.studentName,
                confidence: match.confidence
            )))
        } else {
            completion(.success(RecognitionResult(isMatch: false, studentId: nil, studentName: nil, confidence: 0)))
        }
    }

    /// Calculate similarity between two face encodings
    private func calculateSimilarity(_ encoding1: FaceEncoding, _ encoding2: FaceEncoding) -> Double {
        var totalDistance: Double = 0
        var matchingLandmarks = 0

        for lm1 in encoding1.landmarks {
            if let lm2 = encoding2.landmarks.first(where: { $0.type == lm1.type }) {
                let distance = sqrt(
                    pow(lm1.x - lm2.x, 2) +
                    pow(lm1.y - lm2.y, 2) +
                    pow(lm1.z - lm2.z, 2)
                )
                totalDistance += distance
                matchingLandmarks += 1
            }
        }

        guard matchingLandmarks > 0 else { return 0 }

        let averageDistance = totalDistance / Double(matchingLandmarks)
        let similarity = max(0, 1 - averageDistance / 100)  // Normalize

        return similarity
    }
}

struct RecognitionResult {
    let isMatch: Bool
    let studentId: String?
    let studentName: String?
    let confidence: Double
}

enum RecognitionError: Error {
    case invalidImage
    case noFaceDetected
    case encodingFailed
    case noCacheData
}
```

### 3. WhatsApp Notification Trigger

```swift
class WhatsAppNotifier {

    /// Send WhatsApp message to parent after successful recognition
    func notifyParent(studentId: String, studentName: String) {
        // Fetch parent phone number from Firestore
        fetchParentPhone(studentId: studentId) { [weak self] result in
            switch result {
            case .success(let phoneNumber):
                self?.sendWhatsAppMessage(to: phoneNumber, studentName: studentName)
            case .failure(let error):
                print("❌ Failed to get parent phone: \(error)")
            }
        }
    }

    private func fetchParentPhone(studentId: String, completion: @escaping (Result<String, Error>) -> Void) {
        let db = Firestore.firestore()
        db.collection("schools/main-tuition-center/students").document(studentId)
            .getDocument { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                // Get parent phone from student document or related parent
                if let parentPhone = snapshot?.data()?["parentPhone"] as? String {
                    completion(.success(parentPhone))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No parent phone found"])))
                }
            }
    }

    private func sendWhatsAppMessage(to phoneNumber: String, studentName: String) {
        let message = "✅ Attendance confirmed: \(studentName) has arrived at the tuition center."
        let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        // Format: remove any non-numeric characters, ensure country code
        let cleanPhone = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()

        if let url = URL(string: "https://wa.me/\(cleanPhone)?text=\(encodedMessage)") {
            DispatchQueue.main.async {
                UIApplication.shared.open(url)
            }
        }
    }
}
```

---

## Complete Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                         iOS App Flow                                 │
└─────────────────────────────────────────────────────────────────────┘

1. DOWNLOAD FACE DATA (One-time or periodic)
   ┌──────────────┐     ┌─────────────────┐     ┌──────────────────┐
   │ Tap Download │────▶│ Fetch from      │────▶│ Save to Local    │
   │ Button       │     │ Firestore       │     │ Storage          │
   └──────────────┘     └─────────────────┘     └──────────────────┘
                               │
                               ▼
                        ┌─────────────────┐
                        │ Filter:         │
                        │ - Registered    │
                        │ - Valid encoding│
                        └─────────────────┘

2. FACE RECOGNITION (Each attendance check)
   ┌──────────────┐     ┌─────────────────┐     ┌──────────────────┐
   │ Capture      │────▶│ Detect Face     │────▶│ Extract          │
   │ Camera Image │     │ (Vision API)    │     │ Landmarks        │
   └──────────────┘     └─────────────────┘     └──────────────────┘
                                                        │
                                                        ▼
   ┌──────────────┐     ┌─────────────────┐     ┌──────────────────┐
   │ Display      │◀────│ Calculate       │◀────│ Load Local       │
   │ Result       │     │ Similarity      │     │ Face Data        │
   └──────────────┘     └─────────────────┘     └──────────────────┘
          │
          ▼ (If Match Found)
   ┌──────────────┐     ┌─────────────────┐
   │ Trigger      │────▶│ Open WhatsApp   │
   │ Notification │     │ to Parent       │
   └──────────────┘     └─────────────────┘
```

---

## Important Notes

### Confidence Thresholds

- **Recognition threshold**: `0.3` (30%) - Minimum similarity for a match
- **Face detection confidence**: `0.99` - Google Vision confidence

### Data Validation Rules

1. **Skip encodings that**:
   - Are empty or whitespace
   - Start with `"encoded_"` (placeholder/corrupted)
   - Don't contain `"landmarks"` key
2. **Only download for**:
   - Students with `status == "Registered"`

### Offline Capability

- Face data must be cached locally for offline recognition
- Periodic sync recommended to get updated student data
- Version check can determine if re-download is needed

### Security Considerations

- Firebase API key is restricted to specific domains/apps
- Student face data should be encrypted at rest on device
- Consider implementing certificate pinning

---

## Version History

| Version | Date       | Changes               |
| ------- | ---------- | --------------------- |
| 1.0     | 2025-12-01 | Initial documentation |

---

## Contact

For API issues or questions, contact the backend development team.
