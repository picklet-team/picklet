//
//  CaptureOrLibraryView.swift
//  MyApp
//
//  Created by al dente on 2025/04/26.
//

import SwiftUI

struct CaptureOrLibraryView: View {
    var onImagePicked: (UIImage) -> Void
    var onCancel: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var showCamera = true
    @State private var didPickImage = false

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if showCamera {
                    CameraPreviewView(onImageCaptured: { image in
                        didPickImage = true
                        onImagePicked(image)
                        dismiss()
                    })
                } else {
                    LibraryPickerView(onImagePicked: { image in
                        didPickImage = true
                        onImagePicked(image)
                        dismiss()
                    })
                }
            }
            .frame(maxHeight: .infinity)

            HStack {
                modeButton(
                    icon: "camera",
                    title: "カメラ",
                    isSelected: showCamera,
                    action: { showCamera = true }
                )

                modeButton(
                    icon: "photo.on.rectangle",
                    title: "ライブラリ",
                    isSelected: !showCamera,
                    action: { showCamera = false }
                )
            }
            .padding()
            .background(Color(UIColor.systemBackground))
        }
        .ignoresSafeArea()
        .onDisappear {
            if !didPickImage {
                onCancel?()
            }
        }
    }

    private func modeButton(icon: String, title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.title)
                Text(title)
            }
            .foregroundColor(isSelected ? .blue : .gray)
            .frame(maxWidth: .infinity)
        }
    }
}
