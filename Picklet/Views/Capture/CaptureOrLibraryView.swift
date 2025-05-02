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
          CameraSquarePreviewView { image in
            didPickImage = true
            onImagePicked(image)
            dismiss()
          }
        } else {
          PhotoLibraryPickerView { image in
            didPickImage = true
            onImagePicked(image)
            dismiss()
          }
        }
      }
      .frame(maxHeight: .infinity)

      ModeSwitchBarView(
        isCameraSelected: showCamera,
        onCamera: { showCamera = true },
        onLibrary: { showCamera = false }
      )
      .ignoresSafeArea()
      .onDisappear {
        if !didPickImage {
          onCancel?()
        }
      }
    }
  }
}
