//
//  FaceRecognitionClientApp.swift
//  FaceRecognitionClient
//
//  Created by XJ on 28/11/2025.
//

import DeviceCheck  // For DeviceCheckProvider
import FirebaseAppCheck
import FirebaseCore
import SwiftUI

// Define an AppCheckProviderFactory to use DeviceCheck
class FaceRecognitionAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        #if DEBUG
            // For debug builds, use a debug provider
            let debugProvider = AppCheckDebugProvider(app: app)
            return debugProvider
        #else
            // For release builds, use DeviceCheck
            return AppCheckDeviceCheckProvider(app: app)
        #endif
    }
}

// AppDelegate for Firebase setup and App Check
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure Firebase first
        FirebaseApp.configure()

        // Set up App Check with the custom provider factory
        let providerFactory = FaceRecognitionAppCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)

        print("✅ Firebase configured and App Check set up.")
        return true
    }
}

@main
struct FaceRecognitionClientApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var authService = AuthService.shared  // Use the shared singleton instance

    var body: some Scene {
        WindowGroup {
            // Observe authService.isLoading for initial splash/loading
            // Then observe authService.isLoggedIn to show LoginView or CameraView
            ZStack {
                // Background - adapts to dark/light mode
                Color(.systemBackground)
                    .ignoresSafeArea()

                if authService.isLoading {
                    // Show a simple loading indicator while checking auth state
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Checking session...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    if authService.isLoggedIn {
                        // User is logged in, show CameraView
                        if let staff = authService.staff {
                            CameraView(
                                staff: staff,
                                // Provide dummy school until actual school is fetched if needed by CameraView.
                                // It should generally get school data based on staff.schoolId
                                school: authService.currentSchool
                                    ?? School(id: staff.schoolId, name: staff.schoolId),
                                onLogout: {
                                    Task { @MainActor in
                                        await authService.signOut()
                                    }
                                }
                            )
                            .environmentObject(authService)  // Pass authService to CameraView subtree
                        } else {
                            // Fallback if staff is somehow nil after isLoggedIn is true
                            LoginView()
                                .environmentObject(authService)
                        }
                    } else {
                        // User is not logged in, show LoginView
                        LoginView()
                            .environmentObject(authService)
                    }
                }
            }
        }
    }
}
