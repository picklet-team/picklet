import SwiftUI

// キーボードオーバーレイ管理用のビューモディファイア
struct KeyboardOverlayModifier: ViewModifier {
  @State private var isKeyboardVisible = false

  func body(content: Content) -> some View {
    ZStack {
      content

      // キーボードが表示されている時の透明オーバーレイ
      if isKeyboardVisible {
        Color.clear
          .contentShape(Rectangle()) // タップ可能にする
          .onTapGesture {
            hideKeyboard()
          }
          .zIndex(999) // 最前面に表示
          .ignoresSafeArea(.all) // 全画面をカバー
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
      isKeyboardVisible = true
    }
    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
      isKeyboardVisible = false
    }
  }

  private func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
  }
}

extension View {
  func keyboardOverlay() -> some View {
    self.modifier(KeyboardOverlayModifier())
  }
}

// 絵文字入力専用テキストフィールド
struct EmojiInputField: View {
  let currentEmoji: String
  let onEmojiChange: (String) -> Void
  @Binding var isEditing: Bool

  var body: some View {
    ZStack {
      // 現在の絵文字を常に表示
      Text(currentEmoji)
        .font(.system(size: 24))

      // 透明なテキストフィールド
      if isEditing {
        HiddenEmojiTextField(
          onEmojiInput: { emoji in
            onEmojiChange(emoji)
          },
          onFinish: {
            isEditing = false
          }
        )
        .frame(width: 32, height: 32)
      }
    }
  }
}

// カーソルなしの絵文字入力専用ビュー
struct HiddenEmojiTextField: View {
  let onEmojiInput: (String) -> Void
  let onFinish: () -> Void
  @State private var text: String = ""
  @FocusState private var isFocused: Bool

  var body: some View {
    TextField("", text: $text)
      .opacity(0.01) // ほぼ透明
      .focused($isFocused)
      .textFieldStyle(PlainTextFieldStyle())
      .onChange(of: text) { _, newValue in
        let filtered = newValue.filter { $0.isEmoji }
        if let emoji = filtered.first {
          onEmojiInput(String(emoji))
          text = "" // テキストフィールドをクリア（次の入力に備える）
        }
      }
      .onChange(of: isFocused) { _, focused in
        if !focused {
          onFinish()
        }
      }
      .onAppear {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          isFocused = true
        }
      }
  }
}

// テキスト入力フィールド
struct TextInputField: View {
  let currentText: String
  let placeholder: String
  let onTextChange: (String) -> Void
  @Binding var isEditing: Bool
  @FocusState.Binding var isFocused: Bool

  @State private var editingText: String = ""

  var body: some View {
    if isEditing {
      TextField(placeholder, text: $editingText)
        .font(.body)
        .fontWeight(.medium)
        .focused($isFocused)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .onSubmit {
          if !editingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            onTextChange(editingText.trimmingCharacters(in: .whitespacesAndNewlines))
          }
          isEditing = false
        }
        .onAppear {
          editingText = currentText
        }
        .onChange(of: isFocused) { _, focused in
          if !focused {
            isEditing = false
          }
        }
    } else {
      Text(currentText)
        .font(.body)
        .fontWeight(.medium)
        .foregroundColor(.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .cornerRadius(8)
    }
  }
}

// 絵文字判定用の拡張
extension Character {
  var isEmoji: Bool {
    guard let scalar = unicodeScalars.first else { return false }
    return scalar.properties.isEmoji && (scalar.value > 0x238C || unicodeScalars.count > 1)
  }
}
