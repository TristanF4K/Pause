//
//  NFCTag.swift
//  Pause.
//
//  Created by Tristan Srebot on 04.01.26.
//

import Foundation
import FamilyControls

struct NFCTag: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var tagIdentifier: String
    var linkedAppTokens: Set<String> // Stored as strings for Codable
    var linkedCategoryTokens: Set<String> // Stored as strings for Codable
    var createdAt: Date
    var isActive: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        tagIdentifier: String,
        linkedAppTokens: Set<String> = [],
        linkedCategoryTokens: Set<String> = [],
        createdAt: Date = Date(),
        isActive: Bool = false
    ) {
        self.id = id
        self.name = name
        self.tagIdentifier = tagIdentifier
        self.linkedAppTokens = linkedAppTokens
        self.linkedCategoryTokens = linkedCategoryTokens
        self.createdAt = createdAt
        self.isActive = isActive
    }
}
