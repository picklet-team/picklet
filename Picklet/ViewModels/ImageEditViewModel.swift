//
//  ImageEditViewModel.swift
//  Picklet
//
//  Created by al dente on 2025/05/03.
//

import SwiftUI

final class ImageEditViewModel: ObservableObject {
  @Published var imageSet: EditableImageSet
  @Published var isProcessing = false

  init(imageSet: EditableImageSet) {
      self.imageSet = imageSet
  }

  func runSegmentation() {
    guard !isProcessing else { return }
    isProcessing = true
    Task {
      if let output = await CoreMLService.shared.processImageSet(imageSet: imageSet) {
        self.imageSet = output
      }
      self.isProcessing = false
    }
  }
}
