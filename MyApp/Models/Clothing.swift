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
    var image_url: String
    let created_at: String
}
