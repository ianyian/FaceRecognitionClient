//
//  CachedStudentsView.swift
//  FaceRecognitionClient
//
//  Shows list of students loaded in memory from face data cache
//  Created on December 4, 2025.
//

import SwiftUI

struct CachedStudentsView: View {
    let cacheStatus: FaceDataCacheStatus
    let onDismiss: () -> Void
    
    @State private var searchText = ""
    @State private var students: [CachedStudentInfo] = []
    
    private let cacheService = FaceDataCacheService.shared
    
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
            // Summary Section
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Students in Memory")
                            .font(.headline)
                        Text("\(cacheStatus.studentCount) students, \(cacheStatus.recordCount) face samples")
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
                        
                        if let lastUpdated = cacheStatus.lastUpdated {
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
