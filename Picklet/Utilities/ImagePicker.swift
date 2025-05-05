//
//  ImagePicker.swift
//  Picklet
//
//  Created by al dente on 2025/04/25.
//

import PhotosUI

// Utilities/ImagePicker.swift
import SwiftUI

struct ImagePicker: UIViewControllerRepresentable {
  var onImagePicked: (UIImage) -> Void

  func makeUIViewController(context: Context) -> PHPickerViewController {
    var config = PHPickerConfiguration()
    config.selectionLimit = 1
    config.filter = .images

    let picker = PHPickerViewController(configuration: config)
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, PHPickerViewControllerDelegate {
    let parent: ImagePicker

    init(_ parent: ImagePicker) {
      self.parent = parent
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
      picker.dismiss(animated: true)

      guard let provider = results.first?.itemProvider else { return }
      if provider.canLoadObject(ofClass: UIImage.self) {
        provider.loadObject(ofClass: UIImage.self) { image, _ in
          if let uiImage = image as? UIImage {
            DispatchQueue.main.async {
              self.parent.onImagePicked(uiImage)
            }
          }
        }
      }
    }
  }
}
