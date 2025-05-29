import SDWebImageSwiftUI
import SwiftUI

struct ClothingEditView: View {
  @EnvironmentObject var viewModel: ClothingViewModel // private を削除
  @Environment(\.dismiss) var dismiss // private を削除
  @Binding var clothing: Clothing
  let openPhotoPickerOnAppear: Bool
  let canDelete: Bool
  let isNew: Bool

  @State var editingSets: [EditableImageSet] = []
  @State var selectedImageSet: EditableImageSet? // private を削除
  @State var showPhotoPicker = false // private を削除
  @State var showDeleteConfirm = false // private を削除
  @State var isBackgroundLoading = false

  var body: some View {
    ZStack(alignment: .bottom) {
      mainContent
      saveButton
    }
    .ignoresSafeArea(.keyboard, edges: .bottom)
    .onAppear(perform: setupInitialData)
    .sheet(isPresented: $showPhotoPicker) { photoPickerSheet }
    .sheet(item: $selectedImageSet) { maskEditorSheet($0) }
    .confirmationDialog("本当に削除しますか？", isPresented: $showDeleteConfirm) {
      deleteConfirmationButtons
    }
  }

  private var mainContent: some View {
    VStack(spacing: 0) {
      customHeader
      scrollableContent
    }
    .onTapGesture(perform: dismissKeyboard)
    .navigationBarHidden(true)
  }

  private var customHeader: some View {
    VStack {
      TextField("名前", text: $clothing.name)
        .font(.title.weight(.bold))
        .padding(10)
        .cornerRadius(10)
        .multilineTextAlignment(.center)
        .overlay(
          Rectangle()
            .frame(height: 1)
            .padding(.horizontal, 40)
            .foregroundColor(Color.gray.opacity(0.3)),
          alignment: .bottom)
    }
    .background(Color(.systemBackground))
  }

  private var scrollableContent: some View {
    ScrollView {
      VStack {
        ImageListSection(
          imageSets: $editingSets,
          addAction: { showPhotoPicker = true },
          selectAction: prepareImageForEditing,
          isLoading: isBackgroundLoading)
          .padding(.top, 8)

        ClothingFormSection(
          clothing: $clothing,
          canDelete: canDelete,
          onDelete: { showDeleteConfirm = true })
      }
      .padding(.bottom, 80)
    }
  }

  private var saveButton: some View {
    VStack {
      PrimaryActionButton(title: "保存", action: saveChanges)
    }
    .padding(.horizontal)
    .padding(.bottom, 16)
  }

  private var photoPickerSheet: some View {
    CaptureOrLibraryView { image in
      addNewImageSet(image)
    }
  }

  private func maskEditorSheet(_ imageSet: EditableImageSet) -> some View {
    MaskEditorView(imageSet: bindingFor(imageSet))
      .onDisappear {
        updateImageCache()
      }
  }

  private var deleteConfirmationButtons: some View {
    Group {
      Button("削除する", role: .destructive) {
        Task { await deleteClothing() }
      }
      Button("キャンセル", role: .cancel) {}
    }
  }

  private func bindingFor(_ set: EditableImageSet) -> Binding<EditableImageSet> {
    guard let idx = editingSets.firstIndex(where: { $0.id == set.id }) else {
      fatalError("Invalid imageSet")
    }
    return $editingSets[idx]
  }

  private func dismissKeyboard() {
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder),
      to: nil, from: nil, for: nil)
  }
}
