//
//  KeychainService.swift
//  FaceRecognitionClient
//
//  Created on November 28, 2025.
//

import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    
    private let service = "com.yourcompany.FaceRecognitionClient"
    
    private init() {}
    
    // MARK: - Save
    
    func save(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Load
    
    func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    // MARK: - Delete
    
    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
    
    // MARK: - Credential Management
    
    struct CredentialKeys {
        static let schoolCode = "schoolCode"
        static let email = "email"
    }
    
    func saveCredentials(schoolCode: String, email: String) {
        UserDefaults.standard.set(schoolCode, forKey: CredentialKeys.schoolCode)
        _ = save(key: CredentialKeys.email, value: email)
    }
    
    func loadSavedCredentials() -> (schoolCode: String?, email: String?) {
        let schoolCode = UserDefaults.standard.string(forKey: CredentialKeys.schoolCode)
        let email = load(key: CredentialKeys.email)
        return (schoolCode, email)
    }
    
    func clearCredentials() {
        UserDefaults.standard.removeObject(forKey: CredentialKeys.schoolCode)
        _ = delete(key: CredentialKeys.email)
    }
}
