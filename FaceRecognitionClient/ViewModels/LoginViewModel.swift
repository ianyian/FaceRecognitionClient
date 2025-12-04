//
//  LoginViewModel.swift
//  FaceRecognitionClient
//
//  Created on November 28, 2025.
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth

class LoginViewModel: ObservableObject {
    @Published var schoolCode: String = ""
    @Published var email: String = ""
    @Published var password: String = ""
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isAuthenticated: Bool = false
    @Published var isCheckingSession: Bool = true  // Show loading while checking session
    
    @Published var currentStaff: Staff?
    @Published var currentSchool: School?
    
    private let firebaseService = FirebaseService.shared
    private let keychainService = KeychainService.shared
    
    init() {
        loadSavedCredentials()
        
        // Check for existing session on app launch
        Task {
            await checkExistingSession()
        }
    }
    
    // MARK: - Check Existing Session
    
    @MainActor
    func checkExistingSession() async {
        isCheckingSession = true
        
        // Check if user is already signed in with Firebase
        guard let currentUser = Auth.auth().currentUser else {
            print("📱 No existing session found")
            isCheckingSession = false
            return
        }
        
        print("📱 Found existing session for: \(currentUser.email ?? "unknown")")
        
        // Get saved school code
        let savedSchoolCode = keychainService.loadSavedCredentials().schoolCode ?? ""
        
        guard !savedSchoolCode.isEmpty else {
            print("⚠️ No saved school code, requiring re-login")
            try? Auth.auth().signOut()
            isCheckingSession = false
            return
        }
        
        do {
            // Load staff profile
            let staff = try await firebaseService.loadStaffProfile(uid: currentUser.uid)
            
            // Verify staff is still active
            guard staff.isActive else {
                print("⚠️ Staff account is inactive")
                try Auth.auth().signOut()
                isCheckingSession = false
                return
            }
            
            // Load school data
            let school = try await firebaseService.loadSchool(schoolId: savedSchoolCode)
            
            // Update last login time
            try await firebaseService.updateLastLogin(staffId: staff.id)
            
            // Restore session
            self.schoolCode = savedSchoolCode
            self.email = currentUser.email ?? ""
            self.currentStaff = staff
            self.currentSchool = school
            self.isAuthenticated = true
            
            print("✅ Session restored: \(staff.displayName) at \(school.name)")
            
        } catch {
            print("⚠️ Failed to restore session: \(error)")
            // Session is invalid, sign out
            try? Auth.auth().signOut()
        }
        
        isCheckingSession = false
    }
    
    // MARK: - Load Saved Credentials
    
    func loadSavedCredentials() {
        let (savedSchoolCode, savedEmail) = keychainService.loadSavedCredentials()
        
        if let schoolCode = savedSchoolCode {
            self.schoolCode = schoolCode
        }
        
        if let email = savedEmail {
            self.email = email
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
            
            // Load school data using the SELECTED school code from dropdown
            let school = try await firebaseService.loadSchool(schoolId: schoolCode)
            
            // Update last login time
            try await firebaseService.updateLastLogin(staffId: staff.id)
            
            // Always save credentials (remember me is default behavior)
            keychainService.saveCredentials(schoolCode: schoolCode, email: email)
            
            // Update state
            currentStaff = staff
            currentSchool = school
            isAuthenticated = true
            isLoading = false
            
            print("✅ Login successful: \(staff.displayName) at \(school.name)")
            
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
