//
//  ColorSchemeSelection.swift
//  Picklet
//
//  Created on 2025/05/06.
//

import SwiftUI

// カラースキームの選択肢を表すenum
enum ColorSchemeSelection: String, CaseIterable, Identifiable {
  case light
  case dark
  case system

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .light: return "Light"
    case .dark: return "Dark"
    case .system: return "System"
    }
  }

  var colorScheme: ColorScheme? {
    switch self {
    case .light: return .light
    case .dark: return .dark
    case .system: return nil
    }
  }
}
