// ClothingAddView.swift
import SwiftUI

struct ClothingAddView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: ClothingViewModel

    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var showCropView = false

    var body: some View {
        VStack {
            Button("写真から服を追加する") {
                showImagePicker = true
            }
            .padding()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(onImagePicked: { image in
                self.selectedImage = image
                self.showCropView = true
            })
        }
        .sheet(isPresented: $showCropView) {
            if let selectedImage = selectedImage {
                CropDestinationView(selectedImage: selectedImage)
                    .environmentObject(viewModel) // ✅ ここ追加
            }
        }
    }
}
