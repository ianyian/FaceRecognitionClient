//
//  LoginViewModel.swift
//  FaceRecognitionClient
//
//  Created on November 28, 2025.
//

import Combine
import FirebaseAuth
import Foundation
import SwiftUI

class LoginViewModel: ObservableObject {
    @Published var schoolCode: String = ""
    @Published var email: String = ""
    @Published var password: String = ""

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // Schools list for dropdown
    @Published var availableSchools: [School] = []
    @Published var isLoadingSchools: Bool = false

    private let firebaseService = FirebaseService.shared
    private let keychainService = KeychainService.shared

    init() {
        // Credentials will be loaded by LoginView's .onAppear if needed
        // Schools will be loaded by LoginView's .task
    }

    // MARK: - Load Schools

    @MainActor
    func loadSchools() async {
        print("🔄 LoginViewModel: Starting to load schools...")
        isLoadingSchools = true

        do {
            print("🔄 LoginViewModel: Calling firebaseService.loadAllSchools()...")
            availableSchools = try await firebaseService.loadAllSchools()
            print("📋 LoginViewModel: Loaded \(availableSchools.count) schools for selection")

            // If we have a saved school code, verify it's still valid
            if !schoolCode.isEmpty {
                if !availableSchools.contains(where: { $0.id == schoolCode }) {
                    print("⚠️ Saved school code '\(schoolCode)' not in available schools")
                    // Don't clear it - let user re-select
                }
            }
        } catch {
            print("❌ LoginViewModel: Failed to load schools: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            // Continue without schools list - user can still type school code
        }

        print("✅ LoginViewModel: Setting isLoadingSchools = false")
        isLoadingSchools = false
    }

    // MARK: - Login

    @MainActor
    func login() async {
        guard validateInputs() else { return }

        isLoading = true
        errorMessage = nil

        do {
            // Use AuthService to sign in (which includes school validation)
            _ = try await AuthService.shared.signIn(
                email: email, password: password, schoolId: schoolCode)

            // Always save credentials (remember me is default behavior)
            keychainService.saveCredentials(schoolCode: schoolCode, email: email)

            isLoading = false
            print("✅ Login successful via AuthService")

        } catch {  // Handle specific errors
            isLoading = false
            errorMessage = error.localizedDescription
            print("❌ Login failed: \(error)")
        }
    }

    // MARK: - Validation

    private func validateInputs() -> Bool {
        guard !schoolCode.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please select a tuition center"
            return false
        }

        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter your email"
            return false
        }

        guard email.contains("@") && email.contains(".") else {
            errorMessage = "Please enter a valid email address"
            return false
        }

        guard !password.isEmpty else {
            errorMessage = "Please enter your password"
            return false
        }

        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return false
        }

        return true
    }
}
