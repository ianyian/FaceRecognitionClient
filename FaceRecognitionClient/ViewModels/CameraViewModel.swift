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
    @Published var capturedImage: UIImage?  // Image being processed (shown during recognition)
    @Published var showImagePicker: Bool = false
    @Published var statusLog: [String] = []
    @Published var cacheStatus: FaceDataCacheStatus = .empty
    @Published var showResultPopup: Bool = false  // Show result popup after detection
    @Published var isPaused: Bool = false          // Pause camera capture until user confirms
    
    private let firebaseService = FirebaseService.shared
    private let faceRecognitionService = FaceRecognitionService.shared
    private let cacheService = FaceDataCacheService.shared
    private let settingsService = SettingsService.shared
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
        
        // Load cache status
        await MainActor.run {
            reloadCache()
        }
        
        do {
            students = try await firebaseService.loadStudents(schoolId: school.id)
            faceRecognitionService.loadStudentData(students)
            
            print("✅ Data loaded with \(students.count) students. Camera ready to start.")
            print("📊 Cache status: \(cacheStatus.hasCache ? "\(cacheStatus.recordCount) records" : "empty")")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to load students: \(error)")
        }
    }
    
    func reloadCache() {
        cacheService.reloadFromDisk()
        cacheStatus = cacheService.getCacheStatus()
        print("📊 Cache reloaded: \(cacheStatus.hasCache ? "\(cacheStatus.recordCount) records from \(cacheStatus.studentCount) students" : "empty")")
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
    
    // Store the latest frame from camera (for manual capture)
    private var latestFrame: UIImage?
    
    func processFrame(_ image: UIImage) {
        // Just store the latest frame - no auto-capture
        // User will tap to capture manually
        latestFrame = image
    }
    
    /// User tapped screen to capture photo
    func manualCapture() {
        // Don't capture if paused or already processing
        guard !isPaused else { return }
        guard !isProcessing else { return }
        guard status == .scanning || status == .faceDetected else { return }
        
        guard let image = latestFrame else {
            print("⚠️ No frame available to capture")
            return
        }
        
        // Haptic feedback for capture
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        Task {
            await performFaceRecognition(image)
        }
    }
    
    private func performFaceRecognition(_ image: UIImage) async {
        isProcessing = true
        showFaceBox = true
        
        // FIRST: Show the captured image immediately
        await MainActor.run {
            self.capturedImage = image
            self.status = .faceDetected
        }
        
        // Clear previous logs
        await MainActor.run {
            statusLog.removeAll()
        }
        
        await addLog("📸 Photo captured!")
        
        // Brief pause to let user see the captured image
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        await MainActor.run {
            self.status = .processing
        }
        await addLog("🔍 Starting face recognition...")
        
        do {
            // Start timer
            uploadStartTime = Date()
            
            // Run face recognition directly (no Firebase upload)
            // Check if we have cache data
            if cacheStatus.hasCache {
                // Use local face matching
                await addLog("🔍 Detecting face landmarks...")
                let detectedEncoding = try await faceRecognitionService.detectFaceLandmarks(in: image)
                await addLog("✅ Detected \(detectedEncoding.landmarks.count) landmarks")
                
                await addLog("🔄 Matching against \(cacheStatus.recordCount) cached samples...")
                let threshold = settingsService.matchThreshold
                await addLog("⚙️ Threshold: \(String(format: "%.0f%%", threshold * 100))")
                
                let matchResult = faceRecognitionService.matchFaceAgainstLocalCache(detectedEncoding)
                
                // Always show the best similarity score for debugging
                await addLog("📊 Best score: \(matchResult.bestSimilarityPercentage)")
                if let candidateName = matchResult.bestCandidateName {
                    await addLog("👤 Best candidate: \(candidateName)")
                }
                
                if let match = matchResult.match {
                    await addLog("✅ Match: \(match.studentName) (\(match.similarityPercentage))")
                    await handleLocalMatch(match)
                } else {
                    await addLog("❌ No match above threshold (\(matchResult.bestSimilarityPercentage) < \(String(format: "%.0f%%", threshold * 100)))")
                    status = .failed("Face not recognized")
                    // Show popup and pause for user confirmation
                    await showResultAndPause()
                }
            } else {
                // Fall back to cloud matching (legacy)
                await addLog("⚠️ No local cache, using cloud matching...")
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
            // Handle Firebase/Firestore errors and Vision framework errors
            let errorMsg = error.localizedDescription
            await addLog("❌ ERROR: \(errorMsg)")
            
            // Check if it's a Vision framework simulator error
            if errorMsg.contains("inference context") || errorMsg.contains("CoreML") || errorMsg.contains("ANE") {
                await addLog("⚠️ Vision ML error in Simulator")
                await addLog("💡 This is a known iOS Simulator limitation")
                await addLog("💡 Face detection ML models may not work in Simulator")
                await addLog("💡 Please test on a real device for full functionality")
                status = .failed("Simulator ML limitation")
            }
            // Check if it's a Firestore size error
            else if errorMsg.contains("longer than") || errorMsg.contains("1048487") {
                await addLog("💡 Image too large for Firestore (>1MB)")
                await addLog("💡 Try using a smaller image")
                status = .failed("Image too large")
            } else {
                status = .failed("Recognition failed")
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
    
    private func handleLocalMatch(_ match: LocalFaceMatchResult) async {
        status = .success(match.studentName)
        
        // Update details
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .medium
        lastCheckTime = dateFormatter.string(from: match.matchTimestamp)
        studentName = "\(match.studentName) (\(match.similarityPercentage))"
        
        // Calculate processing time
        if let startTime = uploadStartTime {
            let elapsed = Date().timeIntervalSince(startTime)
            processingTime = String(format: "%.2fs", elapsed)
        }
        
        // Provide haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Record attendance
        if let schoolId = school?.id {
            do {
                try await firebaseService.recordAttendance(schoolId: schoolId, studentId: match.studentId)
                await addLog("📝 Attendance recorded")
                
                // TODO: Send WhatsApp notification (to be implemented later)
                // For now, just log that we would send it
                await addLog("📱 WhatsApp notification pending...")
                
            } catch {
                await addLog("⚠️ Failed to record attendance: \(error.localizedDescription)")
                print("⚠️ Failed to record attendance: \(error)")
            }
        }
        
        // Show popup and pause for user confirmation (instead of auto-reset)
        await showResultAndPause()
    }
    
    /// Show result popup and pause camera until user confirms
    private func showResultAndPause() async {
        await MainActor.run {
            isPaused = true
            showResultPopup = true
            isProcessing = false
        }
        
        // Provide haptic feedback based on status
        let generator = UINotificationFeedbackGenerator()
        switch status {
        case .success:
            generator.notificationOccurred(.success)
        case .failed:
            generator.notificationOccurred(.error)
        default:
            break
        }
    }
    
    /// User confirmed result, resume camera capture
    func confirmAndResume() {
        showResultPopup = false
        isPaused = false
        capturedImage = nil  // Clear captured image
        status = .scanning
        showFaceBox = false
        statusLog.removeAll()
    }
    
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
        
        // Show popup and pause for user confirmation
        await showResultAndPause()
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
