import UIKit

class ImageController {
    
    static func createFlipPicImage(imageFront: Data, imageBack: Data, layout: Layout = Layout(rawValue: 0)!) -> FlipPicImage {
        let image = FlipPicImage(imageFront: UIImage(data: imageFront)!, imageBack: UIImage(data: imageBack)!, layout: layout)
        return image!
    }
    
    static func createFlipPicImageFromImages(imageFront: UIImage, imageBack: UIImage, layout: Layout = Layout(rawValue: 0)!) -> FlipPicImage? {
        let flipPicImage = FlipPicImage(imageFront: imageFront, imageBack: imageBack, layout: layout)
        return flipPicImage
    }
    
    // MARK: Read
    
    static func dataToImage(imageData: Data) -> UIImage? {
        guard let image = UIImage(data: imageData) else {
            print("No Image from Data")
            return nil
        }
        return image
    }
    
    static func imageToData(image: UIImage) -> Data? {
        guard let imageData: Data = image.jpegData(compressionQuality: 1.0) else {
            print("No Data from Image")
            return nil
        }
        return imageData
    }
    
    // MARK: Update
    
    static func updateToOriginal(flipPicImage: FlipPicImage) {
        flipPicImage.layout = Layout(rawValue: 0)!
        flipPicImage.imageBackCIImage = flipPicImage.originalImageBackCIImage
        flipPicImage.imageFrontCIImage = flipPicImage.originalImageFrontCIImage
        print("Test: Updated Image to Original")
    }
}
