import UIKit

class FlipPicImage {
    // MARK: Internal
    
    // Front is FaceTime Camera (front)
    var imageFrontCIImage: CIImage
    
    // Back is iSight HD Camera (back)
    var imageBackCIImage: CIImage
    var originalImageFrontCIImage: CIImage
    var originalImageBackCIImage: CIImage
    
    // UIImage Conversion Variables
    var imageFrontUIImage: UIImage
    var imageBackUIImage: UIImage
    var layout: Layout
    
    // MARK: Lifecycle
    
    init?(imageFront: UIImage, imageBack: UIImage, layout: Layout = Layout(rawValue: 0)!) {
        imageFrontUIImage = imageFront
        imageBackUIImage = imageBack
        self.layout = layout
        guard let frontCIImage = CIImage(image: imageFront) ?? imageFront.ciImage,
              let backCIImage = CIImage(image: imageBack) ?? imageBack.ciImage
        else {
            print("Error: Unable to create CIImage from UIImage")
            return nil // Fail initialization if CIImage creation fails
        }
        imageFrontCIImage = frontCIImage
        imageBackCIImage = backCIImage
        originalImageFrontCIImage = frontCIImage.copy() as! CIImage
        originalImageBackCIImage = backCIImage.copy() as! CIImage
    }
}
