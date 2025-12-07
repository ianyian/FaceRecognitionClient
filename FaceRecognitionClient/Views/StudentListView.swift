//
//  StudentListView.swift
//  FaceRecognitionClient
//
//  Student List with Search and Filter
//  Created on December 4, 2025.
//

import SwiftUI

struct StudentListView: View {
    @StateObject private var viewModel: StudentViewModel
    @Environment(\.colorScheme) var colorScheme

    // Observe settings for avatar display
    @State private var showAvatars: Bool = SettingsService.shared.showAvatarsInList

    let school: School
    let staff: Staff
    let onBack: () -> Void

    init(school: School, staff: Staff, onBack: @escaping () -> Void) {
        self.school = school
        self.staff = staff
        self.onBack = onBack
        _viewModel = StateObject(wrappedValue: StudentViewModel(schoolId: school.id, staff: staff))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Filter Tabs
                filterTabs

                // Student List
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.filteredStudents.isEmpty {
                    emptyStateView
                } else {
                    studentList
                }
            }
            .navigationTitle("Students")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        onBack()
                    }
                }

                // Only show Add button if user has create permission (Admin, Reception)
                if staff.canCreate {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            viewModel.prepareAddForm()
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search by name...")
            .task {
                await viewModel.loadData()
            }
            .refreshable {
                await viewModel.loadData()
            }
            .sheet(isPresented: $viewModel.showingAddForm) {
                StudentFormView(viewModel: viewModel, staff: staff, isEdit: false)
            }
            .sheet(isPresented: $viewModel.showingEditForm) {
                StudentFormView(viewModel: viewModel, staff: staff, isEdit: true)
            }
            .navigationDestination(item: $viewModel.selectedStudent) { student in
                StudentDetailView(viewModel: viewModel, staff: staff, initialStudent: student)
            }
        }
        .overlay(alignment: .bottom) {
            if viewModel.showToast {
                ToastView(message: viewModel.toastMessage, type: viewModel.toastType)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                viewModel.showToast = false
                            }
                        }
                    }
            }
        }
        .animation(.spring(response: 0.3), value: viewModel.showToast)
    }

    // MARK: - Filter Tabs

    private var filterTabs: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach([StudentStatus.registered, StudentStatus.deleted], id: \.self) { status in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.statusFilter = status
                        }
                    } label: {
                        VStack(spacing: 8) {
                            HStack(spacing: 6) {
                                Image(
                                    systemName: status == .registered
                                        ? "checkmark.circle.fill" : "trash.circle.fill"
                                )
                                .font(.subheadline)
                                Text(status.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(
                                viewModel.statusFilter == status
                                    ? (status == .registered ? .green : .red)
                                    : .secondary
                            )

                            // Active indicator bar
                            Rectangle()
                                .fill(
                                    viewModel.statusFilter == status
                                        ? (status == .registered ? Color.green : Color.red)
                                        : Color.clear
                                )
                                .frame(height: 3)
                                .cornerRadius(1.5)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Student List

    private var studentList: some View {
        List {
            ForEach(viewModel.filteredStudents) { student in
                StudentRowView(student: student, schoolId: school.id, showAvatar: showAvatars)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Task {
                            await viewModel.loadStudentDetail(student.id)
                        }
                    }
            }
        }
        .listStyle(.plain)
        .onAppear {
            // Refresh avatar setting when view appears
            showAvatars = SettingsService.shared.showAvatarsInList
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading students...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Text("🎓")
                .font(.system(size: 60))
            Text("No students found")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Try adjusting your search or filter")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Student Row View

struct StudentRowView: View {
    let student: Student
    let schoolId: String
    let showAvatar: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Avatar - only show if setting is enabled
            if showAvatar {
                StudentAvatarView(
                    studentId: student.id,
                    studentName: student.fullName,
                    schoolId: schoolId,
                    size: 50
                )
            } else {
                // Simple initials circle when avatar is disabled
                InitialsAvatarView(name: student.fullName, size: 50)
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(student.fullName)
                    .font(.body)
                    .fontWeight(.medium)

                Text(student.className)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status Badge
            StatusBadge(status: student.status)

            // Chevron
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Initials Avatar View (Memory-efficient alternative)

struct InitialsAvatarView: View {
    let name: String
    let size: CGFloat

    private var initials: String {
        let components = name.split(separator: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "?"
    }

    private var backgroundColor: Color {
        // Generate consistent color from name
        let hash = abs(name.hashValue)
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .teal, .indigo]
        return colors[hash % colors.count]
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(backgroundColor.opacity(0.2))

            Circle()
                .stroke(backgroundColor.opacity(0.3), lineWidth: 1)

            Text(initials)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundColor(backgroundColor)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: StudentStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(backgroundColor.opacity(0.15))
            .foregroundColor(backgroundColor)
            .cornerRadius(12)
    }

    private var backgroundColor: Color {
        switch status {
        case .registered:
            return .green
        case .pending:
            return .orange
        case .deleted:
            return .red
        }
    }
}

// MARK: - Toast View

struct ToastView: View {
    let message: String
    let type: StudentViewModel.ToastType

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(iconColor)

            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
        )
        .padding(.horizontal)
        .padding(.bottom, 20)
    }

    private var iconName: String {
        switch type {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }

    private var iconColor: Color {
        switch type {
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        }
    }
}

// MARK: - Preview

#Preview {
    StudentListView(
        school: School(id: "main-tuition-center", name: "Main Tuition Center"),
        staff: Staff(
            id: "preview-staff",
            email: "admin@example.com",
            firstName: "Admin",
            lastName: "User",
            role: .admin,
            schoolId: "main-tuition-center"
        ),
        onBack: {}
    )
}
