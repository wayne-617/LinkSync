//
//  APIService.swift
//  LinkSync-iOS
//
//  Created by Wayne on 10/22/25.
//

import Foundation
import Amplify
import AWSCognitoAuthPlugin

struct MessageRequest: Codable {
    let userId: String
    let type: String
    let message: String
}

struct APIResponse: Codable {
    let success: Bool
    let message: String?
}

class APIService: ObservableObject {
    static let shared = APIService()
    
    private init() {}
    
    func uploadMessage(userId: String, content: String) async throws -> APIResponse {
        let type = isURL(content) ? "url" : "text"
        
        let request = MessageRequest(
            userId: userId,
            type: type,
            message: content
        )
        
        guard let url = URL(string: "\(Config.apiBaseURL)/messages") else {
            throw APIError.invalidURL
        }
        
        // Get the access token from Cognito
        let idToken = try await getIdToken()
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let jsonData = try JSONEncoder().encode(request)
            urlRequest.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            if httpResponse.statusCode == 200 {
                return APIResponse(success: true, message: "Message Sent")
            } else {
                throw APIError.serverError(httpResponse.statusCode)
            }
        } catch {
            if error is APIError {
                throw error
            } else {
                throw APIError.networkError(error)
            }
        }
    }
    
    /*private func getAccessToken() async throws -> String {
        do {
            let session = try await Amplify.Auth.fetchAuthSession()
            
            if let cognitoSession = session as? AWSAuthCognitoSession {
                let tokensResult = await cognitoSession.getCognitoTokens()
                
                switch tokensResult {
                case .success(let tokens):
                    return tokens.accessToken
                case .failure(let error):
                    print("Failed to get Cognito tokens: \(error)")
                    throw APIError.noAccessToken
                }
            } else {
                throw APIError.noAccessToken
            }
        } catch {
            print("Failed to get access token: \(error)")
            throw APIError.noAccessToken
        }
    }*/
    private func getIdToken() async throws -> String {
        do {
            // Fetch the current auth session
            let session = try await Amplify.Auth.fetchAuthSession()

            // Cast to Cognito-specific session
            guard let cognitoSession = session as? AWSAuthCognitoSession else {
                throw APIError.noAccessToken
            }

            // Get the tokens (async Result)
            let tokensResult = await cognitoSession.getCognitoTokens()

            switch tokensResult {
            case .success(let tokens):
                return tokens.idToken
            case .failure(let error):
                print("Failed to get Cognito tokens: \(error)")
                throw APIError.noAccessToken
            }
        } catch {
            print("Failed to fetch auth session: \(error)")
            throw APIError.noAccessToken
        }
    }

    
    private func isURL(_ text: String) -> Bool {
        let urlPattern = #"^https?://[^\s/$.?#].[^\s]*$"#
        let regex = try? NSRegularExpression(pattern: urlPattern)
        let range = NSRange(location: 0, length: text.utf16.count)
        return regex?.firstMatch(in: text, options: [], range: range) != nil
    }
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case networkError(Error)
    case noAccessToken
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code):
            return "Server error: \(code)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .noAccessToken:
            return "No access token available. Please sign in again."
        }
    }
}
