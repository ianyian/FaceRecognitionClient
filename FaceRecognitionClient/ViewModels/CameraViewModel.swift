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
        case .scanning: return .teal
        case .faceDetected: return .cyan
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
    @Published var matchedParentPhone: String? = nil  // Parent phone for WhatsApp button
    
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
    
    // Auto-lock timer
    private var autoLockTimer: Timer?
    private var autoLockCountdown: Int = 0
    @Published var showAutoLockCountdown: Bool = false
    
    // Popup auto-lock timer (2x timeout)
    private var popupAutoLockTimer: Timer?
    @Published var popupAutoLockCountdown: Int = 0
    @Published var showPopupAutoLockCountdown: Bool = false

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
        
        // Add initial log entry
        await addLog("📷 Camera started")
        await addLog("👆 Tap screen to capture a photo")
        
        do {
            // Setup camera
            try await setupCamera()
            
            status = .scanning
            await addLog("✅ Ready - \(cacheStatus.recordCount) face samples loaded")
            print("✅ Camera started with \(students.count) students")
            
            // Start auto-lock timer when camera starts
            await MainActor.run {
                startAutoLockTimer()
            }
        } catch {
            await addLog("❌ Camera error: \(error.localizedDescription)")
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
    @Published var isComparing: Bool = false  // Shows comparison is in progress
    
    func processFrame(_ image: UIImage) {
        // Just store the latest frame - no auto-capture
        // User will tap to capture manually
        latestFrame = image
    }
    
    /// Capture and run face recognition (non-blocking)
    func testCapture() {
        // Cancel auto-lock timer when user interacts
        cancelAutoLockTimer()
        
        guard let image = latestFrame else {
            print("⚠️ No frame available to capture")
            return
        }
        
        // Haptic feedback for capture
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        
        print("📸 Image captured - starting comparison")
        
        // Immediately show the captured image
        capturedImage = image
        status = .faceDetected
        isPaused = true
        
        // Add separator for new capture instead of clearing log
        if !statusLog.isEmpty {
            statusLog.append("─────────────────")
        }
        
        // Run face recognition in background (non-blocking)
        Task.detached { [weak self] in
            await self?.runFaceComparison(image)
        }
    }
    
    /// Run face comparison in background
    private func runFaceComparison(_ image: UIImage) async {
        await MainActor.run {
            self.isComparing = true
        }
        await addLog("📸 Photo captured!")
        await addLog("🔍 Starting face comparison...")
        
        // Start timer
        let startTime = Date()
        
        do {
            // Check if we have cache data
            guard cacheStatus.hasCache else {
                await addLog("⚠️ No face data cache available")
                await addLog("💡 Go to Settings to download face data")
                await MainActor.run {
                    self.isComparing = false
                    self.status = .failed("No face data")
                    self.showPopupWithAutoLock()
                }
                return
            }
            
            // Detect face landmarks
            await addLog("🔍 Detecting face landmarks...")
            let detectedEncoding = try await faceRecognitionService.detectFaceLandmarks(in: image)
            let totalLandmarks = detectedEncoding.allLandmarks?.count ?? 0
            await addLog("✅ Detected \(detectedEncoding.landmarks.count) key + \(totalLandmarks) total landmarks")
            
            // Match against cache
            await addLog("🔄 Matching against \(cacheStatus.recordCount) samples...")
            let threshold = settingsService.matchThreshold
            await addLog("⚙️ Threshold: \(String(format: "%.0f%%", threshold * 100))")
            
            let matchResult = faceRecognitionService.matchFaceAgainstLocalCache(detectedEncoding)
            
            // Calculate processing time
            let elapsed = Date().timeIntervalSince(startTime)
            let timeStr = String(format: "%.2fs", elapsed)
            
            // Show results
            await addLog("📊 Best score: \(matchResult.bestSimilarityPercentage)")
            if let candidateName = matchResult.bestCandidateName {
                await addLog("👤 Best candidate: \(candidateName)")
            }
            await addLog("⏱️ Time: \(timeStr)")
            
            // Fetch parent phone for WhatsApp button (if match found)
            var fetchedPhone: String? = nil
            if let match = matchResult.match, let schoolId = school?.id {
                do {
                    let student = try await firebaseService.getStudent(schoolId: schoolId, studentId: match.studentId)
                    fetchedPhone = student?.parentPhoneNumber
                    print("📱 WhatsApp: Fetched phone=\(fetchedPhone ?? "nil") for \(match.studentName)")
                } catch {
                    print("⚠️ Failed to fetch student for WhatsApp: \(error)")
                }
            }
            
            await MainActor.run {
                self.processingTime = timeStr
                self.isComparing = false
                self.matchedParentPhone = fetchedPhone  // Set parent phone for WhatsApp button
                
                if let match = matchResult.match {
                    self.status = .success(match.studentName)
                    self.studentName = "\(match.studentName) (\(match.similarityPercentage))"
                } else {
                    self.status = .failed("No match found")
                }
                self.showPopupWithAutoLock()
            }
            
            // Haptic feedback for result
            let feedbackGenerator = UINotificationFeedbackGenerator()
            if matchResult.match != nil {
                feedbackGenerator.notificationOccurred(.success)
            } else {
                feedbackGenerator.notificationOccurred(.error)
            }
            
        } catch {
            let errorMsg = error.localizedDescription
            await addLog("❌ Error: \(errorMsg)")
            
            await MainActor.run {
                self.isComparing = false
                self.status = .failed(errorMsg)
                self.showPopupWithAutoLock()
            }
            
            let feedbackGenerator = UINotificationFeedbackGenerator()
            feedbackGenerator.notificationOccurred(.error)
        }
    }
    
    /// Resume from capture - go back to camera
    func resumeFromTest() {
        capturedImage = nil
        status = .scanning
        isPaused = false
        showResultPopup = false
        isComparing = false
        
        // Ensure camera session is running
        if isCameraReady {
            cameraService.startSession()
        }
        
        print("🔄 Resumed camera")
    }
    
    /// User tapped screen to capture photo (legacy - redirects to testCapture)
    func manualCapture() {
        testCapture()
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
                let totalLandmarks = detectedEncoding.allLandmarks?.count ?? 0
                await addLog("✅ Detected \(detectedEncoding.landmarks.count) key + \(totalLandmarks) total landmarks")
                
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
        
        // Fetch parent phone from student record for WhatsApp button
        var fetchedPhone: String? = nil
        if let schoolId = school?.id {
            do {
                let student = try await firebaseService.getStudent(schoolId: schoolId, studentId: match.studentId)
                fetchedPhone = student?.parentPhoneNumber
                print("📱 WhatsApp: Fetched student, parentPhone=\(fetchedPhone ?? "nil"), setting=\(SettingsService.shared.showWhatsAppButton)")
            } catch {
                print("⚠️ Failed to fetch student for WhatsApp: \(error)")
            }
        } else {
            print("⚠️ WhatsApp: school?.id is nil")
        }
        
        // Set on main actor to ensure UI sees the update
        await MainActor.run {
            matchedParentPhone = fetchedPhone
        }
        
        // Provide haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Record attendance
        if let schoolId = school?.id {
            do {
                try await firebaseService.recordAttendance(schoolId: schoolId, studentId: match.studentId)
                await addLog("📝 Attendance recorded")
                
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
            showPopupWithAutoLock()
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
    
    /// Synchronous helper to show popup and start auto-lock timer (call from MainActor)
    private func showPopupWithAutoLock() {
        isPaused = true
        showResultPopup = true
        isProcessing = false
        
        // Start popup auto-lock timer (2x normal timeout)
        startPopupAutoLockTimer()
    }
    
    /// Start the popup auto-lock timer (2x the normal auto-lock timeout)
    private func startPopupAutoLockTimer() {
        cancelPopupAutoLockTimer()
        
        let timeout = settingsService.autoLockTimeout
        guard timeout > 0 else {
            showPopupAutoLockCountdown = false
            return  // Disabled
        }
        
        // Use 2x the normal timeout for popup
        popupAutoLockCountdown = timeout * 2
        showPopupAutoLockCountdown = true
        
        popupAutoLockTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.popupAutoLockCountdown -= 1
                
                if self.popupAutoLockCountdown <= 0 {
                    self.performPopupAutoLock()
                }
            }
        }
    }
    
    /// Cancel the popup auto-lock timer
    private func cancelPopupAutoLockTimer() {
        popupAutoLockTimer?.invalidate()
        popupAutoLockTimer = nil
        showPopupAutoLockCountdown = false
    }
    
    /// Perform popup auto-lock - close popup and lock camera
    private func performPopupAutoLock() {
        cancelPopupAutoLockTimer()
        
        // Close popup
        showResultPopup = false
        isPaused = false
        capturedImage = nil
        showFaceBox = false
        isComparing = false
        
        // Lock camera (same as manual lock)
        stopCamera()
        isCameraStarted = false
        status = .scanning
        
        print("🔒 Popup auto-locked due to inactivity")
    }
    
    /// User confirmed result, resume camera capture
    func confirmAndResume() {
        // Cancel popup auto-lock timer
        cancelPopupAutoLockTimer()
        
        showResultPopup = false
        isPaused = false
        capturedImage = nil  // Clear captured image
        status = .scanning
        showFaceBox = false
        isComparing = false
        // Don't clear the log - keep history for review
        // statusLog.removeAll()
        
        // Ensure camera session is running
        if isCameraReady {
            cameraService.startSession()
        }
        
        print("🔄 Resumed camera from popup")
        
        // Start auto-lock timer if enabled
        startAutoLockTimer()
    }
    
    // MARK: - Auto Lock
    
    /// Start the auto-lock countdown timer
    private func startAutoLockTimer() {
        // Cancel any existing timer
        cancelAutoLockTimer()
        
        let timeout = settingsService.autoLockTimeout
        guard timeout > 0 else {
            showAutoLockCountdown = false
            return  // Disabled
        }
        
        autoLockCountdown = timeout
        showAutoLockCountdown = true
        
        autoLockTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.autoLockCountdown -= 1
                
                if self.autoLockCountdown <= 0 {
                    self.performAutoLock()
                }
            }
        }
    }
    
    /// Cancel the auto-lock timer (called when user taps to capture)
    func cancelAutoLockTimer() {
        autoLockTimer?.invalidate()
        autoLockTimer = nil
        showAutoLockCountdown = false
    }
    
    /// Perform auto-lock - stop camera and return to start screen
    private func performAutoLock() {
        cancelAutoLockTimer()
        
        // Stop camera
        stopCamera()
        
        // Reset to initial state (before camera started)
        isCameraStarted = false
        isCameraReady = false
        capturedImage = nil
        status = .scanning
        
        // Add log entry
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        statusLog.append("[\(timestamp)] 🔒 Auto-locked (idle timeout)")
        
        print("🔒 Auto-locked due to idle timeout")
    }
    
    /// Manual lock - user initiated screen lock
    func manualLock() {
        cancelAutoLockTimer()
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Stop camera
        stopCamera()
        
        // Reset to initial state (before camera started)
        isCameraStarted = false
        isCameraReady = false
        capturedImage = nil
        status = .scanning
        
        // Add log entry
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        statusLog.append("[\(timestamp)] 🔒 Screen locked (manual)")
        
        print("🔒 Manual screen lock")
    }
    
    /// Manual lock from popup - user wants to lock from result popup
    func manualLockFromPopup() {
        // Cancel popup auto-lock timer
        cancelPopupAutoLockTimer()
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // Close popup and reset state
        showResultPopup = false
        isPaused = false
        capturedImage = nil
        showFaceBox = false
        isComparing = false
        
        // Stop camera
        stopCamera()
        
        // Reset to initial state (before camera started)
        isCameraStarted = false
        isCameraReady = false
        status = .scanning
        
        // Add log entry
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        statusLog.append("[\(timestamp)] 🔒 Screen locked (manual)")
        
        print("🔒 Manual screen lock from popup")
    }
    
    private func handleSuccessfulMatch(_ match: FaceMatchResult) async {
        status = .success(match.student.fullName)
        
        // Update details
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .medium
        lastCheckTime = dateFormatter.string(from: match.matchTimestamp)
        studentName = match.student.fullName
        processingTime = String(format: "%.2fs", match.processingTime)
        
        // Store parent phone for WhatsApp button
        matchedParentPhone = match.student.parentPhoneNumber
        
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
            // Keep last 50 messages to allow reviewing previous captures
            if statusLog.count > 50 {
                statusLog.removeFirst()
            }
        }
        print("📊 Log: \(logMessage)")
    }
    
    deinit {
        stopCamera()
    }
}
