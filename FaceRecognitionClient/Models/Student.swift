//
//  Student.swift
//  FaceRecognitionClient
//
//  Created on November 28, 2025.
//  Updated on December 4, 2025 - Aligned schema with CoMa web app
//

import Foundation
import FirebaseFirestore

enum StudentStatus: String, Codable {
    case registered = "Registered"
    case pending = "Pending"
    case deleted = "Deleted"
}

struct Student: Codable, Identifiable, Hashable {
    let id: String
    let firstName: String
    let lastName: String
    let className: String
    
    // Parent info - stored directly in student document (aligned with CoMa web)
    let parentFirstName: String?
    let parentLastName: String?
    let parentPhone: String?
    
    // Legacy fields for backward compatibility (reading old records)
    let parentId: String?
    let parentName: String?       // Legacy: combined parent name
    let parentContact: String?    // Legacy: same as parentPhone
    
    let faceEncoding: String?
    let avatarUrl: String?
    let status: StudentStatus
    let registrationDate: Date?
    let updatedAt: Date?
    let createdAt: Date?
    let createdBy: String?
    let schoolId: String?
    
    // Hashable conformance (using id only)
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Student, rhs: Student) -> Bool {
        lhs.id == rhs.id
    }
    
    var fullName: String {
        return "\(firstName) \(lastName)"
    }
    
    /// Get parent full name - prefers new schema, falls back to legacy
    var parentFullName: String? {
        if let first = parentFirstName, let last = parentLastName, !first.isEmpty {
            return "\(first) \(last)"
        }
        return parentName
    }
    
    /// Get parent phone - prefers new schema, falls back to legacy
    var parentPhoneNumber: String? {
        if let phone = parentPhone, !phone.isEmpty {
            return phone
        }
        return parentContact
    }
    
    var isActive: Bool {
        return status == .registered
    }
    
    var hasFaceEncoding: Bool {
        return faceEncoding != nil && !faceEncoding!.isEmpty
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName
        case lastName
        case className = "class"
        case parentFirstName
        case parentLastName
        case parentPhone
        case parentId
        case parentName
        case parentContact
        case faceEncoding
        case avatarUrl
        case status
        case registrationDate
        case updatedAt
        case createdAt
        case createdBy
        case schoolId
    }
    
    init(id: String, firstName: String, lastName: String, className: String,
         parentFirstName: String? = nil, parentLastName: String? = nil, parentPhone: String? = nil,
         parentId: String? = nil, parentName: String? = nil, parentContact: String? = nil,
         faceEncoding: String? = nil, avatarUrl: String? = nil, status: StudentStatus = .registered,
         registrationDate: Date? = nil, updatedAt: Date? = nil, createdAt: Date? = nil,
         createdBy: String? = nil, schoolId: String? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.className = className
        self.parentFirstName = parentFirstName
        self.parentLastName = parentLastName
        self.parentPhone = parentPhone
        self.parentId = parentId
        self.parentName = parentName
        self.parentContact = parentContact
        self.faceEncoding = faceEncoding
        self.avatarUrl = avatarUrl
        self.status = status
        self.registrationDate = registrationDate
        self.updatedAt = updatedAt
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.schoolId = schoolId
    }
    
    init(from document: DocumentSnapshot) throws {
        guard let data = document.data() else {
            throw NSError(domain: "Student", code: 404, userInfo: [NSLocalizedDescriptionKey: "Student data not found"])
        }
        
        self.id = document.documentID
        self.firstName = data["firstName"] as? String ?? ""
        self.lastName = data["lastName"] as? String ?? ""
        self.className = data["class"] as? String ?? ""
        
        // New schema fields (CoMa web app format)
        self.parentFirstName = data["parentFirstName"] as? String
        self.parentLastName = data["parentLastName"] as? String
        self.parentPhone = data["parentPhone"] as? String
        
        // Legacy fields for backward compatibility
        self.parentId = data["parentId"] as? String
        self.parentName = data["parentName"] as? String
        self.parentContact = data["parentContact"] as? String
        
        self.faceEncoding = data["faceEncoding"] as? String
        self.avatarUrl = data["avatarUrl"] as? String
        
        let statusString = data["status"] as? String ?? "Registered"
        self.status = StudentStatus(rawValue: statusString) ?? .registered
        
        // Handle registrationDate - can be Timestamp or ISO string
        if let timestamp = data["registrationDate"] as? Timestamp {
            self.registrationDate = timestamp.dateValue()
        } else if let isoString = data["registrationDate"] as? String {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            self.registrationDate = formatter.date(from: isoString) ?? ISO8601DateFormatter().date(from: isoString)
        } else {
            self.registrationDate = nil
        }
        
        self.updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        self.createdBy = data["createdBy"] as? String
        self.schoolId = data["schoolId"] as? String
    }
}

struct StudentEncoding {
    let id: String
    let name: String
    let encoding: String
    let parentName: String?
    let parentContact: String?
}
