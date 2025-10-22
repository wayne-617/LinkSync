//
//  LoginView.swift
//  LinkSync-iOS
//
//  Created by Wayne on 10/22/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var username = ""
    @State private var password = ""
    @State private var showingRegistrationModal = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                // App Title
                Text("LinkSync")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Connect to your computer")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Login Form
                VStack(spacing: 16) {
                    TextField("Username", text: $username)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: username) { _ in
                            authManager.clearError()
                        }
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: password) { _ in
                            authManager.clearError()
                        }
                    
                    Button(action: {
                        print("LoginView: Attempting to sign in with username: \(username)")
                        Task {
                            await authManager.signIn(username: username, password: password)
                            print("LoginView: Sign in completed, isAuthenticated: \(authManager.isAuthenticated)")
                        }
                    }) {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Login")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .disabled(authManager.isLoading || username.isEmpty || password.isEmpty)
                }
                .padding(.horizontal, 32)
                
                // Registration Link
                Button(action: {
                    showingRegistrationModal = true
                }) {
                    Text("How to register")
                        .foregroundColor(.blue)
                        .underline()
                }
                .padding(.top, 8)
                
                Spacer()
                
                // Error Message
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingRegistrationModal) {
            RegistrationModalView()
        }
    }
}

struct RegistrationModalView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Steps to Register:")
                    .font(.headline)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        Text("1.")
                            .fontWeight(.semibold)
                        Text("Install LinkSync Chrome extension on Chrome Web Store")
                    }
                    
                    HStack(alignment: .top) {
                        Text("2.")
                            .fontWeight(.semibold)
                        Text("Create an account through the extension")
                    }
                    
                    HStack(alignment: .top) {
                        Text("3.")
                            .fontWeight(.semibold)
                        Text("Log into the account here")
                    }
                }
                .font(.body)
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("Registration")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager.shared)
}
