//
//  Student.swift
//  FaceRecognitionClient
//
//  Created on November 28, 2025.
//

import Foundation
import FirebaseFirestore

enum StudentStatus: String, Codable {
    case registered = "Registered"
    case pending = "Pending"
    case deleted = "Deleted"
}

struct Student: Codable, Identifiable {
    let id: String
    let firstName: String
    let lastName: String
    let className: String
    let parentId: String
    let parentName: String?
    let parentContact: String?
    let faceEncoding: String?
    let avatarUrl: String?
    let status: StudentStatus
    let registrationDate: Date?
    let updatedAt: Date?
    
    var fullName: String {
        return "\(firstName) \(lastName)"
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
        case parentId
        case parentName
        case parentContact
        case faceEncoding
        case avatarUrl
        case status
        case registrationDate
        case updatedAt
    }
    
    init(id: String, firstName: String, lastName: String, className: String, parentId: String, parentName: String? = nil, parentContact: String? = nil, faceEncoding: String? = nil, avatarUrl: String? = nil, status: StudentStatus = .registered, registrationDate: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.className = className
        self.parentId = parentId
        self.parentName = parentName
        self.parentContact = parentContact
        self.faceEncoding = faceEncoding
        self.avatarUrl = avatarUrl
        self.status = status
        self.registrationDate = registrationDate
        self.updatedAt = updatedAt
    }
    
    init(from document: DocumentSnapshot) throws {
        guard let data = document.data() else {
            throw NSError(domain: "Student", code: 404, userInfo: [NSLocalizedDescriptionKey: "Student data not found"])
        }
        
        self.id = document.documentID
        self.firstName = data["firstName"] as? String ?? ""
        self.lastName = data["lastName"] as? String ?? ""
        self.className = data["class"] as? String ?? ""
        self.parentId = data["parentId"] as? String ?? ""
        self.parentName = data["parentName"] as? String
        self.parentContact = data["parentContact"] as? String
        self.faceEncoding = data["faceEncoding"] as? String
        self.avatarUrl = data["avatarUrl"] as? String
        
        let statusString = data["status"] as? String ?? "Registered"
        self.status = StudentStatus(rawValue: statusString) ?? .registered
        
        self.registrationDate = (data["registrationDate"] as? Timestamp)?.dateValue()
        self.updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()
    }
}

struct StudentEncoding {
    let id: String
    let name: String
    let encoding: String
    let parentName: String?
    let parentContact: String?
}
