import SwiftUI

struct TagManagementView: View {
  @EnvironmentObject var themeManager: ThemeManager
  @State private var tags: [String] = ["お気に入り", "仕事用", "デート用"] // 仮データ
  @State private var showingAddDialog = false
  @State private var newTagName = ""

  var body: some View {
    List {
      Section("タグマスター") {
        ForEach(tags, id: \.self) { tag in
          HStack {
            Text(tag)
              .font(.body)

            Spacer()

            Button(action: {
              tags.removeAll { $0 == tag }
            }) {
              Image(systemName: "trash")
                .foregroundColor(.red)
            }
          }
          .padding(.vertical, 4)
        }
      }

      Section(footer: Text("カスタムタグを管理できます。")) {
        EmptyView()
      }
    }
    .navigationTitle("タグ管理")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button(action: { showingAddDialog = true }) {
          Image(systemName: "plus")
            .foregroundColor(themeManager.currentTheme.primaryColor)
        }
      }
    }
    .alert("新しいタグ", isPresented: $showingAddDialog) {
      TextField("タグ名", text: $newTagName)
      Button("追加") {
        if !newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          tags.append(newTagName.trimmingCharacters(in: .whitespacesAndNewlines))
          newTagName = ""
        }
      }
      Button("キャンセル", role: .cancel) {
        newTagName = ""
      }
    }
  }
}
