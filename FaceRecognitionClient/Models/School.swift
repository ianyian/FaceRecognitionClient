//
//  School.swift
//  FaceRecognitionClient
//
//  Created on November 28, 2025.
//

import Foundation
import FirebaseFirestore

struct School: Codable, Identifiable {
    let id: String
    let name: String
    let address: String?
    let phone: String?
    let isActive: Bool
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case address
        case phone
        case isActive
        case createdAt
    }
    
    init(id: String, name: String, address: String? = nil, phone: String? = nil, isActive: Bool = true, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.address = address
        self.phone = phone
        self.isActive = isActive
        self.createdAt = createdAt
    }
    
    init(from document: DocumentSnapshot) throws {
        guard let data = document.data() else {
            throw NSError(domain: "School", code: 404, userInfo: [NSLocalizedDescriptionKey: "School data not found"])
        }
        
        self.id = document.documentID
        self.name = data["name"] as? String ?? ""
        self.address = data["address"] as? String
        self.phone = data["phone"] as? String
        self.isActive = data["isActive"] as? Bool ?? true
        self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
    }
}
