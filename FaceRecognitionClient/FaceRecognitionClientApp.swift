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
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        print("✅ Firebase configured successfully")
    }
    
    var body: some Scene {
        WindowGroup {
            LoginView()
        }
    }
}
