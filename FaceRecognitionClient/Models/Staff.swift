//
//  Staff.swift
//  FaceRecognitionClient
//
//  Created on November 28, 2025.
//

import Foundation
import FirebaseFirestore

enum StaffRole: String, Codable {
    case admin = "admin"
    case teacher = "teacher"
    case reception = "reception"
}

struct Staff: Codable, Identifiable {
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
        return "\(firstName) \(lastName)"
    }
    
    var canAccessCamera: Bool {
        return isActive && (role == .admin || role == .reception)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName
        case lastName
        case role
        case schoolId
        case isActive
        case createdAt
        case lastLoginAt
    }
    
    init(id: String, email: String, firstName: String, lastName: String, role: StaffRole, schoolId: String, isActive: Bool = true, createdAt: Date? = nil, lastLoginAt: Date? = nil) {
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
            throw NSError(domain: "Staff", code: 404, userInfo: [NSLocalizedDescriptionKey: "Staff data not found"])
        }
        
        self.id = document.documentID
        self.email = data["email"] as? String ?? ""
        self.firstName = data["firstName"] as? String ?? ""
        self.lastName = data["lastName"] as? String ?? ""
        
        let roleString = data["role"] as? String ?? "teacher"
        self.role = StaffRole(rawValue: roleString) ?? .teacher
        
        self.schoolId = data["schoolId"] as? String ?? ""
        self.isActive = data["isActive"] as? Bool ?? true
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        self.lastLoginAt = (data["lastLoginAt"] as? Timestamp)?.dateValue()
    }
}
