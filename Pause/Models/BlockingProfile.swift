//
//  BlockingProfile.swift
//  Pause.
//
//  Created by Tristan Srebot on 04.01.26.
//

import Foundation
import FamilyControls

struct BlockingProfile: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var blockedAppTokens: Set<String> // Stored as strings for Codable
    var blockedCategoryTokens: Set<String> // Stored as strings for Codable
    var isActive: Bool
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        blockedAppTokens: Set<String> = [],
        blockedCategoryTokens: Set<String> = [],
        isActive: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.blockedAppTokens = blockedAppTokens
        self.blockedCategoryTokens = blockedCategoryTokens
        self.isActive = isActive
        self.createdAt = createdAt
    }
}
