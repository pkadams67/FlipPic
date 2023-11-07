import UIKit

class RCT_ImageController {

	static func createRCTImage(imageFront: Data, imageBack: Data, layout: Layout = Layout(rawValue: 0)!) -> RCT_Image {
		let image = RCT_Image(imageFront: UIImage(data: imageFront)!, imageBack: UIImage(data: imageBack)!, layout: layout)
		return image
	}

	static func createRCTImageFromImages(imageFront: UIImage, imageBack: UIImage, layout: Layout = Layout(rawValue: 0)!) -> RCT_Image? {
		let rctImage = RCT_Image(imageFront: imageFront, imageBack: imageBack, layout: layout)
		return rctImage
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

	static func updateToOriginal(rCTImage: RCT_Image) {
		rCTImage.layout = Layout(rawValue: 0)!
		rCTImage.imageBackCIImage = rCTImage.originalImageBackCIImage
		rCTImage.imageFrontCIImage = rCTImage.originalImageFrontCIImage
		print("Test: Updated Image to Original")
	}
}
