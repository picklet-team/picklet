//
//  EditableImageSet.swift
//  Picklet
//
//  Created by al dente on 2025/04/29.
//

import SwiftUI

struct EditableImageSet: Identifiable {
  let id: UUID
  let original: UIImage
  var originalUrl: String?
  var mask: UIImage?
  var maskUrl: String?
  var result: UIImage?
  var resultUrl: String?
  var isNew: Bool

  init(
    id: UUID = UUID(),
    original: UIImage,
    originalUrl: String? = nil,
    mask: UIImage? = nil,
    maskUrl: String? = nil,
    result: UIImage? = nil,
    resultUrl: String? = nil,
    isNew: Bool = true
  ) {
    self.id = id
    self.original = original
    self.originalUrl = originalUrl
    self.mask = mask
    self.maskUrl = maskUrl
    self.result = result
    self.resultUrl = resultUrl
    self.isNew = isNew
  }
}
