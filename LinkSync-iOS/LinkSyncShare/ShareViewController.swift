import UIKit
import Amplify
import AWSCognitoAuthPlugin
import os.log

class ShareViewController: UIViewController {
    
    private let apiService = APIService.shared
    private let logger = Logger(subsystem: "com.wayne617.linksync", category: "ShareExtension")
    
    // UI Components
    private let containerView = UIView()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let statusLabel = UILabel()
    private let checkmarkLabel = UILabel()
    private let errorIconLabel = UILabel()
    private let infoIconLabel = UILabel()
    
    private let AUTH_INSTRUCTION_MESSAGE = """
        
        1. Swipe up and close all apps
        
        2. Open LinkSync and sign in again
        
        Done! Your Share Extension is now enabled and ready
        """
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        logger.info("🚀 ShareViewController viewDidLoad started")
        print("🚀 ShareViewController viewDidLoad started")
        
        //view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.backgroundColor = .clear
        setupUI()
        
        // Configure Amplify once when view loads
        //logger.info("📝 About to configure Amplify")
        //print("📝 About to configure Amplify")
        
        //AmplifyConfiguration.configure()
        
        //logger.info("✅ Amplify configuration completed")
        //print("✅ Amplify configuration completed")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        logger.info("👀 ShareViewController viewDidAppear")
        print("👀 ShareViewController viewDidAppear")
        
