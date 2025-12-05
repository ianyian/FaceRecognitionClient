//
//  CameraView.swift
//  FaceRecognitionClient
//
//  Created on November 28, 2025.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    let staff: Staff
    let school: School
    let onLogout: () -> Void
    
    @StateObject private var viewModel = CameraViewModel()
    @State private var showLogoutAlert = false
    @State private var showSettings = false
    @State private var showStudentManagement = false
    @State private var showCachedStudents = false  // Show cached students list
    @State private var showActivityLog = true  // Default ON, syncs with settings
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                topBar
                cameraPreviewArea
                statusPanel
            }
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) {
                viewModel.resumeFromTest()
            }
            Button("Logout", role: .destructive) {
                viewModel.stopCamera()
                onLogout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
        .task {
            await viewModel.loadData(staff: staff, school: school)
            showActivityLog = SettingsService.shared.showActivityLog
        }
        .onDisappear {
            viewModel.stopCamera()
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            showActivityLog = SettingsService.shared.showActivityLog
        }
        .sheet(isPresented: $viewModel.showImagePicker) {
            ImagePicker(image: Binding(
                get: { nil },
                set: { image in
                    if let image = image {
                        Task {
                            await viewModel.processPickedImage(image)
                        }
                    }
                }
            ))
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(schoolId: school.id, schoolName: school.name) {
                viewModel.reloadCache()
            }
        }
        .fullScreenCover(isPresented: $showStudentManagement) {
            StudentListView(school: school, onBack: {
                showStudentManagement = false
            })
        }
        .sheet(isPresented: $showCachedStudents) {
            CachedStudentsView(
                cacheStatus: viewModel.cacheStatus,
                schoolId: school.id,
                schoolName: school.name,
                onDismiss: {
                    showCachedStudents = false
                },
                onDownloadComplete: {
                    viewModel.reloadCache()
                }
            )
        }
        .overlay {
            if viewModel.showResultPopup {
                ResultPopupView(
                    status: viewModel.status,
                    studentName: viewModel.studentName,
                    processingTime: viewModel.processingTime,
                    parentPhone: viewModel.matchedParentPhone,
                    showWhatsAppButton: SettingsService.shared.showWhatsAppButton,
                    showAutoLockCountdown: viewModel.showPopupAutoLockCountdown,
                    autoLockCountdown: viewModel.popupAutoLockCountdown,
                    onConfirm: {
                        viewModel.confirmAndResume()
                    },
                    onWhatsApp: {
                        viewModel.confirmAndResume()
                    },
                    onLock: {
                        viewModel.manualLockFromPopup()
                    }
                )
            }
        }
    }
    
    // MARK: - Top Bar
    
    private var topBar: some View {
        HStack {
            // Logout button
            Button(action: {
                showLogoutAlert = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.subheadline)
                    Text("Logout")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .foregroundColor(.white)
                .cornerRadius(20)
            }
            
            Spacer()
            
            // Cache status indicator
            cacheStatusButton
            
            Spacer()
            
            // Students button
            Button(action: {
                showStudentManagement = true
            }) {
                Image(systemName: "person.2.fill")
                    .font(.title3)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
            
            // Settings button
            Button(action: {
                showSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
    }
    
    @ViewBuilder
    private var cacheStatusButton: some View {
        if viewModel.cacheStatus.hasCache {
            Button {
                showCachedStudents = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .foregroundColor(.green)
                    Text("\(viewModel.cacheStatus.studentCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
            }
        } else {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("No Data")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
        }
    }
    
    // MARK: - Camera Preview Area
    
    @ViewBuilder
    private var cameraPreviewArea: some View {
        ZStack {
            if let capturedImage = viewModel.capturedImage {
                capturedImageView(capturedImage)
            } else if viewModel.isCameraReady, let previewLayer = viewModel.cameraService.getPreviewLayer() {
                liveCameraPreview(previewLayer)
            } else if viewModel.isCameraReady && viewModel.isSimulator {
                simulatorModeView
            } else if viewModel.isCameraStarted {
                initializingCameraView
            } else {
                cameraReadyView
            }
            
            // Face Detection Box
            if viewModel.showFaceBox {
                FaceDetectionBox()
                    .transition(.opacity)
            }
        }
        .layoutPriority(1)
    }
    
    private func capturedImageView(_ image: UIImage) -> some View {
        ZStack {
            GeometryReader { geo in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            }
            
            if !viewModel.showResultPopup {
                VStack {
                    if viewModel.isComparing {
                        HStack(spacing: 10) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Comparing...")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 25)
                        .padding(.vertical, 12)
                        .background(Color.orange)
                        .cornerRadius(12)
                        .padding(.top, 20)
                    } else {
                        Text("📸 Captured!")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.green)
                            .cornerRadius(10)
                            .padding(.top, 20)
                    }
                    
                    Spacer()
                    
                    Button {
                        viewModel.resumeFromTest()
                    } label: {
                        HStack {
                            Image(systemName: "xmark")
                            Text("Cancel")
                                .fontWeight(.bold)
                        }
                        .font(.title3)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 18)
                        .background(Color.gray.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    private func liveCameraPreview(_ previewLayer: AVCaptureVideoPreviewLayer) -> some View {
        ZStack {
            CameraPreviewView(previewLayer: previewLayer)
            
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.testCapture()
                }
            
            VStack {
                Spacer()
                Text("👆 Tap anywhere to capture")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(20)
                Spacer()
            }
            
            if viewModel.showAutoLockCountdown {
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                            Text("Auto-lock")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .padding(.trailing, 8)
                        .padding(.top, 8)
                    }
                    Spacer()
                }
            }
        }
    }
    
    private var simulatorModeView: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.5))
            
            VStack(spacing: 20) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 60))
                    .foregroundColor(.white.opacity(0.7))
                
                Text("💻 Simulator Test Mode")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Select an image to test Firebase save/retrieve")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Button(action: {
                    viewModel.showImagePicker = true
                }) {
                    HStack {
                        Image(systemName: "photo.fill")
                        Text("Pick Image from Library")
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                
                Text("Image will be saved to Firebase and retrieved for verification")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if let savedImage = viewModel.savedImage {
                VStack {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("✅ Uploaded & Retrieved")
                                .font(.system(size: 10))
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.green)
                                .cornerRadius(6)
                            
                            Image(uiImage: savedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .background(Color.white)
                                .cornerRadius(8)
                                .shadow(radius: 8)
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 16)
                    }
                    Spacer()
                }
                .transition(.opacity.combined(with: .scale))
                .animation(.spring(response: 0.3), value: viewModel.savedImage != nil)
            }
        }
    }
    
    private var initializingCameraView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("Initializing camera...")
                        .foregroundColor(.white)
                        .padding(.top)
                }
            )
    }
    
    private var cameraReadyView: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("Camera Ready")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Button(action: {
                        Task {
                            await viewModel.manualStartCamera()
                        }
                    }) {
                        HStack {
                            Image(systemName: "video.fill")
                            Text("Start Camera")
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
            )
    }
    
    // MARK: - Status Panel
    
    private var statusPanel: some View {
        VStack(spacing: 0) {
            // Compact Status Bar with Lock Button
            HStack(spacing: 12) {
                // Status indicator
                HStack(spacing: 8) {
                    if viewModel.isCameraStarted {
                        Image(systemName: viewModel.status.icon)
                            .font(.system(size: 20))
                            .foregroundColor(viewModel.status.color)
                        
                        Text(viewModel.status.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                        
                        Text("Screen Locked")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
                
                if viewModel.isComparing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.8)
                }
                
                if viewModel.isCameraReady && !viewModel.isComparing {
                    Button(action: {
                        viewModel.manualLock()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                            Text("Lock")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(viewModel.isCameraStarted ? viewModel.status.color.opacity(0.15) : Color.gray.opacity(0.15))
            
            // Activity Log
            if showActivityLog {
                activityLogView
            }
        }
        .frame(minHeight: showActivityLog ? 170 : 50)
        .fixedSize(horizontal: false, vertical: true)
        .background(colorScheme == .dark ? Color(.systemBackground) : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 10, y: -5)
    }
    
    private var activityLogView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    if viewModel.statusLog.isEmpty {
                        Text("👆 Tap screen to capture photo")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(Array(viewModel.statusLog.enumerated()), id: \.offset) { index, log in
                            Text(log)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(log.contains("❌") || log.contains("FAILED") || log.contains("ERROR") ? .red :
                                               log.contains("✅") ? .green : .primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 2)
                                .id(index)
                        }
                    }
                    
                    Color.clear
                        .frame(height: 5)
                        .id("bottom")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .frame(height: 120)
            .background(colorScheme == .dark ? Color(.systemBackground) : Color(.secondarySystemBackground))
            .onChange(of: viewModel.statusLog.count) { _ in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }
}

// MARK: - Result Popup View

struct ResultPopupView: View {
    let status: CameraStatus
    let studentName: String
    let processingTime: String
    let parentPhone: String?
    let showWhatsAppButton: Bool
    let showAutoLockCountdown: Bool
    let autoLockCountdown: Int
    let onConfirm: () -> Void
    let onWhatsApp: () -> Void
    let onLock: () -> Void
    
    private var isSuccess: Bool {
        if case .success = status { return true }
        return false
    }
    
    private var canShowWhatsApp: Bool {
        guard isSuccess else { return false }
        guard showWhatsAppButton else { return false }
        guard let phone = parentPhone, !phone.isEmpty else { return false }
        return true
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent background - tappable to dismiss
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onConfirm()
                }
            
            // Popup card
            VStack(spacing: 24) {
                // Status icon
                Image(systemName: status.icon)
                    .font(.system(size: 80))
                    .foregroundColor(status.color)
                
                // Title
                Text(status.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Message
                Text(status.message)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                
                // Details (for success)
                if case .success = status {
                    VStack(spacing: 8) {
                        Text("Time: \(processingTime)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                // Buttons
                VStack(spacing: 12) {
                    // WhatsApp button (only for success with parent phone and setting enabled)
                    if canShowWhatsApp, let phone = parentPhone {
                        Button {
                            openWhatsApp(phone: phone)
                            onWhatsApp()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "message.fill")
                                Text("WhatsApp Parent")
                                    .fontWeight(.bold)
                            }
                            .font(.title3)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .padding(.horizontal, 10)
                    }
                    
                    // Next Capture button
                    Button {
                        onConfirm()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "camera.fill")
                            Text("Next Capture")
                                .fontWeight(.bold)
                        }
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(status.color)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .padding(.horizontal, 10)
                }
                .padding(.top, 10)
                
                // Screen-Lock button (moved to bottom with more spacing)
                Button {
                    onLock()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "lock.fill")
                        Text("Screen-Lock")
                            .fontWeight(.bold)
                        if showAutoLockCountdown {
                            Text("(\(autoLockCountdown)s)")
                                .font(.caption)
                                .fontWeight(.regular)
                        }
                    }
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.gray.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .padding(.horizontal, 10)
                .padding(.top, 16)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.systemBackground).opacity(0.95))
                    .shadow(color: status.color.opacity(0.5), radius: 20)
            )
            .padding(.horizontal, 30)
            .onAppear {
                print("📱 ResultPopupView: parentPhone=\(parentPhone ?? "nil"), showSetting=\(showWhatsAppButton), isSuccess=\(isSuccess), canShow=\(canShowWhatsApp)")
            }
        }
    }
    
    private func openWhatsApp(phone: String) {
        let cleanNumber = phone.replacingOccurrences(of: "[^0-9+]", with: "", options: .regularExpression)
        let whatsappNumber = cleanNumber.replacingOccurrences(of: "+", with: "")
        
        if let url = URL(string: "https://wa.me/\(whatsappNumber)") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Face Detection Box

struct FaceDetectionBox: View {
    var body: some View {
        ZStack {
            // Corner brackets
            VStack {
                HStack {
                    CornerBracket(corners: [.topLeft])
                    Spacer()
                    CornerBracket(corners: [.topRight])
                }
                Spacer()
                HStack {
                    CornerBracket(corners: [.bottomLeft])
                    Spacer()
                    CornerBracket(corners: [.bottomRight])
                }
            }
            
            // Label
            VStack {
                Text("Face Detected")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.9))
                    .foregroundColor(.white)
                    .cornerRadius(6)
                    .offset(y: -20)
                
                Spacer()
            }
        }
        .frame(width: 250, height: 300)
    }
}

struct CornerBracket: View {
    let corners: UIRectCorner
    
    var body: some View {
        RoundedCorner(radius: 4, corners: corners)
            .stroke(Color.green, lineWidth: 3)
            .frame(width: 30, height: 30)
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Detail Row

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.vertical, 8)
        Divider()
    }
}

#Preview {
    CameraView(
        staff: Staff(
            id: "test-id",
            email: "test@example.com",
            firstName: "Ian",
            lastName: "Wong",
            role: .reception,
            schoolId: "main-tuition-center"
        ),
        school: School(
            id: "main-tuition-center",
            name: "Main Tuition Center"
        ),
        onLogout: {}
    )
}
