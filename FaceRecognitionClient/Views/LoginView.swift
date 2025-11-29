//
//  LoginView.swift
//  FaceRecognitionClient
//
//  Created on November 28, 2025.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [Color(red: 0.4, green: 0.49, blue: 0.92), Color(red: 0.46, green: 0.29, blue: 0.64)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Content
            VStack {
                Spacer()
                
                // Login Card
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("📚")
                            .font(.system(size: 60))
                        
                        Text("FaceCheck Client")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Tuition Center Login")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 10)
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        // School Code Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tuition Center Code")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
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
                                    Text(viewModel.schoolCode.isEmpty ? "Select a center..." : viewModel.schoolCode)
                                        .foregroundColor(viewModel.schoolCode.isEmpty ? .secondary : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                        }
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            TextField("staff@example.com", text: $viewModel.email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                            
                            SecureField("••••••••", text: $viewModel.password)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        
                        // Remember Me
                        Toggle(isOn: $viewModel.rememberMe) {
                            Text("Remember Me")
                                .font(.subheadline)
                        }
                        .padding(.top, 4)
                    }
                    
                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(12)
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    // Login Button
                    Button(action: {
                        Task {
                            await viewModel.login()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("LOGIN")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.top, 10)
                }
                .padding(30)
                .background(Color(.systemBackground))
                .cornerRadius(20)
                .shadow(radius: 20)
                .padding(.horizontal, 20)
                
                Spacer()
                Spacer()
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
