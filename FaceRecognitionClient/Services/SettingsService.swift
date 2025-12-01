//
//  SettingsService.swift
//  FaceRecognitionClient
//
//  Created on December 1, 2025.
//

import Foundation

class SettingsService {
    static let shared = SettingsService()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Keys
    
    private enum Keys {
        static let matchThreshold = "face_match_threshold"
        static let schoolId = "school_id"
        static let autoDownloadOnLogin = "auto_download_on_login"
    }
    
    // MARK: - Match Threshold
    
    /// Face match similarity threshold (0.0 - 1.0)
    /// Default: 0.75 (75%)
    var matchThreshold: Double {
        get {
            let value = defaults.double(forKey: Keys.matchThreshold)
            // Return default if not set (0.0 means not set)
            return value > 0 ? value : 0.75
        }
        set {
            // Clamp value between 0.5 and 1.0
            let clampedValue = min(max(newValue, 0.5), 1.0)
            defaults.set(clampedValue, forKey: Keys.matchThreshold)
            print("⚙️ Match threshold set to: \(String(format: "%.0f%%", clampedValue * 100))")
        }
    }
    
    /// Match threshold as percentage string
    var matchThresholdPercentage: String {
        return String(format: "%.0f%%", matchThreshold * 100)
    }
    
    // MARK: - School ID
    
    /// Current school ID
    /// Default: "main-tuition-center"
    var schoolId: String {
        get {
            return defaults.string(forKey: Keys.schoolId) ?? "main-tuition-center"
        }
        set {
            defaults.set(newValue, forKey: Keys.schoolId)
            print("⚙️ School ID set to: \(newValue)")
        }
    }
    
    // MARK: - Auto Download
    
    /// Whether to auto-download face data on login
    /// Default: false
    var autoDownloadOnLogin: Bool {
        get {
            return defaults.bool(forKey: Keys.autoDownloadOnLogin)
        }
        set {
            defaults.set(newValue, forKey: Keys.autoDownloadOnLogin)
            print("⚙️ Auto download on login: \(newValue)")
        }
    }
    
    // MARK: - Reset
    
    func resetToDefaults() {
        defaults.removeObject(forKey: Keys.matchThreshold)
        defaults.removeObject(forKey: Keys.autoDownloadOnLogin)
        // Don't reset schoolId
        print("⚙️ Settings reset to defaults")
    }
    
    private init() {}
}
