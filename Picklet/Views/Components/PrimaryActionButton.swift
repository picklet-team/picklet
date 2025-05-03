//
//  PrimaryActionButton.swift
//  Picklet
//
//  Created by al dente on 2025/04/26.
//

// Views/Components/PrimaryActionButton.swift

import SwiftUI

struct PrimaryActionButton: View {
    let title: String
    let action: () -> Void
    var backgroundColor: Color = Color.gray.opacity(0.2) // デフォルト薄グレー

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(backgroundColor)
                .cornerRadius(12)
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
        }
        .background(Color(UIColor.systemBackground)) // 背景透け防止
    }
}
