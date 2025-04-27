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
    let image_url: String
    let created_at: String
}
