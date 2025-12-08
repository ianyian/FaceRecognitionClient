//
//  SettingsView.swift
//  FaceRecognitionClient
//
//  Created on December 1, 2025.
//  Updated December 4, 2025 - Added avatar toggle and memory monitoring settings
//  Updated December 5, 2025 - Added live memory chart in Settings page
//

import Charts
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @State private var matchThreshold: Double
    @State private var autoLockTimeout: Int
    @State private var isDarkMode: Bool
    @State private var showAvatarsInList: Bool
    @State private var showMemoryMonitor: Bool
    @State private var showActivityLog: Bool
    @State private var showWhatsAppButton: Bool
    @State private var autoRefreshAfterStudentChange: Bool
    @State private var cacheStatus: FaceDataCacheStatus = .empty
    @State private var isDownloading = false
    @State private var downloadProgress: (current: Int, total: Int) = (0, 0)
    @State private var statusMessage: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var currentMemoryInfo: MemoryInfo?
    @State private var memoryHistory: [MemoryInfo] = []
    @State private var memoryTimer: Timer?
    @State private var showLogoutAlert = false

    @AppStorage("appearanceMode") private var appearanceMode: Int = 0  // 0=System, 1=Light, 2=Dark (default: System)

    let staff: Staff?
    let schoolId: String
    let schoolName: String
    let onLogout: (() -> Void)?
    let onDownloadComplete: (() -> Void)?

    private let settingsService = SettingsService.shared
    private let cacheService = FaceDataCacheService.shared
    private let firebaseService = FirebaseService.shared

    init(
        staff: Staff? = nil,
        schoolId: String,
        schoolName: String = "",
        onLogout: (() -> Void)? = nil,
        onDownloadComplete: (() -> Void)? = nil
    ) {
        self.staff = staff
        self.schoolId = schoolId
        self.schoolName = schoolName
        self.onLogout = onLogout
        self.onDownloadComplete = onDownloadComplete
        self._matchThreshold = State(initialValue: SettingsService.shared.matchThreshold)
        self._autoLockTimeout = State(initialValue: SettingsService.shared.autoLockTimeout)
        self._isDarkMode = State(
            initialValue: UserDefaults.standard.integer(forKey: "appearanceMode") == 2)
        self._showAvatarsInList = State(initialValue: SettingsService.shared.showAvatarsInList)
        self._showMemoryMonitor = State(initialValue: SettingsService.shared.showMemoryMonitor)
        self._showActivityLog = State(initialValue: SettingsService.shared.showActivityLog)
        self._showWhatsAppButton = State(initialValue: SettingsService.shared.showWhatsAppButton)
        self._autoRefreshAfterStudentChange = State(
            initialValue: SettingsService.shared.autoRefreshAfterStudentChange)
    }

    private var currentColorScheme: ColorScheme? {
        switch appearanceMode {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }

    private var roleDisplayName: String {
        guard let role = staff?.role else { return "-" }
        switch role {
        case .admin: return "Administrator"
        case .reception: return "Reception"
        case .teacher: return "Teacher"
        }
    }

    private var roleColor: Color {
        guard let role = staff?.role else { return .secondary }
        switch role {
        case .admin: return .red
        case .reception: return .blue
        case .teacher: return .green
        }
    }

    var body: some View {
        NavigationView {
            Form {
                // MARK: - User Profile Section
                Section {
                    // User Name
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(staff?.displayName ?? "Unknown User")
                                .fontWeight(.medium)
                            Text(staff?.email ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Role
                    HStack {
                        Text("Role")
                        Spacer()
                        Text(roleDisplayName)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(roleColor.opacity(0.15))
                            .foregroundColor(roleColor)
                            .cornerRadius(8)
                    }

                    // Assigned School
                    HStack {
                        Text("Assigned School")
                        Spacer()
                        if staff?.isGlobalUser == true {
                            HStack(spacing: 4) {
                                Image(systemName: "globe")
                                    .font(.caption)
                                Text("Global Access")
                            }
                            .foregroundColor(.purple)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.15))
                            .cornerRadius(8)
                        } else {
                            Text(staff?.schoolId ?? "-")
                                .foregroundColor(.secondary)
                        }
                    }

                    // Current School (for face data sync)
                    HStack {
                        Text("Current School")
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(schoolName.isEmpty ? schoolId : schoolName)
                                .foregroundColor(.secondary)
                            if !schoolName.isEmpty && schoolName != schoolId {
                                Text(schoolId)
                                    .font(.caption2)
                                    .foregroundColor(.secondary.opacity(0.7))
                            }
                        }
                    }
                } header: {
                    Text("User Profile")
                } footer: {
                    Text("Your account information and permissions.")
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
                                Text(
                                    "\(cacheStatus.recordCount) samples from \(cacheStatus.studentCount) students"
                                )
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
                                        Text(
                                            "\(downloadProgress.current) / \(downloadProgress.total)"
                                        )
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    }
                                }
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.title2)
                                Text(
                                    cacheStatus.hasCache
                                        ? "Re-download Face Data" : "Download Face Data"
                                )
                                .fontWeight(.semibold)
                            }

                            Spacer()
                        }
                    }
                    .disabled(isDownloading)

                    // Clear Cache Button
                    if cacheStatus.hasCache {
                        Button(
                            role: .destructive,
                            action: {
                                clearCache()
                            }
                        ) {
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
                    Text(
                        "Face data is stored locally on your device for offline recognition. Download updates when new students are registered."
                    )
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
                                    .background(
                                        matchThreshold == preset
                                            ? Color.blue : Color.gray.opacity(0.2)
                                    )
                                    .foregroundColor(matchThreshold == preset ? .white : .primary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                } header: {
                    Text("Recognition Settings")
                } footer: {
                    Text(
                        "Higher threshold = more strict matching (fewer false positives). Lower threshold = more lenient (may match wrong person). Default: 60%"
                    )
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
                    Text(
                        "Automatically lock the camera after this duration of inactivity. Saves battery when no one is scanning. Tap 'Start Camera' to resume."
                    )
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

                // MARK: - Display Settings Section
                Section {
                    Toggle(isOn: $showAvatarsInList) {
                        HStack {
                            Image(systemName: "person.crop.circle")
                                .foregroundColor(.purple)
                            Text("Show Avatars in Student List")
                        }
                    }
                    .onChange(of: showAvatarsInList) { oldValue, newValue in
                        settingsService.showAvatarsInList = newValue
                    }

                    Toggle(isOn: $showActivityLog) {
                        HStack {
                            Image(systemName: "text.alignleft")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Show Activity Log")
                                Text("Display troubleshooting log on camera screen")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onChange(of: showActivityLog) { oldValue, newValue in
                        settingsService.showActivityLog = newValue
                    }

                    Toggle(isOn: $showWhatsAppButton) {
                        HStack {
                            Image(systemName: "message.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("WhatsApp Parent Button")
                                Text("Show WhatsApp button on successful recognition")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onChange(of: showWhatsAppButton) { oldValue, newValue in
                        settingsService.showWhatsAppButton = newValue
                    }

                    Toggle(isOn: $autoRefreshAfterStudentChange) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Auto Refresh Face Data")
                                Text("Automatically refresh after creating/editing students")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onChange(of: autoRefreshAfterStudentChange) { oldValue, newValue in
                        settingsService.autoRefreshAfterStudentChange = newValue
                    }
                } header: {
                    Text("Display")
                } footer: {
                    Text(
                        "Activity log shows real-time recognition details. Auto refresh ensures face data is always up-to-date (turn OFF when adding many students)."
                    )
                }

                // MARK: - Memory Monitor Section
                Section {
                    // Current Memory Stats
                    if let memory = currentMemoryInfo {
                        HStack {
                            Image(systemName: "memorychip")
                                .foregroundColor(.orange)
                            Text("App Memory")
                            Spacer()
                            Text(memory.appUsageFormatted)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.orange)
                        }

                        HStack {
                            Image(systemName: "iphone")
                                .foregroundColor(.green)
                            Text("Available Memory")
                            Spacer()
                            Text(memory.deviceFreeFormatted)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.green)
                        }

                        HStack {
                            Image(systemName: "cpu")
                                .foregroundColor(.blue)
                            Text("Total Device Memory")
                            Spacer()
                            Text(memory.deviceTotalFormatted)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    } else {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading memory info...")
                                .foregroundColor(.secondary)
                        }
                    }

                    // Refresh button
                    Button {
                        refreshMemoryInfo()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh Memory Info")
                        }
                    }

                    Divider()

                    // Memory monitor toggle
                    Toggle(isOn: $showMemoryMonitor) {
                        HStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Live Memory Monitor")
                                Text("Shows real-time chart on this page")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .onChange(of: showMemoryMonitor) { oldValue, newValue in
                        settingsService.showMemoryMonitor = newValue
                        if newValue {
                            startLiveMonitoring()
                        } else {
                            stopLiveMonitoring()
                        }
                    }

                    // Live Memory Chart (shown when toggle is ON)
                    if showMemoryMonitor {
                        MemoryChartView(memoryHistory: memoryHistory)
                            .frame(height: 150)
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    }
                } header: {
                    Text("Memory")
                } footer: {
                    Text(
                        "Live monitor shows app memory usage as a floating chart. Stays visible while navigating between screens."
                    )
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(role: .destructive) {
                        showLogoutAlert = true
                    } label: {
                        Text("Logout")
                            .foregroundColor(.red)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCacheStatus()
                refreshMemoryInfo()
                // Start monitoring if already enabled
                if showMemoryMonitor {
                    startLiveMonitoring()
                }
            }
            .onDisappear {
                // Stop monitoring when leaving settings
                stopLiveMonitoring()
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Logout", role: .destructive) {
                    onLogout?()
                }
            } message: {
                Text("Are you sure you want to logout?")
            }
        }
        .preferredColorScheme(currentColorScheme)
    }

    // MARK: - Actions

    private func loadCacheStatus() {
        cacheStatus = cacheService.getCacheStatus()
    }

    private func refreshMemoryInfo() {
        currentMemoryInfo = getMemoryInfo()
    }

    private func startLiveMonitoring() {
        // Get initial reading
        let info = getMemoryInfo()
        currentMemoryInfo = info
        memoryHistory = [info]

        // Start timer for continuous updates
        memoryTimer?.invalidate()
        memoryTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            let newInfo = getMemoryInfo()
            currentMemoryInfo = newInfo
            memoryHistory.append(newInfo)

            // Keep last 300 samples (5 minutes)
            if memoryHistory.count > 300 {
                memoryHistory.removeFirst()
            }
        }
    }

    private func stopLiveMonitoring() {
        memoryTimer?.invalidate()
        memoryTimer = nil
    }

    private func getMemoryInfo() -> MemoryInfo {
        // Get app memory
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        let appMemory = kerr == KERN_SUCCESS ? Double(info.resident_size) / 1024.0 / 1024.0 : 0

        // Get device memory
        let totalMemory = Double(ProcessInfo.processInfo.physicalMemory) / 1024.0 / 1024.0

        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)

        var vmStats = vm_statistics64()
        var vmCount = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size)
        let vmKerr = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(vmCount)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &vmCount)
            }
        }
        let freeMemory =
            vmKerr == KERN_SUCCESS
            ? Double(vmStats.free_count + vmStats.inactive_count) * Double(pageSize) / 1024.0
                / 1024.0 : 0

        return MemoryInfo(
            timestamp: Date(),
            appUsedMB: appMemory,
            deviceFreeMB: freeMemory,
            deviceTotalMB: totalMemory
        )
    }

    private func downloadFaceData() async {
        isDownloading = true
        statusMessage = ""
        downloadProgress = (0, 0)

        do {
            // Clear existing cache first
            try? cacheService.clearCache()

            // Download face data
            let faceData = try await firebaseService.downloadFaceData(schoolId: schoolId) {
                current, total in
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

// MARK: - Memory Chart View

struct MemoryChartView: View {
    let memoryHistory: [MemoryInfo]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Chart header
            HStack {
                Text("📊 Live Memory Usage")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                if let latest = memoryHistory.last {
                    Text(latest.appUsageFormatted)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(memoryColor(for: latest.appUsedMB))
                }
            }

            // Chart
            if #available(iOS 16.0, *) {
                chartView
            } else {
                fallbackChartView
            }

            // Time axis labels
            HStack {
                Text("-5m")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)
                Spacer()
                Text("-2.5m")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)
                Spacer()
                Text("Now")
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    @available(iOS 16.0, *)
    private var chartView: some View {
        let maxValue = max((memoryHistory.map(\.appUsedMB).max() ?? 100) * 1.1, 50)
        let minValue = max((memoryHistory.map(\.appUsedMB).min() ?? 0) * 0.9, 0)

        return Chart {
            ForEach(Array(memoryHistory.enumerated()), id: \.element.id) { index, info in
                LineMark(
                    x: .value("Index", index),
                    y: .value("MB", info.appUsedMB)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.orange, Color.red.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 2))

                AreaMark(
                    x: .value("Index", index),
                    y: .value("MB", info.appUsedMB)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.4), Color.orange.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .chartYScale(domain: minValue...maxValue)
        .chartXScale(domain: 0...300)
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                AxisValueLabel {
                    if let mb = value.as(Double.self) {
                        Text("\(Int(mb))")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                    .foregroundStyle(Color.gray.opacity(0.3))
            }
        }
        .chartXAxis(.hidden)
        .frame(height: 100)
    }

    private var fallbackChartView: some View {
        GeometryReader { geometry in
            if !memoryHistory.isEmpty {
                let maxValue = memoryHistory.map(\.appUsedMB).max() ?? 100
                let minValue = max(0, (memoryHistory.map(\.appUsedMB).min() ?? 0) - 10)
                let range = max(maxValue - minValue, 1)

                Path { path in
                    let points = memoryHistory.enumerated().map { index, info -> CGPoint in
                        let x = CGFloat(index) / 300.0 * geometry.size.width
                        let y =
                            (1 - CGFloat((info.appUsedMB - minValue) / range))
                            * geometry.size.height
                        return CGPoint(x: x, y: y)
                    }

                    if let first = points.first {
                        path.move(to: first)
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [Color.orange, Color.red.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )
            }
        }
        .frame(height: 100)
    }

    private func memoryColor(for mb: Double) -> Color {
        if mb > 300 {
            return .red
        } else if mb > 150 {
            return .orange
        } else {
            return .green
        }
    }
}

#Preview {
    SettingsView(schoolId: "main-tuition-center")
}
