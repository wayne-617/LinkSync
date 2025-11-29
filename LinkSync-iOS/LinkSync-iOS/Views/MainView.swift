import SwiftUI

struct MainView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var apiService = APIService.shared
    @State private var messageText = ""
    @State private var isUploading = false
    @State private var showingProfileMenu = false
    @State private var showingErrorAlert = false
    @State private var showingTipsModal = false
    @State private var errorMessage = ""
    @State private var uploadSuccess = false
    
    // Detect device type
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var isIPad: Bool {
        horizontalSizeClass == .regular
    }
    
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
                
                GeometryReader { geometry in
                    ScrollView(.vertical, showsIndicators: false) {
                        // Center content horizontally on iPad
                        HStack {
                            if isIPad {
                                Spacer()
                            }
                            
                            VStack(spacing: 0) {
                                Spacer()
                                
                                // Header with logo and branding
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
                                    
                                    Text("Send to your computer")
                                        .font(isIPad ? .headline : .subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.bottom, isIPad ? 50 : 40)
                                
                                // Main content card
                                VStack(spacing: 20) {
                                    // Text input area
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack {
                                            Image(systemName: "text.alignleft")
                                                .foregroundColor(.accentColor)
                                                .font(.system(size: isIPad ? 16 : 14))
                                            
                                            Text("Text or URL")
                                                .font(isIPad ? .body : .subheadline)
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
                                                        .font(.system(size: isIPad ? 20 : 18))
                                                }
                                            }
                                        }
                                        
                                        TextField("Paste a link or type a message...", text: $messageText, axis: .vertical)
                                            .lineLimit(10)
                                            .padding(isIPad ? 16 : 12)
                                            .background(Color(.systemBackground))
                                            .cornerRadius(isIPad ? 14 : 12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: isIPad ? 14 : 12)
                                                    .stroke(
                                                        messageText.isEmpty ? Color.gray.opacity(0.2) : Color.accentColor.opacity(0.3),
                                                        lineWidth: 1.5
                                                    )
                                            )
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                            .font(isIPad ? .body : .callout)
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
                                                    .font(.system(size: isIPad ? 24 : 20))
                                                Text("Sent!")
                                                    .fontWeight(.semibold)
                                            } else {
                                                Image(systemName: "arrow.up.circle.fill")
                                                    .font(.system(size: isIPad ? 24 : 20))
                                                Text("Send to Computer")
                                                    .fontWeight(.semibold)
                                            }
                                        }
                                        .font(isIPad ? .body : .callout)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: isIPad ? 64 : 56)
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
                                        .cornerRadius(isIPad ? 16 : 14)
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
                                .padding(isIPad ? 32 : 24)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(isIPad ? 24 : 20)
                                .shadow(color: Color.black.opacity(0.06), radius: 15, x: 0, y: 5)
                                .padding(.horizontal, 20)
                                
                                // Tips button
                                Button(action: {
                                    showingTipsModal = true
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "lightbulb.fill")
                                            .font(.system(size: isIPad ? 16 : 14))
                                            .foregroundColor(.yellow)
                                        Text("Quick Tips")
                                            .font(isIPad ? .body : .subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.accentColor)
                                    }
                                    .padding(.vertical, isIPad ? 14 : 12)
                                    .padding(.horizontal, isIPad ? 24 : 20)
                                    .background(Color(.tertiarySystemBackground))
                                    .cornerRadius(20)
                                }
                                .padding(.top, isIPad ? 32 : 24)
                                
                                Spacer()
                            }
                            .frame(minHeight: geometry.size.height)
                            // Constrain width on iPad
                            .frame(maxWidth: isIPad ? 600 : .infinity)
                            
                            if isIPad {
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isIPad {
                        Menu {
                            Button(role: .destructive, action: {
                                Task {
                                    await authManager.signOut()
                                }
                            }) {
                                Label(authManager.isLoading ? "Signing Out..." : "Sign Out",
                                      systemImage: authManager.isLoading ? "arrow.clockwise" : "arrow.right.square")
                            }
                            .disabled(authManager.isLoading)
                        } label: {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.title2)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    } else {
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
            }
            .alert("Upload Failed", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .if(isIPad) { view in
                view.popover(isPresented: $showingProfileMenu) {
                    VStack(spacing: 0) {
                        Button(action: {
                            showingProfileMenu = false
                            Task {
                                await authManager.signOut()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                    .foregroundColor(.red)
                                Text("Sign Out")
                                    .foregroundColor(.red)
                                Spacer()
                            }
                            .padding()
                        }
                        .disabled(authManager.isLoading)
                        
                        Divider()
                        
                        Button(action: {
                            showingProfileMenu = false
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Cancel")
                                Spacer()
                            }
                            .padding()
                        }
                    }
                    .frame(width: 250)
                    .presentationCompactAdaptation(.popover)
                }
            } else: { view in
                view.confirmationDialog("Account", isPresented: $showingProfileMenu) {
                    Button(role: .destructive) {
                        Task {
                            await authManager.signOut()
                        }
                    } label: {
                        if authManager.isLoading {
                            Label("Signing Out...", systemImage: "arrow.clockwise")
                        } else {
                            Text("Sign Out")
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                }
            }
            .sheet(isPresented: $showingTipsModal) {
                TipsModalView()
            }
        }
        .navigationViewStyle(.stack) // Important for iPad
    }
    
    private func uploadMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        isUploading = true
        
        Task {
            guard let userId = await authManager.getUserId() else {
                await MainActor.run {
                    isUploading = false
                    errorMessage = "User not authenticated. Please sign in again."
                    showingErrorAlert = true
                }
                return
            }
            
            do {
                try await apiService.uploadMessage(userId: userId, content: trimmedText)
                await MainActor.run {
                    isUploading = false
                    uploadSuccess = true
                    
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
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var isIPad: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                VStack(spacing: isIPad ? 20 : 16) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: isIPad ? 60 : 48))
                        .foregroundColor(.yellow)

                    Text("Quick Tips")
                        .font(isIPad ? .largeTitle : .title2)
                        .fontWeight(.bold)
                
                    Text("Get the most out of LinkSync")
                        .font(isIPad ? .body : .subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, isIPad ? 50 : 40)
                .padding(.bottom, isIPad ? 40 : 32)
                
                ScrollView {
                    VStack(spacing: isIPad ? 24 : 20) {
                        TipCard(
                            icon: "link",
                            title: "Upload Instantly",
                            description: "Share URLs, notes, or any text snippet to your computer"
                        )

                        TipCard(
                            icon: "rectangle.on.rectangle",
                            title: "Use Share Extension",
                            description: "Share content from other apps directly to your computer"
                        )

                        TipCard(
                            icon: "heart",
                            title: "Pin For Quick Access",
                            description: "In the Share Sheet apps tap\n'More' → 'Edit' → ⊕ LinkSync"
                        )
                        
                        TipCard(
                            icon: "star",
                            title: "Love LinkSync? Rate Us!",
                            description: "Leave a review and share your feedback"
                        )
                    }
                    .padding(.horizontal, isIPad ? 32 : 24)
                }

                Spacer()

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

struct TipCard: View {
    let icon: String
    let title: String
    let description: String
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var isIPad: Bool {
        horizontalSizeClass == .regular
    }

    var body: some View {
        HStack(alignment: .top, spacing: isIPad ? 20 : 16) {
            Image(systemName: icon)
                .font(.system(size: isIPad ? 28 : 24))
                .foregroundColor(.accentColor)
                .frame(width: isIPad ? 48 : 40, height: isIPad ? 48 : 40)
                .background(Color.accentColor.opacity(0.15))
                .cornerRadius(isIPad ? 12 : 10)

            VStack(alignment: .leading, spacing: isIPad ? 6 : 4) {
                Text(title)
                    .font(isIPad ? .title3 : .headline)
                    .fontWeight(.semibold)

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

// Helper extension for conditional view modifiers
extension View {
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        @ViewBuilder then trueTransform: (Self) -> TrueContent,
        @ViewBuilder else falseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            trueTransform(self)
        } else {
            falseTransform(self)
        }
    }
}

#Preview {
    MainView()
        .environmentObject(AuthManager.shared)
}
