//
//  Staff.swift
//  FaceRecognitionClient
//
//  Created on November 28, 2025.
//

import FirebaseFirestore
import Foundation

enum StaffRole: String, Codable {
    case admin = "admin"
    case teacher = "teacher"
    case reception = "reception"
}

/// Permission actions that can be checked
enum StaffPermission: String {
    case view = "view"
    case create = "create"
    case edit = "edit"
    case delete = "delete"
}

/// Role-based permission matrix
/// - Admin: Full access - can view, create, edit, and delete all data
/// - Reception: Can view, create, and edit students (no delete permission)
/// - Teacher: View-only access to student data
private let rolePermissions: [StaffRole: Set<StaffPermission>] = [
    .admin: [.view, .create, .edit, .delete],
    .reception: [.view, .create, .edit],
    .teacher: [.view],
]

struct Staff: Identifiable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let role: StaffRole
    let schoolId: String
    let isActive: Bool
    let createdAt: Date?
    let lastLoginAt: Date?

    var displayName: String {
        return "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }

    var canAccessCamera: Bool {
        return isActive && (role == .admin || role == .reception)
    }

    /// Check if user has global access (can switch between schools)
    var isGlobalUser: Bool {
        return schoolId.lowercased() == "global"
    }

    // MARK: - Permission Checking

    /// Check if user has a specific permission
    /// - Parameter permission: The permission to check
    /// - Returns: true if user is active and has the permission
    func hasPermission(_ permission: StaffPermission) -> Bool {
        guard isActive else { return false }
        return rolePermissions[role]?.contains(permission) ?? false
    }

    /// Convenience: Can view student data (all roles)
    var canView: Bool {
        return hasPermission(.view)
    }

    /// Convenience: Can create students (Admin, Reception)
    var canCreate: Bool {
        return hasPermission(.create)
    }

    /// Convenience: Can edit students (Admin, Reception)
    var canEdit: Bool {
        return hasPermission(.edit)
    }

    /// Convenience: Can delete students (Admin only)
    var canDelete: Bool {
        return hasPermission(.delete)
    }

    // MARK: - Initialization

    init(
        id: String, email: String, firstName: String, lastName: String, role: StaffRole,
        schoolId: String, isActive: Bool = true, createdAt: Date? = nil, lastLoginAt: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.role = role
        self.schoolId = schoolId
        self.isActive = isActive
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
    }

    init(from document: DocumentSnapshot) throws {
        guard let data = document.data() else {
            throw NSError(
                domain: "Staff", code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Staff data not found"])
        }

        self.id = document.documentID

        guard let email = data["email"] as? String else {
            throw NSError(
                domain: "Staff", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing email"])
        }
        self.email = email

        let roleString = data["role"] as? String ?? "teacher"
        self.role = StaffRole(rawValue: roleString) ?? .teacher

        guard let schoolId = data["schoolId"] as? String else {
            throw NSError(
                domain: "Staff", code: 3, userInfo: [NSLocalizedDescriptionKey: "Missing schoolId"])
        }
        self.schoolId = schoolId

        // Handle isActive as Bool or Int
        if let isActiveBool = data["isActive"] as? Bool {
            self.isActive = isActiveBool
        } else if let isActiveInt = data["isActive"] as? Int {
            self.isActive = isActiveInt != 0
        } else {
            self.isActive = true
        }

        // Handle name fields - check for firstName/lastName or displayName
        if let firstName = data["firstName"] as? String,
            let lastName = data["lastName"] as? String
        {
            self.firstName = firstName
            self.lastName = lastName
        } else if let displayName = data["displayName"] as? String {
            let parts = displayName.split(separator: " ", maxSplits: 1)
            self.firstName = String(parts.first ?? "")
            self.lastName = parts.count > 1 ? String(parts[1]) : ""
        } else {
            let emailParts = email.split(separator: "@")
            self.firstName = String(emailParts.first ?? "User")
            self.lastName = ""
        }

        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        self.lastLoginAt = (data["lastLoginAt"] as? Timestamp)?.dateValue()
    }
}
