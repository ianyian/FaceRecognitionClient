//
//  SettingsView.swift
//  FaceRecognitionClient
//
//  Created on December 1, 2025.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var matchThreshold: Double
    @State private var autoLockTimeout: Int
    @State private var isDarkMode: Bool
    @State private var cacheStatus: FaceDataCacheStatus = .empty
    @State private var isDownloading = false
    @State private var downloadProgress: (current: Int, total: Int) = (0, 0)
    @State private var statusMessage: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0  // 0=System, 1=Light, 2=Dark
    
    let schoolId: String
    let schoolName: String
    let onDownloadComplete: (() -> Void)?
    
    private let settingsService = SettingsService.shared
    private let cacheService = FaceDataCacheService.shared
    private let firebaseService = FirebaseService.shared
    
    init(schoolId: String, schoolName: String = "", onDownloadComplete: (() -> Void)? = nil) {
        self.schoolId = schoolId
        self.schoolName = schoolName
        self.onDownloadComplete = onDownloadComplete
        self._matchThreshold = State(initialValue: SettingsService.shared.matchThreshold)
        self._autoLockTimeout = State(initialValue: SettingsService.shared.autoLockTimeout)
        self._isDarkMode = State(initialValue: UserDefaults.standard.integer(forKey: "appearanceMode") == 2)
    }
    
    private var currentColorScheme: ColorScheme? {
        switch appearanceMode {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - Connection Section (MOVED TO TOP)
                Section {
                    HStack {
                        Image(systemName: "building.2")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(schoolName.isEmpty ? schoolId : schoolName)
                                .fontWeight(.medium)
                            if !schoolName.isEmpty {
                                Text(schoolId)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .font(.system(.caption, design: .monospaced))
                            }
                        }
                    }
                } header: {
                    Text("Connection")
                } footer: {
                    Text("Connected to this school's database for face data sync.")
                }
                
                // MARK: - Face Data Section
                Section {
                    // Cache Status
                    if cacheStatus.hasCache {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Face Data Loaded")
                                    .font(.headline)
                                Text("\(cacheStatus.recordCount) samples from \(cacheStatus.studentCount) students")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack {
                            Text("Last Downloaded")
                            Spacer()
                            if let date = cacheStatus.lastUpdated {
                                Text(date, format: .dateTime.month().day().hour().minute())
                                    .foregroundColor(.secondary)
                            } else {
                                Text("-")
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        HStack {
                            Text("Cache Size")
                            Spacer()
                            Text("\(cacheStatus.fileSizeKB) KB")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("\(cacheStatus.version)")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("No Face Data")
                                    .font(.headline)
                                Text("Download face data to enable recognition")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Download Button
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
                                Text(cacheStatus.hasCache ? "Re-download Face Data" : "Download Face Data")
                                    .fontWeight(.semibold)
                            }
                            
                            Spacer()
                        }
                    }
                    .disabled(isDownloading)
                    
                    // Clear Cache Button
                    if cacheStatus.hasCache {
                        Button(role: .destructive, action: {
                            clearCache()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear Cache")
                            }
                        }
                        .disabled(isDownloading)
                    }
                    
                    // Status Message
                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                } header: {
                    Text("Face Data")
                } footer: {
                    Text("Face data is stored locally on your device for offline recognition. Download updates when new students are registered.")
                }
                
                // MARK: - Recognition Settings Section
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Match Threshold")
                            Spacer()
                            Text(String(format: "%.0f%%", matchThreshold * 100))
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        
                        Slider(value: $matchThreshold, in: 0.4...1.0, step: 0.05) {
                            Text("Threshold")
                        } minimumValueLabel: {
                            Text("40%")
                                .font(.caption2)
                        } maximumValueLabel: {
                            Text("100%")
                                .font(.caption2)
                        }
                        .onChange(of: matchThreshold) { oldValue, newValue in
                            settingsService.matchThreshold = newValue
                        }
                    }
                    
                    // Quick presets
                    HStack(spacing: 12) {
                        ForEach([0.50, 0.60, 0.75, 0.90], id: \.self) { preset in
                            Button(action: {
                                matchThreshold = preset
                                settingsService.matchThreshold = preset
                            }) {
                                Text(String(format: "%.0f%%", preset * 100))
                                    .font(.caption)
                                    .fontWeight(matchThreshold == preset ? .bold : .regular)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(matchThreshold == preset ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(matchThreshold == preset ? .white : .primary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                } header: {
                    Text("Recognition Settings")
                } footer: {
                    Text("Higher threshold = more strict matching (fewer false positives). Lower threshold = more lenient (may match wrong person). Default: 60%")
                }
                
                // MARK: - Auto Lock Section
                Section {
                    Picker("Auto-lock Timer", selection: $autoLockTimeout) {
                        ForEach(SettingsService.autoLockOptions, id: \.value) { option in
                            Text(option.label).tag(option.value)
                        }
                    }
                    .onChange(of: autoLockTimeout) { oldValue, newValue in
                        settingsService.autoLockTimeout = newValue
                    }
                } header: {
                    Text("Camera")
                } footer: {
                    Text("Automatically lock the camera after this duration of inactivity. Saves battery when no one is scanning. Tap 'Start Camera' to resume.")
                }
                
                // MARK: - Appearance Section
                Section {
                    Picker("Appearance", selection: $appearanceMode) {
                        Text("System").tag(0)
                        Text("Light").tag(1)
                        Text("Dark").tag(2)
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Choose your preferred color scheme. System uses your device settings.")
                }
                
                // MARK: - App Info Section
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCacheStatus()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .preferredColorScheme(currentColorScheme)
    }
    
    // MARK: - Actions
    
    private func loadCacheStatus() {
        cacheStatus = cacheService.getCacheStatus()
    }
    
    private func downloadFaceData() async {
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
                loadCacheStatus()
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
    
    private func clearCache() {
        do {
            try cacheService.clearCache()
            loadCacheStatus()
            statusMessage = "Cache cleared"
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#Preview {
    SettingsView(schoolId: "main-tuition-center")
}
