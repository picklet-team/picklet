import SwiftUI

struct ManagementRowView: View {
  let icon: String
  let iconColor: Color
  let name: String
  let linkedItemsCount: Int
  let isInitialEdit: Bool // 初期編集状態フラグを追加
  let onIconChange: (String) -> Void
  let onNameChange: (String) -> Void
  let onDelete: () -> Void

  @State private var isEditingName = false
  @State private var isEditingIcon = false
  @State private var showingDeleteAlert = false
  @FocusState private var isNameFieldFocused: Bool

  var body: some View {
    HStack(spacing: 16) {
      // アイコン部分
      EmojiInputField(
        currentEmoji: icon,
        onEmojiChange: onIconChange,
        isEditing: $isEditingIcon)
        .frame(width: 32, height: 32)
        .onTapGesture {
          // 他のフィールドのフォーカスを外す
          isNameFieldFocused = false
          isEditingName = false

          // アイコン編集開始
          isEditingIcon = true
        }

      // 名前部分
      TextInputField(
        currentText: name,
        placeholder: "名前",
        onTextChange: onNameChange,
        isEditing: $isEditingName,
        isFocused: $isNameFieldFocused)
        .onTapGesture {
          if !isEditingName {
            // 他のフィールドのフォーカスを外す
            isEditingIcon = false

            // 名前編集開始
            isEditingName = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
              isNameFieldFocused = true
            }
          }
        }

      Spacer()

      // 紐づいているアイテム数
      if linkedItemsCount > 0 {
        HStack(spacing: 4) {
          Image(systemName: "link")
            .foregroundColor(.secondary)
            .font(.caption)

          Text("\(linkedItemsCount)")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray5))
        .cornerRadius(6)
      }

      // 削除ボタン
      Button(
        action: {
          if linkedItemsCount > 0 { return }
          showingDeleteAlert = true
        },
        label: {
          Image(systemName: "trash")
            .foregroundColor(linkedItemsCount > 0 ? .secondary : .red)
            .font(.system(size: 16))
            .frame(width: 32, height: 32)
        })
        .buttonStyle(.plain)
        .confirmDeletionAlert(isPresented: $showingDeleteAlert) {
          onDelete()
        }
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 16)
    .background(Color(.secondarySystemBackground))
    .cornerRadius(12)
    .onAppear {
      // 初期編集状態の場合、名前編集を開始
      if isInitialEdit {
        isEditingName = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          isNameFieldFocused = true
        }
      }
    }
  }
}
