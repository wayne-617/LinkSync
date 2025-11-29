import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var username = ""
    @State private var password = ""
    @State private var showingRegistrationModal = false
    @State private var showingErrorAlert = false
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var isIPad: Bool {
        horizontalSizeClass == .regular
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.05), Color.accentColor.opacity(0.02)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Center content horizontally on iPad
                HStack {
                    if isIPad {
                        Spacer()
                    }
                    
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // App branding
                        VStack(spacing: isIPad ? 16 : 12) {
                            Image(systemName: "link.circle.fill")
                                .font(.system(size: isIPad ? 80 : 64))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("linksync")
                                .font(.system(size: isIPad ? 44 : 36, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text("Connect to your computer")
                                .font(isIPad ? .headline : .subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, isIPad ? 50 : 40)
                        
                        // Login card
                        VStack(spacing: 20) {
                            VStack(spacing: isIPad ? 20 : 16) {
                                // Username field
                                VStack(alignment: .leading, spacing: isIPad ? 10 : 8) {
                                    Text("Username")
                                        .font(isIPad ? .body : .subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Enter your username", text: $username)
                                        .textFieldStyle(.plain)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                        .padding(isIPad ? 16 : 14)
                                        .background(Color(.systemBackground))
                                        .cornerRadius(isIPad ? 14 : 12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: isIPad ? 14 : 12)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                        .font(isIPad ? .body : .callout)
                                        .disabled(authManager.isLoading)
                                        .opacity(authManager.isLoading ? 0.6 : 1.0)
                                }
                                
                                // Password field
                                VStack(alignment: .leading, spacing: isIPad ? 10 : 8) {
                                    Text("Password")
                                        .font(isIPad ? .body : .subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    
                                    SecureField("Enter your password", text: $password)
                                        .textFieldStyle(.plain)
                                        .padding(isIPad ? 16 : 14)
                                        .background(Color(.systemBackground))
                                        .cornerRadius(isIPad ? 14 : 12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: isIPad ? 14 : 12)
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                        .font(isIPad ? .body : .callout)
                                        .disabled(authManager.isLoading)
                                        .opacity(authManager.isLoading ? 0.6 : 1.0)
                                }
                            }
                            
                            // Error message display
                            if let errorMessage = authManager.errorMessage {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                        .font(.system(size: isIPad ? 16 : 14))
                                    
                                    Text(errorMessage)
                                        .font(isIPad ? .body : .subheadline)
                                        .foregroundColor(.red)
                                    
                                    Spacer()
                                }
                                .padding(isIPad ? 14 : 12)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            // Login button
                            Button(action: {
                                print("LoginView: Attempting to sign in with username: \(username)")
                                Task {
                                    await authManager.signIn(username: username, password: password)
                                    print("LoginView: Sign in completed, isAuthenticated: \(authManager.isAuthenticated)")
                                }
                            }) {
                                HStack(spacing: 8) {
                                    if authManager.isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Login")
                                            .fontWeight(.semibold)
                                            .font(isIPad ? .body : .callout)
                                        Image(systemName: "arrow.right")
                                            .font(isIPad ? .body : .callout)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: isIPad ? 58 : 52)
                                .background(
                                    LinearGradient(
                                        colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(isIPad ? 14 : 12)
                            }
                            .disabled(authManager.isLoading || username.isEmpty || password.isEmpty)
                            .opacity((username.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                            .padding(.top, 8)
                        }
                        .padding(isIPad ? 32 : 28)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(isIPad ? 24 : 20)
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
                            .font(isIPad ? .body : .subheadline)
                        }
                        .padding(.top, isIPad ? 32 : 24)
                        
                        Spacer()
                        Spacer()
                    }
                    .frame(maxWidth: isIPad ? 550 : .infinity)
                    
                    if isIPad {
                        Spacer()
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack) // Important for iPad
        .sheet(isPresented: $showingRegistrationModal) {
            RegistrationModalView()
        }
    }
}

struct RegistrationModalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var isIPad: Bool {
        horizontalSizeClass == .regular
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with icon
                VStack(spacing: isIPad ? 20 : 16) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: isIPad ? 60 : 48))
                        .foregroundColor(.accentColor)
                    
                    Text("Getting Started")
                        .font(isIPad ? .largeTitle : .title2)
                        .fontWeight(.bold)
                    
                    Text("Follow these steps to create your account")
                        .font(isIPad ? .body : .subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, isIPad ? 50 : 40)
                .padding(.bottom, isIPad ? 40 : 32)
                
                // Steps
                ScrollView {
                    VStack(spacing: isIPad ? 28 : 24) {
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
                    .padding(.horizontal, isIPad ? 32 : 24)
                }
                
                Spacer()
                
                // Close button
                Button(action: {
                    dismiss()
                }) {
                    Text("Got it")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: isIPad ? 56 : 50)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, isIPad ? 32 : 24)
                .padding(.bottom, isIPad ? 40 : 32)
            }
            .frame(maxWidth: isIPad ? 700 : .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(isIPad ? .title2 : .title3)
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
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var isIPad: Bool {
        horizontalSizeClass == .regular
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: isIPad ? 20 : 16) {
            // Step number badge
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: isIPad ? 48 : 40, height: isIPad ? 48 : 40)
                
                Text(number)
                    .font(.system(size: isIPad ? 22 : 18, weight: .bold))
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: isIPad ? 8 : 6) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundColor(.accentColor)
                        .font(.system(size: isIPad ? 18 : 16))
                    
                    Text(title)
                        .font(isIPad ? .title3 : .headline)
                        .fontWeight(.semibold)
                }
                
                Text(description)
                    .font(isIPad ? .body : .subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(isIPad ? 20 : 16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(isIPad ? 16 : 12)
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthManager.shared)
}
