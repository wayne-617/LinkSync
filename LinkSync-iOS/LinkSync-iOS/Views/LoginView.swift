import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var username = ""
    @State private var password = ""
    @State private var showingRegistrationModal = false
    @State private var showingErrorAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.05), Color.accentColor.opacity(0.02)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // App branding
                    VStack(spacing: 12) {
                        Image(systemName: "link.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("linksync")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text("Connect to your computer")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                    
                    // Login card
                    VStack(spacing: 20) {
                        VStack(spacing: 16) {
                            // Username field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Username")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                TextField("Enter your username", text: $username)
                                    .textFieldStyle(.plain)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .padding(14)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .onChange(of: username) { _ in
                                        authManager.clearError()
                                    }
                                    .disabled(authManager.isLoading)
                                    .opacity(authManager.isLoading ? 0.6 : 1.0)
                            }
                            
                            // Password field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                
                                SecureField("Enter your password", text: $password)
                                    .textFieldStyle(.plain)
                                    .padding(14)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                                    .onChange(of: password) { _ in
                                        authManager.clearError()
                                    }
                                    .disabled(authManager.isLoading)
                                    .opacity(authManager.isLoading ? 0.6 : 1.0)
                            }
                        }
                        
                        // Login button
                        Button(action: {
                            print("LoginView: Attempting to sign in with username: \(username)")
                            Task {
                                await authManager.signIn(username: username, password: password)
                                print("LoginView: Sign in completed, isAuthenticated: \(authManager.isAuthenticated)")
                                
                                // Show alert if there's an error
                                if authManager.errorMessage != nil {
                                    showingErrorAlert = true
                                }
                            }
                        }) {
                            HStack(spacing: 8) {
                                if authManager.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Login")
                                        .fontWeight(.semibold)
                                    Image(systemName: "arrow.right")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(authManager.isLoading || username.isEmpty || password.isEmpty)
                        .opacity((username.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                        .padding(.top, 8)
                    }
                    .padding(28)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
                    .padding(.horizontal, 20)
                    
                    // Registration link
                    Button(action: {
                        showingRegistrationModal = true
                    }) {
                        HStack(spacing: 4) {
                            Text("New user?")
                                .foregroundColor(.secondary)
                            Text("How to register")
                                .foregroundColor(.accentColor)
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                    }
                    .padding(.top, 24)
                    
                    Spacer()
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingRegistrationModal) {
            RegistrationModalView()
        }
        .alert("Login Error", isPresented: $showingErrorAlert, presenting: authManager.errorMessage) { _ in
            Button("OK", role: .cancel) {
                authManager.clearError()
            }
        } message: { errorMessage in
            Text(errorMessage)
        }
    }
}

struct RegistrationModalView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with icon
                VStack(spacing: 16) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    
                    Text("Getting Started")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Follow these steps to create your account")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                .padding(.bottom, 32)
                
                // Steps
                VStack(spacing: 24) {
                    RegistrationStepView(
                        number: "1",
                        icon: "arrow.down.circle.fill",
                        title: "Install Extension",
                        description: "Get LinkSync Chrome extension from the Chrome Web Store"
                    )
                    
                    RegistrationStepView(
                        number: "2",
                        icon: "person.circle.fill",
                        title: "Create Account",
                        description: "Sign up through the extension with your email and password"
                    )
                    
                    RegistrationStepView(
                        number: "3",
                        icon: "checkmark.circle.fill",
                        title: "Login Here",
                        description: "Use your credentials to login on this app"
                    )
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Close button
                Button(action: {
                    dismiss()
                }) {
                    Text("Got it")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            })
        }
    }
}

struct RegistrationStepView: View {
    let number: String
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Step number badge
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Text(number)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundColor(.accentColor)
                        .font(.system(size: 16))
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager.shared)
}
