//
//
//

import Foundation
import UIKit

extension UIImage {
  func resized(toMaxPixel maxPixel: CGFloat) -> UIImage {
    let aspectRatio = size.width / size.height
    var newSize: CGSize
    if aspectRatio > 1 {
      newSize = CGSize(width: maxPixel, height: maxPixel / aspectRatio)
    } else {
      newSize = CGSize(width: maxPixel * aspectRatio, height: maxPixel)
    }

    UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
    self.draw(in: CGRect(origin: .zero, size: newSize))
    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return resizedImage ?? self
  }
}
