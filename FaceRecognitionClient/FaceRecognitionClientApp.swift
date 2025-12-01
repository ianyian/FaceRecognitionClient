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

// Wrapper view to handle appearance changes
struct ContentContainerView: View {
    @AppStorage("appearanceMode") private var appearanceMode: Int = 0
    
    var body: some View {
        LoginView()
            .preferredColorScheme(colorScheme)
    }
    
    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }
}
