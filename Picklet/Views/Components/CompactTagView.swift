import SwiftUI

struct CompactTagView: View {
  let text: String
  let color: Color

  var body: some View {
    Text(text)
      .font(.caption)
      .fontWeight(.medium)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(color.opacity(0.1))
      .foregroundColor(color)
      .cornerRadius(8)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(color.opacity(0.3), lineWidth: 1))
  }
}
