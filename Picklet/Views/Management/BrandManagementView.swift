import SwiftUI

struct BrandManagementView: View {
  @EnvironmentObject var themeManager: ThemeManager
  @EnvironmentObject var brandManager: BrandManager
  @State private var showingAddDialog = false
  @State private var newBrandName = ""
  @State private var editingBrand: Brand?
  @State private var editBrandName = ""

  var body: some View {
    List {
      Section("ブランド一覧") {
        ForEach(brandManager.brands) { brand in
          BrandRowView(
            brand: brand,
            onEdit: {
              editingBrand = brand
              editBrandName = brand.name
            },
            onDelete: {
              _ = brandManager.deleteBrand(brand)
            })
        }
      }

      Section(footer: Text("すべてのブランドを追加・編集・削除できます。")) {
        EmptyView()
      }
    }
    .navigationTitle("ブランド管理")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button(action: { showingAddDialog = true }) {
          Image(systemName: "plus")
            .foregroundColor(themeManager.currentTheme.primaryColor)
        }
      }
    }
    .alert("新しいブランド", isPresented: $showingAddDialog) {
      TextField("ブランド名", text: $newBrandName)
      Button("追加") {
        if !newBrandName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          _ = brandManager.addBrand(newBrandName.trimmingCharacters(in: .whitespacesAndNewlines))
          newBrandName = ""
        }
      }
      Button("キャンセル", role: .cancel) {
        newBrandName = ""
      }
    }
    .alert("ブランド名を編集", isPresented: .constant(editingBrand != nil)) {
      TextField("ブランド名", text: $editBrandName)
      Button("保存") {
        if let brand = editingBrand,
           !editBrandName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          var updatedBrand = brand
          updatedBrand.name = editBrandName.trimmingCharacters(in: .whitespacesAndNewlines)
          _ = brandManager.updateBrand(updatedBrand)
          editingBrand = nil
          editBrandName = ""
        }
      }
      Button("キャンセル", role: .cancel) {
        editingBrand = nil
        editBrandName = ""
      }
    }
  }
}

struct BrandRowView: View {
  let brand: Brand
  let onEdit: () -> Void
  let onDelete: () -> Void
  @EnvironmentObject var themeManager: ThemeManager

  var body: some View {
    HStack {
      Text(brand.name)
        .font(.body)

      Spacer()

      HStack(spacing: 16) {
        Button(action: onEdit) {
          Image(systemName: "pencil")
            .foregroundColor(themeManager.currentTheme.primaryColor)
        }

        Button(action: onDelete) {
          Image(systemName: "trash")
            .foregroundColor(.red)
        }
      }
    }
    .padding(.vertical, 4)
  }
}
