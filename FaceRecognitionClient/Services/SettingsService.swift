//
//  SettingsService.swift
//  FaceRecognitionClient
//
//  Created on December 1, 2025.
//  Updated December 4, 2025 - Added avatar display and memory monitor settings
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
        static let autoLockTimeout = "auto_lock_timeout"
        static let showAvatarsInList = "show_avatars_in_list"
        static let showMemoryMonitor = "show_memory_monitor"
        static let showActivityLog = "show_activity_log"
        static let showWhatsAppButton = "show_whatsapp_button"
    }
    
    // MARK: - Match Threshold
    
    /// Face match similarity threshold (0.0 - 1.0)
    /// Default: 0.60 (60%)
    var matchThreshold: Double {
        get {
            let value = defaults.double(forKey: Keys.matchThreshold)
            // Return default if not set (0.0 means not set)
            return value > 0 ? value : 0.60
        }
        set {
            // Clamp value between 0.4 and 1.0 (allow lower threshold)
            let clampedValue = min(max(newValue, 0.4), 1.0)
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
    
    // MARK: - Auto Lock
    
    /// Auto-lock timeout in seconds (0 = disabled)
    /// Default: 5 seconds
    var autoLockTimeout: Int {
        get {
            let value = defaults.integer(forKey: Keys.autoLockTimeout)
            // Return default if not set (0 could be intentional "disabled")
            if defaults.object(forKey: Keys.autoLockTimeout) == nil {
                return 5  // Default 5 seconds
            }
            return value
        }
        set {
            defaults.set(newValue, forKey: Keys.autoLockTimeout)
            print("⚙️ Auto-lock timeout set to: \(newValue) seconds")
        }
    }
    
    /// Auto-lock timeout options for UI
    static let autoLockOptions: [(label: String, value: Int)] = [
        ("Off", 0),
        ("3 sec", 3),
        ("5 sec", 5),
        ("10 sec", 10),
        ("30 sec", 30)
    ]
    
    // MARK: - Avatar Display
    
    /// Whether to show avatars in student list (default OFF to save memory)
    var showAvatarsInList: Bool {
        get {
            // Default false (off) - check if key exists
            if defaults.object(forKey: Keys.showAvatarsInList) == nil {
                return false
            }
            return defaults.bool(forKey: Keys.showAvatarsInList)
        }
        set {
            defaults.set(newValue, forKey: Keys.showAvatarsInList)
            print("⚙️ Show avatars in list: \(newValue)")
        }
    }
    
    // MARK: - Memory Monitor
    
    /// Whether to show persistent memory monitor overlay
    /// NOTE: This is NOT persisted - always starts OFF to save resources
    private var _showMemoryMonitor = false
    
    var showMemoryMonitor: Bool {
        get {
            return _showMemoryMonitor
        }
        set {
            _showMemoryMonitor = newValue
            // Post notification so views can react
            NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: nil)
            print("⚙️ Show memory monitor: \(newValue) (session only, not saved)")
        }
    }
    
    // MARK: - Activity Log
    
    /// Whether to show activity log on main camera screen (default ON for troubleshooting)
    var showActivityLog: Bool {
        get {
            // Default true (on) - check if key exists
            if defaults.object(forKey: Keys.showActivityLog) == nil {
                return true  // Default ON
            }
            return defaults.bool(forKey: Keys.showActivityLog)
        }
        set {
            defaults.set(newValue, forKey: Keys.showActivityLog)
            print("⚙️ Show activity log: \(newValue)")
        }
    }
    
    // MARK: - WhatsApp Button
    
    /// Whether to show WhatsApp Parent button on success popup (default ON)
    var showWhatsAppButton: Bool {
        get {
            // Default true (on) - check if key exists
            if defaults.object(forKey: Keys.showWhatsAppButton) == nil {
                return true  // Default ON
            }
            return defaults.bool(forKey: Keys.showWhatsAppButton)
        }
        set {
            defaults.set(newValue, forKey: Keys.showWhatsAppButton)
            print("⚙️ Show WhatsApp button: \(newValue)")
        }
    }
    
    // MARK: - Reset
    
    func resetToDefaults() {
        defaults.removeObject(forKey: Keys.matchThreshold)
        defaults.removeObject(forKey: Keys.autoDownloadOnLogin)
        defaults.removeObject(forKey: Keys.autoLockTimeout)
        defaults.removeObject(forKey: Keys.showAvatarsInList)
        defaults.removeObject(forKey: Keys.showMemoryMonitor)
        defaults.removeObject(forKey: Keys.showActivityLog)
        defaults.removeObject(forKey: Keys.showWhatsAppButton)
        // Don't reset schoolId
        print("⚙️ Settings reset to defaults")
    }
    
    private init() {}
}
