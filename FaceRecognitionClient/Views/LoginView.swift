//
//  LoginView.swift
//  FaceRecognitionClient
//
//  Created on November 28, 2025.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var isPasswordVisible = false
    
    var body: some View {
        ZStack {
            // Background - adapts to dark/light mode
            Color(.systemBackground)
                .ignoresSafeArea()
            
            // Show loading while checking existing session
            if viewModel.isCheckingSession {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                // Content
                ScrollView {
                    VStack(spacing: 0) {
                        // Header Section with accent color
                        VStack(spacing: 16) {
                            // Icon
                            Image(systemName: "faceid")
                                .font(.system(size: 50, weight: .light))
                                .foregroundColor(.white)
                                .padding(25)
                                .background(
                                    LinearGradient(
                                        colors: [Color.blue, Color.blue.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
                            
                            Text("Tuition Center")
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 60)
                        .padding(.bottom, 40)
                        
                        // Form Fields
                        VStack(spacing: 20) {
                            // School Code Picker
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Tuition Center")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                Menu {
                                    Button("Main Tuition Center") {
                                        viewModel.schoolCode = "main-tuition-center"
                                    }
                                    Button("North Branch") {
                                        viewModel.schoolCode = "north-branch"
                                    }
                                    Button("South Branch") {
                                        viewModel.schoolCode = "south-branch"
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "building.2")
                                            .foregroundColor(.blue)
                                        Text(viewModel.schoolCode.isEmpty ? "Select a center" : viewModel.schoolCode)
                                            .foregroundColor(viewModel.schoolCode.isEmpty ? .secondary : .primary)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color(.separator), lineWidth: 0.5)
                                    )
                                }
                            }
                            
                            // Email Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                HStack {
                                    Image(systemName: "envelope")
                                        .foregroundColor(.blue)
                                    TextField("staff@example.com", text: $viewModel.email)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .textContentType(.emailAddress)
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.separator), lineWidth: 0.5)
                                )
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Password")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                HStack {
                                    Image(systemName: "lock")
                                        .foregroundColor(.blue)
                                    
                                    if isPasswordVisible {
                                        TextField("Enter password", text: $viewModel.password)
                                            .textContentType(.password)
                                    } else {
                                        SecureField("Enter password", text: $viewModel.password)
                                            .textContentType(.password)
                                    }
                                    
                                    Button(action: {
                                        isPasswordVisible.toggle()
                                    }) {
                                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(.separator), lineWidth: 0.5)
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Error Message
                        if let errorMessage = viewModel.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text(errorMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal, 24)
                        }
                        
                        // Login Button
                        Button(action: {
                            Task {
                                await viewModel.login()
                            }
                        }) {
                            HStack(spacing: 10) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "arrow.right.circle.fill")
                                    Text("Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: .blue.opacity(0.3), radius: 5, y: 3)
                        }
                        .disabled(viewModel.isLoading)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.isAuthenticated) {
            if let staff = viewModel.currentStaff, let school = viewModel.currentSchool {
                CameraView(staff: staff, school: school, onLogout: {
                    viewModel.logout()
                })
            }
        }
    }
}

#Preview {
    LoginView()
}
