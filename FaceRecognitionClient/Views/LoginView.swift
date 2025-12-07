//
//  LoginView.swift
//  FaceRecognitionClient
//
//  Created on November 28, 2025.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()  // ViewModel for login logic
    @EnvironmentObject var authService: AuthService  // Authentification state from the app
    @Environment(\.colorScheme) var colorScheme
    @State private var isPasswordVisible = false

    var body: some View {
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
                    // School Picker - Dynamic from Firestore
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Tuition Center")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)

                        if viewModel.isLoadingSchools {
                            HStack {
                                Image(systemName: "building.2")
                                    .foregroundColor(.blue)
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .padding(.horizontal, 8)
                                Text("Loading schools...")
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.separator), lineWidth: 0.5)
                            )
                        } else if viewModel.availableSchools.isEmpty {
                            // Fallback: show text field if no schools loaded
                            HStack {
                                Image(systemName: "building.2")
                                    .foregroundColor(.blue)
                                TextField("Enter school ID", text: $viewModel.schoolCode)
                                    .autocapitalization(.none)
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.separator), lineWidth: 0.5)
                            )
                        } else {
                            Menu {
                                ForEach(viewModel.availableSchools) { school in
                                    Button(action: {
                                        viewModel.schoolCode = school.id
                                    }) {
                                        HStack {
                                            Text(school.name)
                                            if viewModel.schoolCode == school.id {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Image(systemName: "building.2")
                                        .foregroundColor(.blue)
                                    if viewModel.schoolCode.isEmpty {
                                        Text("Select a center")
                                            .foregroundColor(.secondary)
                                    } else if let selectedSchool = viewModel
                                        .availableSchools.first(where: {
                                            $0.id == viewModel.schoolCode
                                        })
                                    {
                                        Text(selectedSchool.name)
                                            .foregroundColor(.primary)
                                    } else {
                                        Text(viewModel.schoolCode)
                                            .foregroundColor(.primary)
                                    }
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

                            if !viewModel.email.isEmpty {
                                Button {
                                    viewModel.email = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
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
                                Image(
                                    systemName: isPasswordVisible
                                        ? "eye.slash.fill" : "eye.fill"
                                )
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
        .task {
            await viewModel.loadSchools()
        }
    }
}

#Preview {
    LoginView()
}
