//
//  CameraViewModel.swift
//  FaceRecognitionClient
//
//  Created on November 28, 2025.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation

enum CameraStatus: Equatable {
    case scanning
    case faceDetected
    case processing
    case success(String)  // Student name
    case failed(String)   // Error message
    
    var icon: String {
        switch self {
        case .scanning: return "viewfinder"
        case .faceDetected: return "face.smiling"
        case .processing: return "hourglass"
        case .success: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
    
    var title: String {
        switch self {
        case .scanning: return "Scanning..."
        case .faceDetected: return "Face Detected"
        case .processing: return "Processing..."
        case .success: return "Access OK"
        case .failed: return "Access FAILED"
        }
    }
    
    var message: String {
        switch self {
        case .scanning: return "Position face in camera"
        case .faceDetected: return "Hold still..."
        case .processing: return "Recognizing face"
        case .success(let name): return "Welcome, \(name)!"
        case .failed(let error): return error
        }
    }
    
    var color: Color {
        switch self {
        case .scanning: return .blue
        case .faceDetected: return .blue
        case .processing: return .orange
        case .success: return .green
        case .failed: return .red
        }
    }
}

class CameraViewModel: ObservableObject {
    @Published var status: CameraStatus = .scanning
    @Published var lastCheckTime: String = "-"
    @Published var studentName: String = "-"
    @Published var processingTime: String = "-"
    @Published var showFaceBox: Bool = false
    @Published var errorMessage: String?
    @Published var isCameraReady: Bool = false
    @Published var isCameraStarted: Bool = false
    @Published var isSimulator: Bool = false
    @Published var savedImage: UIImage?
    @Published var showImagePicker: Bool = false
    @Published var statusLog: [String] = []
    
    private let firebaseService = FirebaseService.shared
    private let faceRecognitionService = FaceRecognitionService.shared
    let cameraService = CameraService()
    
    private var students: [Student] = []
    private var staff: Staff?
    private var school: School?
    private var isProcessing: Bool = false
    private var frameCounter: Int = 0
    private var uploadStartTime: Date?
    
    // MARK: - Lifecycle
    
    func loadData(staff: Staff, school: School) async {
        self.staff = staff
        self.school = school
        
        do {
            students = try await firebaseService.loadStudents(schoolId: school.id)
            faceRecognitionService.loadStudentData(students)
            
            print("✅ Data loaded with \(students.count) students. Camera ready to start.")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to load students: \(error)")
        }
    }
    
    func manualStartCamera() async {
        isCameraStarted = true
        
        do {
            // Setup camera
            try await setupCamera()
            
            status = .scanning
            print("✅ Camera started with \(students.count) students")
        } catch {
            errorMessage = error.localizedDescription
            isCameraStarted = false
            print("❌ Failed to start camera: \(error)")
        }
    }
    
    // MARK: - Camera Setup
    
    private func setupCamera() async throws {
        // Check authorization
        cameraService.checkAuthorization()
        
        guard cameraService.isAuthorized else {
            throw FaceRecognitionError.cameraAccessDenied
        }
        
        // Setup camera session
        try cameraService.setupSession()
        
        // Set frame capture callback
        cameraService.onFrameCapture = { [weak self] image in
            self?.processFrame(image)
        }
        
        // Start camera session
        cameraService.startSession()
        
        await MainActor.run {
            self.isCameraReady = true
            #if targetEnvironment(simulator)
            self.isSimulator = true
            #endif
        }
        
        print("✅ Camera setup complete")
    }
    
    func stopCamera() {
        cameraService.stopSession()
        isCameraReady = false
    }
    
    // MARK: - Face Recognition
    
    func processFrame(_ image: UIImage) {
        // Throttle processing - only process every 30th frame (about once per second)
        frameCounter += 1
        guard frameCounter % 30 == 0 else { return }
        
        // Don't process if already processing
        guard !isProcessing else { return }
        guard status == .scanning || status == .faceDetected else { return }
        
        Task {
            await performFaceRecognition(image)
        }
    }
    
    private func performFaceRecognition(_ image: UIImage) async {
        isProcessing = true
        showFaceBox = true
        
        // Clear previous logs
        await MainActor.run {
            statusLog.removeAll()
        }
        
        do {
            // Save the captured image to Firestore for testing
            if let staffId = staff?.id, let schoolId = school?.id {
                // Start timer
                uploadStartTime = Date()
                
                // Step 1: Save to Firestore
                status = .processing
                await addLog("📤 Step 1: Starting image save...")
                print("📤 Saving picture to Firestore...")
                
                await addLog("🔄 Converting image to JPEG format...")
                let pictureId = try await firebaseService.saveLoginPicture(image: image, staffId: staffId, schoolId: schoolId)
                await addLog("✅ Picture saved successfully")
                await addLog("🆔 Document ID: \(pictureId)")
                await addLog("📍 Path: /schools/\(schoolId)/login-pictures/\(pictureId)")
                print("✅ Picture saved with ID: \(pictureId)")
                
                // Step 2: Retrieve from Firestore to verify
                await addLog("📥 Step 2: Retrieving picture to verify...")
                print("📥 Retrieving picture from Firestore to verify...")
                let retrievedData = try await firebaseService.loadLoginPicture(pictureId: pictureId, schoolId: schoolId)
                await addLog("✅ Document retrieved from Firestore")
                
                if let imageDataUri = retrievedData["imageData"] as? String {
                    let dataLength = imageDataUri.count
                    await addLog("✅ Image data found (\(dataLength) chars)")
                    print("✅ Picture retrieved successfully! Data URI length: \(dataLength) characters")
                    print("✅ Verification complete - Save and retrieve working!")
                    print("📍 Path: /schools/\(schoolId)/login-pictures/\(pictureId)")
                    
                    // Convert data URI back to UIImage to display
                    await addLog("🔄 Step 3: Converting to display format...")
                    if let retrievedImage = dataURIToImage(imageDataUri) {
                        await MainActor.run {
                            self.savedImage = retrievedImage
                        }
                        await addLog("✅ Image ready to display")
                        print("✅ Retrieved image converted and ready to display")
                        
                        // Calculate and display total processing time
                        if let startTime = uploadStartTime {
                            let elapsed = Date().timeIntervalSince(startTime)
                            let formattedTime = String(format: "%.2f seconds", elapsed)
                            await MainActor.run {
                                self.processingTime = formattedTime
                            }
                            await addLog("⏱️ Total time: \(formattedTime)")
                        }
                        
                        // Auto-hide image after 3 seconds
                        Task {
                            try? await Task.sleep(nanoseconds: 3_000_000_000)
                            await MainActor.run {
                                self.savedImage = nil
                            }
                        }
                    }
                    
                    await addLog("🎉 All steps completed successfully!")
                    // Show success briefly
                    status = .success("Connection Verified")
                    
                    // For simulator/testing mode, stop here - don't run face recognition
                    if isSimulator {
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        await resetAfterDelay(seconds: 0.5)
                        isProcessing = false
                        return
                    }
                    
                    try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                } else {
                    await addLog("❌ Error: imageData field missing")
                    print("⚠️ Retrieved data but imageData field missing")
                    status = .failed("Verification failed")
                    await resetAfterDelay(seconds: 2.0)
                    isProcessing = false
                    return
                }
            }
            
            // Only run face recognition on physical devices with real camera
            if !isSimulator {
                // Detect face in the image
                let match = try await faceRecognitionService.detectAndRecognizeFace(in: image)
                
                if match.isValidMatch {
                    await handleSuccessfulMatch(match)
                } else {
                    status = .failed("Low confidence match")
                    await resetAfterDelay(seconds: 2.0)
                }
            }
            
        } catch let error as FaceRecognitionError {
            // Show face detected status even if recognition fails (for testing)
            if error == .noMatch || error == .lowConfidence {
                status = .faceDetected
                showFaceBox = true
                await resetAfterDelay(seconds: 2.0)
            } else {
                let errorMsg = error.errorDescription ?? "Unknown error"
                await addLog("❌ FAILED: \(errorMsg)")
                status = .failed(errorMsg)
                showFaceBox = false
                await MainActor.run {
                    self.processingTime = "Failed"
                }
                await resetAfterDelay(seconds: 3.0)
            }
        } catch {
            // Handle Firebase/Firestore errors
            let errorMsg = error.localizedDescription
            await addLog("❌ ERROR: \(errorMsg)")
            
            // Check if it's a Firestore size error
            if errorMsg.contains("longer than") || errorMsg.contains("1048487") {
                await addLog("💡 Image too large for Firestore (>1MB)")
                await addLog("💡 Try using a smaller image")
                status = .failed("Image too large")
            } else {
                status = .failed("Upload failed")
            }
            
            await MainActor.run {
                self.errorMessage = errorMsg
                self.processingTime = "Failed"
            }
            showFaceBox = false
            print("❌ Error: \(errorMsg)")
        }
        
        isProcessing = false
    }
    
    // MARK: - Handle Match
    
    private func handleSuccessfulMatch(_ match: FaceMatchResult) async {
        status = .success(match.student.fullName)
        
        // Update details
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .medium
        lastCheckTime = dateFormatter.string(from: match.matchTimestamp)
        studentName = match.student.fullName
        processingTime = String(format: "%.2fs", match.processingTime)
        
        // Provide haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Record attendance
        if let schoolId = school?.id {
            do {
                try await firebaseService.recordAttendance(schoolId: schoolId, studentId: match.student.id)
                
                // Send WhatsApp notification (if parent contact available)
                if let parentContact = match.student.parentContact {
                    sendWhatsAppNotification(
                        to: parentContact,
                        studentName: match.student.fullName,
                        parentName: match.student.parentName
                    )
                }
            } catch {
                print("⚠️ Failed to record attendance: \(error)")
            }
        }
        
        // Reset after 3 seconds
        await resetAfterDelay(seconds: 3.0)
    }
    
    // MARK: - WhatsApp Integration
    
    private func sendWhatsAppNotification(to phoneNumber: String, studentName: String, parentName: String?) {
        let greeting = parentName != nil ? "Hello \(parentName!)!" : "Hello!"
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let currentTime = timeFormatter.string(from: Date())
        
        let message = """
        ✅ Attendance Confirmed
        
        \(greeting) Your child \(studentName) has successfully checked in at the tuition center.
        
        Time: \(currentTime)
        Date: \(Date().formatted(date: .long, time: .omitted))
        
        Thank you!
        - \(school?.name ?? "Tuition Center")
        """
        
        // Clean phone number
        let cleanNumber = phoneNumber.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        
        // URL encode message
        guard let encodedMessage = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            print("⚠️ Failed to encode WhatsApp message")
            return
        }
        
        // Try WhatsApp URL scheme
        let whatsappURL = "whatsapp://send?phone=\(cleanNumber)&text=\(encodedMessage)"
        
        if let url = URL(string: whatsappURL), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            print("📱 WhatsApp notification sent to \(phoneNumber)")
        } else {
            // Fallback to web WhatsApp
            let webURL = "https://wa.me/\(cleanNumber)?text=\(encodedMessage)"
            if let webUrl = URL(string: webURL) {
                UIApplication.shared.open(webUrl)
                print("📱 WhatsApp web notification sent to \(phoneNumber)")
            } else {
                print("⚠️ WhatsApp not available")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func resetAfterDelay(seconds: Double) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        status = .scanning
        showFaceBox = false
    }
    
    func reset() {
        status = .scanning
        showFaceBox = false
        lastCheckTime = "-"
        studentName = "-"
        processingTime = "-"
        errorMessage = nil
        isProcessing = false
        frameCounter = 0
    }
    
    // MARK: - Manual Testing (Simulator)
    
    func manualCapture() async {
        guard !isProcessing else { return }
        
        print("📸 Manual capture triggered")
        
        // Generate test image
        cameraService.capturePhoto()
        
        // Wait a bit for image generation
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Use the captured image
        if let testImage = cameraService.capturedImage {
            await performFaceRecognition(testImage)
        } else {
            print("⚠️ No test image available")
        }
    }
    
    func processPickedImage(_ image: UIImage) async {
        guard !isProcessing else { return }
        print("🖼️ Processing picked image")
        
        // Clear previous logs and reset state
        await MainActor.run {
            statusLog.removeAll()
            processingTime = "-"
            savedImage = nil
        }
        
        await performFaceRecognition(image)
    }
    
    // MARK: - Helper Functions
    
    private func dataURIToImage(_ dataURI: String) -> UIImage? {
        // Remove the data URI prefix
        guard let base64String = dataURI.components(separatedBy: ",").last,
              let imageData = Data(base64Encoded: base64String) else {
            print("⚠️ Failed to decode base64 from data URI")
            return nil
        }
        
        return UIImage(data: imageData)
    }
    
    private func addLog(_ message: String) async {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)"
        await MainActor.run {
            statusLog.append(logMessage)
            // Keep only last 15 messages to show full flow
            if statusLog.count > 15 {
                statusLog.removeFirst()
            }
        }
        print("📊 Log: \(logMessage)")
    }
    
    deinit {
        stopCamera()
    }
}
