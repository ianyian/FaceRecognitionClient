//
//  StudentDetailView.swift
//  FaceRecognitionClient
//
//  Student Profile Detail View
//  Created on December 4, 2025.
//  Updated December 4, 2025 - Memory optimized image display
//

import SwiftUI

// MARK: - Cached Face Sample View (prevents repeated base64 decoding)

struct CachedFaceSampleView: View {
    let dataUrl: String
    let size: CGFloat
    let onTap: () -> Void

    @State private var cachedImage: UIImage?

    var body: some View {
        Group {
            if let image = cachedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture(perform: onTap)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.tertiarySystemBackground))
                    .frame(height: size)
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

            // Create thumbnail to save memory (display size is 100pt, use 2x for retina)
            let thumbnail = createThumbnail(from: image, maxDimension: 200)

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

struct StudentDetailView: View {
    @ObservedObject var viewModel: StudentViewModel
    @Environment(\.dismiss) var dismiss

    let staff: Staff
    let initialStudent: Student

    // Use selectedStudent from viewModel if available (for refresh after edit), otherwise use initial
    private var student: Student {
        viewModel.selectedStudent ?? initialStudent
    }

    @State private var selectedImageIndex: Int?
    @State private var showImagePreview = false
    @State private var previewImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Student Info Card
                studentInfoCard

                // Parent Info Card
                parentInfoCard

                // Face Samples Card
                faceSamplesCard

                // Action Buttons (only show if user has permission)
                actionButtons
            }
            .padding()
        }
        .navigationTitle("Student Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // Only show Edit button if user has edit permission (Admin, Reception)
            if staff.canEdit {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.prepareEditForm()
                    } label: {
                        Text("Edit")
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .alert("Delete Student", isPresented: $viewModel.showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteStudent()
                    dismiss()
                }
            }
        } message: {
            Text(
                "This will mark '\(student.fullName)' as deleted. This action can be undone by an administrator."
            )
        }
        .sheet(isPresented: $showImagePreview) {
            if let image = previewImage {
                ImagePreviewView(image: image)
            }
        }
    }

    // MARK: - Student Info Card

    private var studentInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Student Information")
                .font(.headline)

            Divider()

            // Name (combined first + last)
            StudentDetailRow(label: "Name", value: student.fullName)

            // Class
            StudentDetailRow(label: "Class", value: student.className)

            // Registration Date + Status in one line
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Registered")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formattedDate(student.registrationDate))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Status")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(student.status.rawValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.15))
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    // MARK: - Parent Info Card

    private var parentInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Parent/Guardian")
                .font(.headline)

            Divider()

            // Parent Name + WhatsApp in one line
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(student.parentFullName ?? "-")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("WhatsApp")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let phone = student.parentPhoneNumber, !phone.isEmpty {
                        Link(
                            destination: URL(
                                string:
                                    "https://wa.me/\(phone.replacingOccurrences(of: "+", with: ""))"
                            )!
                        ) {
                            HStack(spacing: 4) {
                                Image(systemName: "phone.fill")
                                    .font(.caption)
                                Text(phone)
                                    .font(.subheadline)
                            }
                            .foregroundColor(.green)
                        }
                    } else {
                        Text("-")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    // MARK: - Face Samples Card

    private var faceSamplesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Face Samples")
                .font(.headline)

            Divider()

            if viewModel.existingImages.isEmpty {
                Text("No face samples available.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                    ], spacing: 12
                ) {
                    ForEach(Array(viewModel.existingImages.enumerated()), id: \.offset) {
                        index, dataUrl in
                        CachedFaceSampleView(dataUrl: dataUrl, size: 100) {
                            // Load full image only when tapped for preview
                            loadFullImageForPreview(dataUrl: dataUrl)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    /// Load full resolution image only when user taps for preview
    private func loadFullImageForPreview(dataUrl: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let base64String = dataUrl.components(separatedBy: ",").last,
                let imageData = Data(base64Encoded: base64String),
                let image = UIImage(data: imageData)
            else {
                return
            }

            DispatchQueue.main.async {
                self.previewImage = image
                self.showImagePreview = true
            }
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        // Delete Button (only for non-deleted students AND only for Admin users)
        if student.status != .deleted && staff.canDelete {
            Button {
                viewModel.confirmDelete()
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Student")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(12)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch student.status {
        case .registered: return .green
        case .pending: return .orange
        case .deleted: return .red
        }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "-" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Student Detail Row

struct StudentDetailRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        StudentDetailView(
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
            initialStudent: Student(
                id: "test-id",
                firstName: "Alice",
                lastName: "Wong",
                className: "Class A",
                parentFirstName: "John",
                parentLastName: "Wong",
                parentPhone: "+60123456789",
                status: .registered,
                registrationDate: Date()
            )
        )
    }
}
