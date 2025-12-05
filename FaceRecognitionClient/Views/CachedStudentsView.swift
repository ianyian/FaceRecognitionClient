//
//  CachedStudentsView.swift
//  FaceRecognitionClient
//
//  Shows list of students loaded in memory from face data cache
//  Created on December 4, 2025.
//  Updated December 5, 2025 - Added Download Face Data button
//

import SwiftUI

struct CachedStudentsView: View {
    let cacheStatus: FaceDataCacheStatus
    let schoolId: String
    let schoolName: String
    let onDismiss: () -> Void
    let onDownloadComplete: (() -> Void)?
    
    @State private var searchText = ""
    @State private var students: [CachedStudentInfo] = []
    @State private var isDownloading = false
    @State private var downloadProgress: (current: Int, total: Int) = (0, 0)
    @State private var statusMessage = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var currentCacheStatus: FaceDataCacheStatus
    
    private let cacheService = FaceDataCacheService.shared
    private let firebaseService = FirebaseService.shared
    
    init(cacheStatus: FaceDataCacheStatus, schoolId: String = "", schoolName: String = "", onDismiss: @escaping () -> Void, onDownloadComplete: (() -> Void)? = nil) {
        self.cacheStatus = cacheStatus
        self.schoolId = schoolId
        self.schoolName = schoolName
        self.onDismiss = onDismiss
        self.onDownloadComplete = onDownloadComplete
        self._currentCacheStatus = State(initialValue: cacheStatus)
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if students.isEmpty {
                    emptyStateView
                } else {
                    studentListView
                }
            }
            .navigationTitle("Loaded Students")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        onDismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search students...")
        }
        .onAppear {
            loadStudentsFromCache()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No Students Loaded")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Download face data from Settings to load students into memory.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Student List
    
    private var studentListView: some View {
        List {
            // Download Section
            Section {
                Button(action: {
                    Task {
                        await downloadFaceData()
                    }
                }) {
                    HStack {
                        if isDownloading {
                            ProgressView()
                                .scaleEffect(0.8)
                                .padding(.trailing, 8)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Downloading...")
                                    .fontWeight(.semibold)
                                if downloadProgress.total > 0 {
                                    Text("\(downloadProgress.current) / \(downloadProgress.total)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            Text("Download Latest Face Data")
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                    }
                }
                .disabled(isDownloading)
                
                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundColor(.green)
                }
            } header: {
                Text("Update")
            } footer: {
                Text("Download to get the latest registered students and face samples.")
            }
            
            // Summary Section
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Students in Memory")
                            .font(.headline)
                        Text("\(currentCacheStatus.studentCount) students, \(currentCacheStatus.recordCount) face samples")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Loaded")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                        
                        if let lastUpdated = currentCacheStatus.lastUpdated {
                            Text(lastUpdated, style: .relative)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            
            // Students List
            Section {
                ForEach(filteredStudents) { student in
                    CachedStudentRow(student: student)
                }
            } header: {
                HStack {
                    Text("Students (\(filteredStudents.count))")
                    Spacer()
                    if !searchText.isEmpty {
                        Text("Filtered")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Filtered Students
    
    private var filteredStudents: [CachedStudentInfo] {
        if searchText.isEmpty {
            return students
        }
        return students.filter { student in
            student.name.lowercased().contains(searchText.lowercased()) ||
            (student.className?.lowercased().contains(searchText.lowercased()) ?? false)
        }
    }
    
    // MARK: - Load Students
    
    private func loadStudentsFromCache() {
        currentCacheStatus = cacheService.getCacheStatus()
        let faceData = cacheService.getFaceDataForMatching()
        
        // Group by student ID and aggregate sample count
        var studentMap: [String: CachedStudentInfo] = [:]
        
        for record in faceData {
            if var existing = studentMap[record.studentId] {
                existing.sampleCount += 1
                studentMap[record.studentId] = existing
            } else {
                studentMap[record.studentId] = CachedStudentInfo(
                    id: record.studentId,
                    name: record.studentName,
                    className: record.className,
                    sampleCount: 1
                )
            }
        }
        
        // Sort by name
        students = studentMap.values.sorted { $0.name < $1.name }
    }
    
    // MARK: - Download Face Data
    
    private func downloadFaceData() async {
        guard !schoolId.isEmpty else {
            errorMessage = "School ID not available"
            showError = true
            return
        }
        
        isDownloading = true
        statusMessage = ""
        downloadProgress = (0, 0)
        
        do {
            // Clear existing cache first
            try? cacheService.clearCache()
            
            // Download face data
            let faceData = try await firebaseService.downloadFaceData(schoolId: schoolId) { current, total in
                Task { @MainActor in
                    downloadProgress = (current, total)
                }
            }
            
            // Get version
            let version = try await firebaseService.getFaceDataVersion(schoolId: schoolId)
            
            // Save to cache
            try cacheService.saveCache(faceData, version: version)
            
            await MainActor.run {
                loadStudentsFromCache()
                statusMessage = "✅ Downloaded \(faceData.count) face records"
                isDownloading = false
                onDownloadComplete?()
            }
            
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                isDownloading = false
            }
        }
    }
}

// MARK: - Cached Student Info

struct CachedStudentInfo: Identifiable {
    let id: String
    let name: String
    let className: String?
    var sampleCount: Int
}

// MARK: - Cached Student Row

struct CachedStudentRow: View {
    let student: CachedStudentInfo
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Text(student.name.prefix(1).uppercased())
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(student.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    if let className = student.className {
                        Label(className, systemImage: "graduationcap.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Label("\(student.sampleCount) samples", systemImage: "photo.stack.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Status indicator
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    CachedStudentsView(
        cacheStatus: FaceDataCacheStatus(
            hasCache: true,
            recordCount: 25,
            studentCount: 5,
            lastUpdated: Date(),
            fileSizeKB: 150,
            version: 1
        ),
        onDismiss: {}
    )
}
