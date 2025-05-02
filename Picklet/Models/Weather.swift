//
//  Weather.swift
//  MyApp
//
//  Created by al dente on 2025/04/25.
//

struct Weather: Codable {
  let city: String
  let date: String  // yyyy-MM-dd
  let temperature: Double
  let condition: String  // 表示用（日本語: 曇りなど）
  let icon: String  // OpenWeatherのアイコン名
  let updated_at: String  // ISO8601形式の日時（キャッシュの有効性判定にも使える）
}
