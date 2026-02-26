//
//  UIImage+Filters.swift
//  Constructor
//
//  Created by Antonio Bonetti on 24/02/26.
//

import Foundation
import UIKit
import CoreImage

extension UIImage {
    func toGrayscale() -> UIImage {
        guard let ciImage = CIImage(image: self) else { return self }
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(0.0, forKey: kCIInputSaturationKey) // grayscale
        filter?.setValue(1.1, forKey: kCIInputContrastKey)
        filter?.setValue(0.0, forKey: kCIInputBrightnessKey)

        let context = CIContext()
        guard let output = filter?.outputImage,
              let cg = context.createCGImage(output, from: output.extent) else { return self }
        return UIImage(cgImage: cg)
    }
}
