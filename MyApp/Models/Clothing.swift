//
//  Clothing.swift
//  MyApp
//
//  Created by al dente on 2025/04/25.
//

// Models/Clothing.swift
import Foundation

struct Clothing: Codable, Identifiable, Equatable {
    let id: UUID
    let user_id: UUID
    var name: String
    var category: String
    var color: String
    let created_at: String
    let updated_at: String
}
