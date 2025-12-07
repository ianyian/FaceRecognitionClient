//
//  StudentFormView.swift
//  FaceRecognitionClient
//
//  Student Registration / Edit Form with Face Capture
//  Created on December 4, 2025.
//  Updated December 4, 2025 - Memory optimized image display
//

import AVFoundation
import SwiftUI

// MARK: - Cached Existing Image View (prevents repeated base64 decoding)

struct CachedExistingImageView: View {
    let dataUrl: String
    let height: CGFloat

    @State private var cachedImage: UIImage?

    var body: some View {
        Group {
            if let image = cachedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.tertiarySystemBackground))
                    .frame(height: height)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.6)
                    )
            }
        }
        .onAppear {
            if cachedImage == nil {
                decodeImage()
            }
        }
    }

    private func decodeImage() {
        // Decode in background to not block UI
        DispatchQueue.global(qos: .userInitiated).async {
            guard let base64String = dataUrl.components(separatedBy: ",").last,
                let imageData = Data(base64Encoded: base64String),
                let image = UIImage(data: imageData)
            else {
                return
            }

            // Create thumbnail to save memory
            let thumbnail = createThumbnail(from: image, maxDimension: 100)

            DispatchQueue.main.async {
                self.cachedImage = thumbnail
            }
        }
    }

    private func createThumbnail(from image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let scale = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return thumbnail ?? image
    }
}

struct StudentFormView: View {
    @ObservedObject var viewModel: StudentViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    let staff: Staff
    let isEdit: Bool

    // Camera state
    @StateObject private var cameraService = CameraService()
    @State private var showCamera = false
    @State private var isCapturing = false
    @State private var selectedImageIndex: Int?
    @State private var showImagePreview = false
    @State private var showCameraPermissionAlert = false
    @State private var flashEffect = false
    @State private var captureCompletedManually = false  // User tapped Complete button

