//
//  LibraryPickerView.swift
//  MyApp
//
//  Created by al dente on 2025/04/26.
//


import SwiftUI
import PhotosUI

struct LibraryPickerView: View {
    var onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        VStack {
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                VStack {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 80))
                        .padding()

                    Text("ライブラリから選ぶ")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(16)
                .padding()
            }
        }
        .onChange(of: selectedItem) { oldItem, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    onImagePicked(uiImage)
                    dismiss()
                }
            }
        }
    }
}
