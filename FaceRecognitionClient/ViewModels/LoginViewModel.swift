//
//  LoginViewModel.swift
//  FaceRecognitionClient
//
//  Created on November 28, 2025.
//

import Foundation
import SwiftUI
import Combine

class LoginViewModel: ObservableObject {
    @Published var schoolCode: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var rememberMe: Bool = false
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isAuthenticated: Bool = false
    
    @Published var currentStaff: Staff?
    @Published var currentSchool: School?
    
    private let firebaseService = FirebaseService.shared
    private let keychainService = KeychainService.shared
    
    init() {
        loadSavedCredentials()
    }
    
    // MARK: - Load Saved Credentials
    
    func loadSavedCredentials() {
        let (savedSchoolCode, savedEmail) = keychainService.loadSavedCredentials()
        
        if let schoolCode = savedSchoolCode {
            self.schoolCode = schoolCode
        }
        
        if let email = savedEmail {
            self.email = email
            self.rememberMe = true
        }
    }
    
    // MARK: - Login
    
    @MainActor
    func login() async {
        guard validateInputs() else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Sign in with Firebase
            let staff = try await firebaseService.signIn(email: email, password: password)
            
            // Load school data
            let school = try await firebaseService.loadSchool(schoolId: staff.schoolId)
            
            // Update last login time
            try await firebaseService.updateLastLogin(staffId: staff.id)
            
            // Save credentials if remember me is checked
            if rememberMe {
                keychainService.saveCredentials(schoolCode: schoolCode, email: email)
            } else {
                keychainService.clearCredentials()
            }
            
            // Update state
            currentStaff = staff
            currentSchool = school
            isAuthenticated = true
            isLoading = false
            
            print("✅ Login successful: \(staff.displayName)")
            
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            print("❌ Login failed: \(error)")
        }
    }
    
    // MARK: - Logout
    
    func logout() {
        do {
            try firebaseService.signOut()
            isAuthenticated = false
            currentStaff = nil
            currentSchool = nil
            password = ""
            errorMessage = nil
            print("✅ Logout successful")
        } catch {
            errorMessage = "Failed to logout: \(error.localizedDescription)"
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
