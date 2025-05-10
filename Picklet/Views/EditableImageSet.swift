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
  var aimask: UIImage?
  var mask: UIImage?
  var result: UIImage?
  var isNew: Bool

  // Add URL properties
  var originalUrl: String?
  var maskUrl: String?
  var aimaskUrl: String?
  var resultUrl: String?

  init(
    id: UUID = UUID(),
    original: UIImage,
    originalUrl: String? = nil,
    aimask: UIImage? = nil,
    aimaskUrl: String? = nil,
    mask: UIImage? = nil,
    maskUrl: String? = nil,
    result: UIImage? = nil,
    resultUrl: String? = nil,
    isNew: Bool = true) {
    self.id = id
    self.original = original
    self.originalUrl = originalUrl
    self.aimask = aimask
    self.aimaskUrl = aimaskUrl
    self.mask = mask
    self.maskUrl = maskUrl
    self.result = result
    self.resultUrl = resultUrl
    self.isNew = isNew
  }
}
