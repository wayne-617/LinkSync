//
//  MainView.swift
//  LinkSync-iOS
//
//  Created by Wayne on 10/22/25.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var apiService = APIService.shared
    @State private var messageText = ""
    @State private var isUploading = false
    @State private var showingProfileMenu = false
    @State private var showingErrorAlert = false
    @State private var showingTipsModal = false // State is correctly defined
    @State private var errorMessage = ""
    @State private var uploadSuccess = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.05), Color.accentColor.opacity(0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // *** FIX: ADD SPACER HERE TO MATCH LOGINVIEW ***
                    Spacer()
                    
                    // Header with logo and branding (matching login screen)
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
                        
                        Text("Send to your computer")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    // *** FIX: REMOVE .padding(.top, 40) - Spacer handles vertical position ***
                    // .padding(.top, 40) <-- REMOVED
                    .padding(.bottom, 40)
                    
                    // Main content card
                    VStack(spacing: 20) {
                        // Text input area
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "text.alignleft")
                                    .foregroundColor(.accentColor)
                                    .font(.system(size: 14))
                                
                                Text("Text or URL")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if !messageText.isEmpty {
                                    Button(action: {
                                        withAnimation {
                                            messageText = ""
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 18))
                                    }
                                }
                            }
                            
                            TextField("Paste a link or type a message...", text: $messageText, axis: .vertical)
                                .lineLimit(1...10)
                                .padding(12)
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            messageText.isEmpty ? Color.gray.opacity(0.2) : Color.accentColor.opacity(0.3),
                                            lineWidth: 1.5
                                        )
                                )
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        // Upload button
                        Button(action: uploadMessage) {
                            HStack(spacing: 10) {
                                if isUploading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    Text("Uploading...")
                                } else if uploadSuccess {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                    Text("Sent!")
                                        .fontWeight(.semibold)
                                } else {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 20))
                                    Text("Send to Computer")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                Group {
                                    if uploadSuccess {
                                        Color.green
                                    } else if messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Color.gray.opacity(0.3)
                                    } else {
                                        LinearGradient(
                                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    }
                                }
                            )
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .shadow(
                                color: uploadSuccess ? Color.green.opacity(0.3) : (messageText.isEmpty ? .clear : Color.accentColor.opacity(0.3)),
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isUploading || uploadSuccess)
                        .animation(.easeInOut(duration: 0.2), value: messageText.isEmpty)
                        .animation(.easeInOut(duration: 0.3), value: uploadSuccess)
                    }
                    .padding(24)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(20)
                    .shadow(color: Color.black.opacity(0.06), radius: 15, x: 0, y: 5)
                    .padding(.horizontal, 20)
                    
                    // Tips button
                    Button(action: {
                        showingTipsModal = true // This sets the state to true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.yellow)
                            Text("Quick Tips")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.accentColor)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(20)
                    }
                    .padding(.top, 24)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingProfileMenu.toggle()
                    }) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.title3)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
            .alert("Upload Failed", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .confirmationDialog("Account", isPresented: $showingProfileMenu) {
                Button(role: .destructive) {
                    Task {
                        await authManager.signOut()
                    }
                } label: {
                    HStack {
                        if authManager.isLoading {
                            ProgressView()
                            Text("Signing Out...")
                        } else {
                            Text("Sign Out")
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
        }
        // FIX APPLIED HERE: Add the sheet modifier to present the modal
        .sheet(isPresented: $showingTipsModal) {
            TipsModalView()
        }
    }
    
    private func uploadMessage() {
        guard let userId = authManager.getCurrentUserId() else {
            errorMessage = "User not authenticated"
            showingErrorAlert = true
            return
        }
        
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        isUploading = true
        
        Task {
            do {
                _ = try await apiService.uploadMessage(userId: userId, content: trimmedText)
                await MainActor.run {
                    isUploading = false
                    uploadSuccess = true
                    
                    // Show success state for 1 second, then reset button (but keep text)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation {
                            uploadSuccess = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isUploading = false
                    errorMessage = error.localizedDescription
                    showingErrorAlert = true
                }
            }
        }
    }
}

struct TipsModalView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with icon
                VStack(spacing: 16) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.yellow)

                    Text("Quick Tips")
                        .font(.title2)
                        .fontWeight(.bold)
                
                    Text("Get the most out of LinkSync")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 32)
                
                // Tips
                VStack(spacing: 20) {
                    TipCard(
                        icon: "link",
                        title: "Share Links Instantly",
                        description: "Paste any URL and it will open automatically on your computer"
                    )
                    
                    TipCard(
                        icon: "doc.text",
                        title: "Transfer Text Quickly",
                        description: "Share notes, passwords, or any text snippet between devices"
                    )

                    TipCard(
                        icon: "rectangle.on.rectangle",
                        title: "Use Share Extension",
                        description: "Share content from other apps directly to your computer"
                    )

                    TipCard(
                        icon: "bolt.fill",
                        title: "Lightning Fast",
                        description: "Your content syncs in real-time with no delays"
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



struct TipCard: View {

    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.accentColor)
                .frame(width: 40, height: 40)
                .background(Color.accentColor.opacity(0.15))
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

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
    MainView()
        .environmentObject(AuthManager.shared)
}
