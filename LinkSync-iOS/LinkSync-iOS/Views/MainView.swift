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
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Text Input Area
                VStack(alignment: .leading, spacing: 8) {
                    Text("Enter text or URL:")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextEditor(text: $messageText)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
                .padding(.horizontal, 20)
                
                // Upload Button
                Button(action: uploadMessage) {
                    if isUploading {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            Text("Uploading...")
                        }
                    } else {
                        Text("Upload to Computer")
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isUploading)
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .navigationTitle("LinkSync")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(action: {
                showingProfileMenu.toggle()
            }) {
                Image(systemName: "person.circle")
                    .font(.title2)
            })
            .alert("Success", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    messageText = ""
                }
            } message: {
                Text("Uploaded successfully")
            }
            .alert("Upload Failed", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .confirmationDialog("Profile", isPresented: $showingProfileMenu) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        await authManager.signOut()
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
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
                    showingSuccessAlert = true
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

#Preview {
    MainView()
        .environmentObject(AuthManager.shared)
}
