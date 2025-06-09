import SwiftUI

// MARK: - Keyboard Helper (Tap Only)

extension View {
  func dismissKeyboardOnTap() -> some View {
    contentShape(Rectangle())
      .onTapGesture {
        UIApplication.shared.endEditing()
      }
  }
}
