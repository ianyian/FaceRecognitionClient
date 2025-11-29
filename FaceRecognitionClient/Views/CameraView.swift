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
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Button(action: {
                        showLogoutAlert = true
                    }) {
                        Text("Logout")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.9))
                            .foregroundColor(.blue)
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    Text(staff.email)
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(Color.black.opacity(0.5))
                
                // Camera Preview Area
                ZStack {
                    // Camera Preview or Placeholder
                    if viewModel.isCameraReady, let previewLayer = viewModel.cameraService.getPreviewLayer() {
                        CameraPreviewView(previewLayer: previewLayer)
                    } else if viewModel.isCameraReady && viewModel.isSimulator {
                        // Simulator mode - show test UI with image display
                        ZStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.5))
                            
                            // Pick Image button
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
                            
                            // Show uploaded image preview in top-right corner (overlay)
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
                    } else if viewModel.isCameraStarted {
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
                    } else {
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
                    
                    // Face Detection Box
                    if viewModel.showFaceBox {
                        FaceDetectionBox()
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(maxHeight: .infinity)
                
                // Status Area
                VStack(spacing: 0) {
                    // Status Indicator
                    HStack(spacing: 15) {
                        Image(systemName: viewModel.status.icon)
                            .font(.system(size: 40))
                            .foregroundColor(viewModel.status.color)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.status.title)
                                .font(.title3)
                                .fontWeight(.bold)
                            
                            Text(viewModel.status.message)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(20)
                    .background(viewModel.status.color.opacity(0.15))
                    .cornerRadius(15)
                    .padding()
                    
                    // Details
                    VStack(spacing: 12) {
                        DetailRow(label: "Last Check:", value: viewModel.lastCheckTime)
                        DetailRow(label: "Student:", value: viewModel.studentName)
                        
                        // Processing time with tiny font
                        HStack {
                            Text("Upload/Download Time:")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.9))
                            Spacer()
                            Text(viewModel.processingTime)
                                .font(.system(size: 9))
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 4)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 25, style: .continuous))
                .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
            }
            
            // Status Log Display at bottom (always at bottom, non-blocking)
            if !viewModel.statusLog.isEmpty {
                VStack {
                    Spacer()
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 3) {
                                ForEach(Array(viewModel.statusLog.enumerated()), id: \.offset) { index, log in
                                    Text(log)
                                        .font(.system(size: 10))
                                        .foregroundColor(log.contains("❌") || log.contains("FAILED") || log.contains("ERROR") ? .red : .white)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.vertical, 1)
                                        .id(index)
                                }
                                
                                // Add spacer to ensure last item is fully visible
                                Color.clear
                                    .frame(height: 10)
                                    .id("bottom")
                            }
                            .padding(10)
                        }
                        .frame(maxHeight: 150)
                        .background(Color.black.opacity(0.85))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.horizontal, 10)
                        .padding(.bottom, 10)
                        .onChange(of: viewModel.statusLog.count) { _ in
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo("bottom", anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .alert("Logout", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                onLogout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
        .task {
            await viewModel.loadData(staff: staff, school: school)
        }
        .onDisappear {
            viewModel.stopCamera()
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