    var body: some View {
        NavigationStack {
            Form {
                // Student Information Section
                studentInfoSection

                // Parent Information Section
                parentInfoSection

                // Face Samples Section
                faceSamplesSection

                // Form Validation Status
                if !isEdit {
                    validationStatusSection
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .onTapGesture {
                hideKeyboard()
            }
            .navigationTitle(isEdit ? "Edit Student" : "New Student")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            hideKeyboard()
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        stopCamera()
                        viewModel.cancelForm()
                        dismiss()
                    }
                    .foregroundColor(.red)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            stopCamera()
                            await viewModel.submitForm()
                            if !viewModel.showToast || viewModel.toastType == .success {
                                dismiss()
                            }
                        }
                    } label: {
                        if viewModel.isSubmitting {
                            ProgressView()
                        } else {
                            Text(isEdit ? "Update" : "Register")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(viewModel.isSubmitting || !canSubmit)
                }
            }
            .sheet(isPresented: $showImagePreview) {
                if let index = selectedImageIndex, index < viewModel.capturedImages.count {
                    ImagePreviewView(image: viewModel.capturedImages[index])
                }
            }
            .alert("Camera Access Required", isPresented: $showCameraPermissionAlert) {
                Button("Open Settings", role: .none) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable camera access in Settings to capture face photos.")
            }
        }
        .onDisappear {
            stopCamera()
        }
    }

    // MARK: - Computed Properties

    private var canSubmit: Bool {
        if isEdit {
            return viewModel.formData.isValid
        } else {
            return viewModel.formData.isValid && viewModel.hasEnoughSamples
        }
    }

    // MARK: - Student Information Section

    private var studentInfoSection: some View {
        Section {
            // First Name
            HStack(spacing: 12) {
                Image(systemName: "person.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24)

                TextField("First Name", text: $viewModel.formData.studentFirstName)
                    .textContentType(.givenName)
                    .autocapitalization(.words)

                if viewModel.formData.studentFirstName.count >= 2 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            // Last Name
            HStack(spacing: 12) {
                Image(systemName: "person.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24)

                TextField("Last Name", text: $viewModel.formData.studentLastName)
                    .textContentType(.familyName)
                    .autocapitalization(.words)

                if viewModel.formData.studentLastName.count >= 2 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            // Class Picker
            HStack(spacing: 12) {
                Image(systemName: "graduationcap.fill")
                    .foregroundColor(.orange)
                    .frame(width: 24)

                Picker("Class", selection: $viewModel.formData.className) {
                    Text("Select a class").tag("")
                    ForEach(viewModel.classes) { classInfo in
                        Text(classInfo.name).tag(classInfo.name)
                    }
                }
                .pickerStyle(.menu)

                if !viewModel.formData.className.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
        } header: {
            Label("Student Information", systemImage: "person.text.rectangle")
        } footer: {
            Text("Enter the student's full name and select their class.")
        }
    }

    // MARK: - Parent Information Section

    private var parentInfoSection: some View {
        Section {
            // Parent First Name
            HStack(spacing: 12) {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.purple)
                    .frame(width: 24)

                TextField("Parent's First Name", text: $viewModel.formData.parentFirstName)
                    .textContentType(.givenName)
                    .autocapitalization(.words)

                if viewModel.formData.parentFirstName.count >= 2 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            // Parent Last Name
            HStack(spacing: 12) {
                Image(systemName: "person.2.fill")
                    .foregroundColor(.purple)
                    .frame(width: 24)

                TextField("Parent's Last Name", text: $viewModel.formData.parentLastName)
                    .textContentType(.familyName)
                    .autocapitalization(.words)

                if viewModel.formData.parentLastName.count >= 2 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            // WhatsApp Number
            HStack(spacing: 12) {
                Image(systemName: "phone.fill")
                    .foregroundColor(.green)
                    .frame(width: 24)

                TextField("WhatsApp Number", text: $viewModel.formData.parentPhone)
                    .textContentType(.telephoneNumber)
                    .keyboardType(.phonePad)

                if viewModel.formData.parentPhone.count >= 10 {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
        } header: {
            Label("Parent/Guardian", systemImage: "figure.and.child.holdinghands")
        } footer: {
            Text("Parent information is used for attendance notifications via WhatsApp.")
        }
    }

    // MARK: - Face Samples Section

    private var faceSamplesSection: some View {
        Section {
            // Status Row
            HStack {
                Image(
                    systemName: viewModel.hasEnoughSamples
                        ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                )
                .foregroundColor(viewModel.hasEnoughSamples ? .green : .orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(
                        viewModel.hasEnoughSamples ? "Face Samples Ready" : "Face Samples Required"
                    )
                    .font(.headline)
                    Text(
                        "\(viewModel.captureCount) of \(StudentViewModel.minFaceSamples)-\(StudentViewModel.maxFaceSamples) samples captured"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()

                // Progress indicator
                CircularProgressView(
                    progress: Double(viewModel.captureCount)
                        / Double(StudentViewModel.maxFaceSamples),
                    lineWidth: 4
                )
                .frame(width: 36, height: 36)
            }

            // Camera Preview
            cameraPreviewView

            // Camera Controls
            cameraControlsView

            // Existing Images (Edit mode)
            if isEdit && !viewModel.existingImages.isEmpty && viewModel.capturedImages.isEmpty {
                existingImagesGrid
            }

            // Captured Images
            if !viewModel.capturedImages.isEmpty {
                capturedImagesGrid
            }
        } header: {
            Label("Face Recognition", systemImage: "faceid")
        } footer: {
            if isEdit {
                Text(
                    "You can optionally capture new photos to replace the existing ones. Leave empty to keep current photos."
                )
            } else {
                Text(
                    "Capture 3-5 clear photos of the student's face from different angles for accurate recognition."
                )
            }
        }
    }

    // MARK: - Camera Preview

    private var cameraPreviewView: some View {
        ZStack {
            if showCamera, let previewLayer = cameraService.getPreviewLayer() {
                // Live Camera Streaming - Tap anywhere to capture
                CameraPreviewView(previewLayer: previewLayer)
                    .overlay(
                        // Face guide overlay
                        RoundedRectangle(cornerRadius: 100)
                            .stroke(Color.white.opacity(0.6), lineWidth: 2)
                            .frame(width: 180, height: 220)
                    )
                    .overlay(
                        // Flash effect
                        Color.white
                            .opacity(flashEffect ? 0.8 : 0)
                            .animation(.easeOut(duration: 0.15), value: flashEffect)
                    )
                    .overlay(
                        // Tap instruction overlay
                        VStack {
                            Spacer()
                            Text(
                                "👆 Tap to capture (\(viewModel.captureCount)/\(StudentViewModel.maxFaceSamples))"
                            )
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(20)
                            .padding(.bottom, 16)
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if viewModel.canCapture && !isCapturing {
                            capturePhoto()
                        }
                    }
            } else {
                // Camera Off State - Tap to start
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemGroupedBackground))
                    .overlay(
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .frame(width: 80, height: 80)

                                Image(systemName: "camera.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.blue)
                            }

                            Text("Camera Preview")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text("Tap here to start camera")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        startCamera()
                    }
            }
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }

    // MARK: - Camera Controls

    private var cameraControlsView: some View {
        Group {
            if showCamera {
                // Show Complete button when camera is streaming
                HStack(spacing: 12) {
                    // Complete button - enabled when >= 3 samples
                    Button {
                        completeCapture()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Complete")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            viewModel.hasEnoughSamples ? Color.green : Color.gray.opacity(0.3)
                        )
                        .foregroundColor(viewModel.hasEnoughSamples ? .white : .secondary)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .disabled(!viewModel.hasEnoughSamples)

                    // Stop Camera button
                    Button {
                        stopCamera()
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Cancel")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            } else if !viewModel.capturedImages.isEmpty {
                // Camera is off but we have images - show option to retake
                Button {
                    startCamera()
                } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Capture More Photos")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(viewModel.canCapture ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundColor(viewModel.canCapture ? .white : .secondary)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.canCapture)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
        }
    }

    // MARK: - Existing Images Grid

    private var existingImagesGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "photo.stack.fill")
                    .foregroundColor(.blue)
                Text("Current Samples")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(viewModel.existingImages.count) photos")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                ], spacing: 8
            ) {
                ForEach(Array(viewModel.existingImages.enumerated()), id: \.offset) {
                    index, dataUrl in
                    // Use cached component to avoid repeated base64 decoding
                    CachedExistingImageView(dataUrl: dataUrl, height: 80)
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Captured Images Grid

    private var capturedImagesGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "camera.on.rectangle.fill")
                    .foregroundColor(.green)
                Text(isEdit ? "New Samples" : "Captured Samples")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                if isEdit && !viewModel.capturedImages.isEmpty {
                    Text("Will replace current")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                    GridItem(.flexible(), spacing: 8),
                ], spacing: 8
            ) {
                ForEach(Array(viewModel.capturedImages.enumerated()), id: \.offset) {
                    index, image in
                    ZStack(alignment: .topTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.green.opacity(0.5), lineWidth: 2)
                            )
                            .onTapGesture {
                                selectedImageIndex = index
                                showImagePreview = true
                            }

                        // Delete button
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.removeCapturedImage(at: index)
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 24, height: 24)
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .offset(x: 6, y: -6)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Validation Status Section

    private var validationStatusSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                validationRow(
                    title: "Student Name",
                    isValid: viewModel.formData.studentFirstName.count >= 2
                        && viewModel.formData.studentLastName.count >= 2,
                    icon: "person.fill"
                )

                validationRow(
                    title: "Class Selected",
                    isValid: !viewModel.formData.className.isEmpty,
                    icon: "graduationcap.fill"
                )

                validationRow(
                    title: "Parent Information",
                    isValid: viewModel.formData.parentFirstName.count >= 2
                        && viewModel.formData.parentLastName.count >= 2,
                    icon: "person.2.fill"
                )

                validationRow(
                    title: "Phone Number",
                    isValid: viewModel.formData.parentPhone.count >= 10,
                    icon: "phone.fill"
                )

                validationRow(
                    title:
                        "Face Samples (\(viewModel.captureCount)/\(StudentViewModel.minFaceSamples)+)",
                    isValid: viewModel.hasEnoughSamples,
                    icon: "faceid"
                )
            }
            .padding(.vertical, 4)
        } header: {
            Label("Registration Checklist", systemImage: "checklist")
        }
    }

    private func validationRow(title: String, isValid: Bool, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isValid ? .green : .gray)

            Text(title)
                .foregroundColor(isValid ? .primary : .secondary)

            Spacer()
        }
    }

    // MARK: - Camera Functions

    private func startCamera() {
        cameraService.checkAuthorization()

        guard cameraService.isAuthorized else {
            showCameraPermissionAlert = true
            return
        }

        do {
            try cameraService.setupSession()
            cameraService.startSession()
            withAnimation(.easeInOut(duration: 0.3)) {
                showCamera = true
                captureCompletedManually = false
            }
        } catch {
            print("❌ Camera error: \(error)")
        }
    }

    private func stopCamera() {
        cameraService.stopSession()
        withAnimation(.easeInOut(duration: 0.3)) {
            showCamera = false
        }
    }

    private func completeCapture() {
        // User manually completed capture with >= 3 samples
        captureCompletedManually = true
        stopCamera()
    }

    private func capturePhoto() {
        guard showCamera, viewModel.canCapture else { return }

        isCapturing = true

        // Flash effect
        withAnimation {
            flashEffect = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            flashEffect = false
        }

        // Capture from camera
        cameraService.capturePhoto()

        // Use the captured image
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let image = cameraService.capturedImage {
                // Add watermark to image
                let watermarkedImage = addWatermark(to: image)
                withAnimation(.spring(response: 0.3)) {
                    viewModel.addCapturedImage(watermarkedImage)
                }

                // Auto-close camera when reaching max (5) samples
                if viewModel.captureCount >= StudentViewModel.maxFaceSamples {
                    // Small delay to let user see the 5th image flash
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        captureCompletedManually = true
                        stopCamera()
                    }
                }
            }
            isCapturing = false
        }
    }

    // MARK: - Watermark Function

    /// Add "XJ.Yian DD/MM/YYYY HH:MM AM/PM" watermark to bottom-right corner
    private func addWatermark(to image: UIImage) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)

        return renderer.image { context in
            // Draw original image
            image.draw(at: .zero)

            // Format current date and time
            let now = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy"
            let dateStr = dateFormatter.string(from: now)

            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "hh:mm a"
            let timeStr = timeFormatter.string(from: now)

            let watermarkText = "XJ.Yian \(dateStr) \(timeStr)"

            // Configure watermark style - responsive font size
            let fontSize = max(12, image.size.width * 0.025)
            let font = UIFont.systemFont(ofSize: fontSize, weight: .medium)

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .right

            let shadow = NSShadow()
            shadow.shadowColor = UIColor.black.withAlphaComponent(0.5)
            shadow.shadowBlurRadius = 2
            shadow.shadowOffset = CGSize(width: 1, height: 1)

            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white.withAlphaComponent(0.85),
                .paragraphStyle: paragraphStyle,
                .shadow: shadow,
            ]

            // Calculate position (bottom-right with padding)
            let textSize = watermarkText.size(withAttributes: attributes)
            let padding = max(8, image.size.width * 0.015)
            let textRect = CGRect(
                x: image.size.width - textSize.width - padding,
                y: image.size.height - textSize.height - padding,
                width: textSize.width,
                height: textSize.height
            )

            // Draw watermark
            watermarkText.draw(in: textRect, withAttributes: attributes)
        }
    }

    // MARK: - Helper Functions

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func dataURLToUIImage(_ dataURL: String) -> UIImage? {
        guard let base64String = dataURL.components(separatedBy: ",").last,
            let imageData = Data(base64Encoded: base64String)
        else {
            return nil
        }
        return UIImage(data: imageData)
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    progress >= 0.6 ? Color.green : Color.orange,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)

            Text("\(Int(progress * 100))%")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Image Preview View

struct ImagePreviewView: View {
    let image: UIImage
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding()
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            }
            .navigationTitle("Face Sample")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    StudentFormView(
        viewModel: StudentViewModel(
            schoolId: "main-tuition-center",
            staff: Staff(
                id: "preview-staff",
                email: "admin@example.com",
                firstName: "Admin",
                lastName: "User",
                role: .admin,
                schoolId: "main-tuition-center"
            )
        ),
        staff: Staff(
            id: "preview-staff",
            email: "admin@example.com",
            firstName: "Admin",
            lastName: "User",
            role: .admin,
            schoolId: "main-tuition-center"
        ),
        isEdit: false
    )
}
