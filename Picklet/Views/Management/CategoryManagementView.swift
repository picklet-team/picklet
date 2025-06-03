import SwiftUI

// マスターデータ管理画面（全体管理）
struct CategoryManagementView: View {
  @EnvironmentObject var themeManager: ThemeManager
  @EnvironmentObject var categoryManager: CategoryManager
  @State private var showingAddDialog = false
  @State private var newCategoryName = ""
  @State private var editingCategory: Category?
  @State private var editCategoryName = ""

  var body: some View {
    List {
      Section("カテゴリ一覧") {
        ForEach(categoryManager.categories) { category in
          CategoryMasterRowView(
            category: category,
            onEdit: {
              editingCategory = category
              editCategoryName = category.name
            },
            onDelete: {
              // すべてのカテゴリが削除可能
              _ = categoryManager.deleteCategory(category)
            }
          )
        }
      }

      Section(footer: Text("すべてのカテゴリを追加・編集・削除できます。")) {
        EmptyView()
      }
    }
    .navigationTitle("カテゴリ管理")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button(action: { showingAddDialog = true }) {
          Image(systemName: "plus")
            .foregroundColor(themeManager.currentTheme.primaryColor)
        }
      }
    }
    .alert("新しいカテゴリ", isPresented: $showingAddDialog) {
      TextField("カテゴリ名", text: $newCategoryName)
      Button("追加") {
        if !newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          _ = categoryManager.addCategory(newCategoryName.trimmingCharacters(in: .whitespacesAndNewlines))
          newCategoryName = ""
        }
      }
      Button("キャンセル", role: .cancel) {
        newCategoryName = ""
      }
    }
    .alert("カテゴリ名を編集", isPresented: .constant(editingCategory != nil)) {
      TextField("カテゴリ名", text: $editCategoryName)
      Button("保存") {
        if let category = editingCategory,
           !editCategoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          var updatedCategory = category
          updatedCategory.name = editCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
          _ = categoryManager.updateCategory(updatedCategory)
          editingCategory = nil
          editCategoryName = ""
        }
      }
      Button("キャンセル", role: .cancel) {
        editingCategory = nil
        editCategoryName = ""
      }
    }
  }
}

struct CategoryMasterRowView: View {
  let category: Category
  let onEdit: () -> Void
  let onDelete: () -> Void
  @EnvironmentObject var themeManager: ThemeManager

  var body: some View {
    HStack {
      Text(category.name)
        .font(.body)

      Spacer()

      HStack(spacing: 16) {
        Button(action: onEdit) {
          Image(systemName: "pencil")
            .foregroundColor(themeManager.currentTheme.primaryColor)
        }

        // すべてのカテゴリで削除ボタンを表示
        Button(action: onDelete) {
          Image(systemName: "trash")
            .foregroundColor(.red)
        }
      }
    }
    .padding(.vertical, 4)
  }
}
