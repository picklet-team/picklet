//
//  ClothingImage.swift
//  MyApp
//
//  Created by al dente on 2025/04/27.
//


import Foundation

struct ClothingImage: Identifiable, Codable {
    let id: UUID
    let clothing_id: UUID
    let user_id: UUID
    let original_url: String
    let mask_url: String?
    let result_url: String?
    let created_at: String
    let updated_at: String
}