        Task {
            AmplifyConfiguration.configure()
            await processSharedContent()
        }
    }
    
    // MARK: - Setup UI
    
    private func setupUI() {
        // Container view with rounded corners
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 16
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Spinner
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        
        // Status label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        statusLabel.textColor = .label
        statusLabel.text = "Sending..."
        
        // Checkmark label (hidden initially)
        checkmarkLabel.translatesAutoresizingMaskIntoConstraints = false
        checkmarkLabel.textAlignment = .center
        checkmarkLabel.font = UIFont.systemFont(ofSize: 48)
        checkmarkLabel.text = "✓"
        checkmarkLabel.textColor = .systemGreen
        checkmarkLabel.alpha = 0
        
        // Error icon label (hidden initially)
        errorIconLabel.translatesAutoresizingMaskIntoConstraints = false
        errorIconLabel.textAlignment = .center
        errorIconLabel.font = UIFont.systemFont(ofSize: 36)
        errorIconLabel.text = "✕"
        errorIconLabel.textColor = .systemRed
        errorIconLabel.alpha = 0
        
        // Info icon label (hidden initially)
        /*infoIconLabel.translatesAutoresizingMaskIntoConstraints = false
        infoIconLabel.textAlignment = .center
        infoIconLabel.font = UIFont.systemFont(ofSize: 36)
        infoIconLabel.text = "ⓘ"
        infoIconLabel.textColor = .systemBlue
        infoIconLabel.alpha = 0*/
        
        view.addSubview(containerView)
        containerView.addSubview(spinner)
        containerView.addSubview(statusLabel)
        containerView.addSubview(checkmarkLabel)
        containerView.addSubview(errorIconLabel)
        //containerView.addSubview(infoIconLabel)
        
        NSLayoutConstraint.activate([
            // Container centered
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalToConstant: 200),
            containerView.heightAnchor.constraint(equalToConstant: 120),
            
            // Spinner position
            spinner.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            spinner.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            
            // Error icon position (aligned with spinner)
            errorIconLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            errorIconLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 25),
            
            // Info icon position (aligned with spinner)
            //infoIconLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            //infoIconLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            
            // Status label position below the icon/spinner area
            statusLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            // Checkmark centered
            checkmarkLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            checkmarkLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        spinner.startAnimating()
    }
    
    // MARK: - Process Shared Content
    
    private func processSharedContent() async {
        
        // 1️⃣ Validate Amplify session and get user ID
        let userId: String
        do {
            
            // Check if session is valid
            let session = try await Amplify.Auth.fetchAuthSession(options: .init(forceRefresh: true))
            
            guard session.isSignedIn else {
                logger.warning("Need to set up Share Extension")
                await showInfo(AUTH_INSTRUCTION_MESSAGE)
                return
            }
            
            
            guard SharedAuthState.isAuthenticated() else {
                logger.warning("❌ Not authenticated per shared state")
                print("❌ Not authenticated per shared state")
                await showError("Not signed in. Please sign in on the app")
                return
            }
            
            // Get user ID
            guard let id = await getUserId() else {
                logger.error("❌ Could not retrieve user ID")
                print("❌ Could not retrieve user ID")
                await showError("Authentication error")
                return
            }
            
            if id != SharedAuthState.getUserId() {
                logger.error("❌ Account changed. Please reload this app")
                print("❌ Account changed. Please reload this app")
                await showError("Account changed. Please reload this app")
                return
            }
            
            userId = id
            
        } catch {
            logger.error("❌ Auth check failed: \(error.localizedDescription)")
            print("❌ Auth check failed: \(error)")
            await showError("Please sign into the app first.")
            return
        }
        
        // 2️⃣ Extract shared content (text or URL)
        
        guard let content = await extractSharedContent() else {
            logger.warning("❌ No content to share")
            print("❌ No content to share")
            await showError("No content to share")
            return
        }
        
        //logger.info("✅ Extracted content: \(content)")
        //print("✅ Extracted content: \(content)")
        
        // 3️⃣ Upload message using your API service
        do {
            //logger.info("📤 Uploading message")
            //print("📤 Uploading message")
            
            try await apiService.uploadMessage(userId: userId, content: content)
            
            //logger.info("✅ Upload successful")
            //print("✅ Upload successful")
            
            await showSuccess()
        } catch {
            logger.error("❌ Upload error: \(error.localizedDescription)")
            print("❌ Upload error: \(error)")
            await showError("Failed to send content")
        }
    }
    
    private func extractSharedContent() async -> String? {
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            logger.warning("No extension context or input items")
            print("No extension context or input items")
            return nil
        }
        
        for item in inputItems {
            if let attachments = item.attachments {
                for attachment in attachments {
                    // 1️⃣ Try text first
                    if attachment.hasItemConformingToTypeIdentifier("public.text") {
                        do {
                            if let content = try await attachment.loadItem(forTypeIdentifier: "public.text") as? String {
                                return content
                            }
                        } catch {
                            logger.error("Failed to load text content: \(error.localizedDescription)")
                            print("❌ Failed to load text content: \(error)")
                        }
                    }
                    
                    // 2️⃣ Try URL next
                    if attachment.hasItemConformingToTypeIdentifier("public.url") {
                        do {
                            if let url = try await attachment.loadItem(forTypeIdentifier: "public.url") as? URL {
                                return url.absoluteString
                            }
                        } catch {
                            logger.error("Failed to load URL content: \(error.localizedDescription)")
                            print("❌ Failed to load URL content: \(error)")
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    private func getUserId() async -> String? {
        do {
            let user = try await Amplify.Auth.getCurrentUser()
            return user.userId
        } catch {
            logger.error("❌ Failed to get user ID: \(error.localizedDescription)")
            print("❌ Failed to get user ID: \(error)")
            return nil
        }
    }
    
    // MARK: - UI Feedback
    
    private func showSuccess() async {
        await MainActor.run {
            // Hide spinner and error icon
            spinner.stopAnimating()
            spinner.alpha = 0
            errorIconLabel.alpha = 0
            statusLabel.alpha = 0
            infoIconLabel.alpha = 0
            
            // Show checkmark with animation
            UIView.animate(withDuration: 0.3) {
                self.checkmarkLabel.alpha = 1
                self.checkmarkLabel.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            } completion: { _ in
                UIView.animate(withDuration: 0.2) {
                    self.checkmarkLabel.transform = .identity
                }
            }
        }
        
        // Wait and dismiss
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        await MainActor.run {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
    
    private func showError(_ message: String) async {
        await MainActor.run {
            // Hide spinner and checkmark, show error icon
            spinner.stopAnimating()
            spinner.alpha = 0
            checkmarkLabel.alpha = 0
            infoIconLabel.alpha = 0
            errorIconLabel.alpha = 1
            
            // Update status text
            statusLabel.text = message
            statusLabel.textColor = .systemRed
            statusLabel.alpha = 1
        }
        
        // Wait and dismiss
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        await MainActor.run {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
    
    /*private func showInfo(_ message: String) async {
        await MainActor.run {
            // Hide spinner and checkmark, show error icon
            spinner.stopAnimating()
            spinner.alpha = 0
            checkmarkLabel.alpha = 0
            errorIconLabel.alpha = 0
            infoIconLabel.alpha = 1
            
            // Update status text
            statusLabel.text = message
            statusLabel.textColor = .systemBlue
            statusLabel.alpha = 1
        }
        
        // Wait and dismiss
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        await MainActor.run {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }*/
    private func showInfo(_ message: String) async {
            await MainActor.run {
                // Stop the custom spinner and hide custom UI, which is still on screen
                //spinner.stopAnimating()
                //self.containerView.alpha = 0
                //self.view.backgroundColor = .clear // Make the background transparent to only show the alert
                
                // 1. Create the alert controller
                let alertController = UIAlertController(
                    title: "Enable LinkSync Share",
                    message: message,
                    preferredStyle: .alert
                )

                // 2. Define the action for the "OK" button
                let okAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                    // 3. Dismiss the entire share extension when OK is pressed
                    self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
                }

                // 4. Add the action to the controller
                alertController.addAction(okAction)

                // 5. Present the alert
                self.present(alertController, animated: true, completion: nil)
                spinner.stopAnimating()
                self.containerView.alpha = 0
            }
        }
}
