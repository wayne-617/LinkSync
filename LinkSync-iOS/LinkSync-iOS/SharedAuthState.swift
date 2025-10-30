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
}
