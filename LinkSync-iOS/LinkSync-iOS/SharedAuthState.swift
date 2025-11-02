//
//  SharedAuthState.swift
//  LinkSync-iOS
//
//  Created by Wayne on 10/29/25.
//
import Foundation

class SharedAuthState {
    private static let suiteName = "group.com.waynelam.linksync"
    private static let isAuthenticatedKey = "isAuthenticated"
    private static let authTimestampKey = "authTimestamp"
    private static let userId = ""
    
    static func setAuthenticated(_ value: Bool) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.set(value, forKey: isAuthenticatedKey)
        defaults.synchronize()
        print("📝 Shared state: Set authenticated = \(value)")
    }
    
    static func isAuthenticated() -> Bool {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return false }
        let value = defaults.bool(forKey: isAuthenticatedKey)
        print("📖 Shared state: Read authenticated = \(value)")
        return value
    }
    
    static func setUserId(_ value: String) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.set(value, forKey: userId)
        defaults.synchronize()
        print("📝 Shared state: Set userId = \(value)")
    }
    
    static func getUserId() -> String? {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return ""
        }
        return defaults.string(forKey: userId) ?? ""
    }
    
    static func setAuthTimestamp(_ value: TimeInterval) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.set(value, forKey: authTimestampKey)
        defaults.synchronize()
        print("📝 Shared state: Set authTimestamp = \(value)")
    }
    
    static func getAuthTimestamp() -> TimeInterval {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return 0 }
        return defaults.double(forKey: authTimestampKey)
    }
}
