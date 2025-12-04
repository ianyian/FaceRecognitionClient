//
//  FaceRecognitionClientApp.swift
//  FaceRecognitionClient
//
//  Created by XJ on 28/11/2025.
//

import SwiftUI
import FirebaseCore

@main
struct FaceRecognitionClientApp: App {
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0  // 0=System, 1=Light, 2=Dark
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        print("✅ Firebase configured successfully")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentContainerView()
        }
    }
}

// Wrapper view to handle appearance changes and global overlays
struct ContentContainerView: View {
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    @State private var showMemoryMonitor: Bool = false
    
    var body: some View {
        ZStack {
            LoginView()
                .preferredColorScheme(colorScheme)
            
            // Global memory monitor overlay
            if showMemoryMonitor {
                MemoryMonitorOverlayContainer()
            }
        }
        .onAppear {
            // Check if memory monitor should be running
            showMemoryMonitor = SettingsService.shared.showMemoryMonitor
            if showMemoryMonitor {
                Task { @MainActor in
                    MemoryMonitorService.shared.startMonitoring()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            // React to settings changes
            let newValue = SettingsService.shared.showMemoryMonitor
            if newValue != showMemoryMonitor {
                showMemoryMonitor = newValue
                Task { @MainActor in
                    if newValue {
                        MemoryMonitorService.shared.startMonitoring()
                    } else {
                        MemoryMonitorService.shared.stopMonitoring()
                    }
                }
            }
        }
    }
    
    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }
}

// Container to observe MemoryMonitorService
struct MemoryMonitorOverlayContainer: View {
    @State private var memoryService = MemoryMonitorService.shared
    
    var body: some View {
        MemoryMonitorOverlay()
    }
}
