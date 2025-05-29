//
//  PrimaryActionButton.swift
//  Picklet
//
//  Created by al dente on 2025/04/26.
//

import SwiftUI

struct PrimaryActionButton: View {
  let title: String
  let action: () -> Void
  var backgroundColor: Color?

  @EnvironmentObject private var themeManager: ThemeManager

  init(title: String, backgroundColor: Color? = nil, action: @escaping () -> Void) {
    self.title = title
    self.backgroundColor = backgroundColor
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.headline)
        .foregroundColor(.primary)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(backgroundColor ?? themeManager.currentTheme.lightBackgroundColor)
        .cornerRadius(12)
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }
  }
}
