import UIKit

class RCT_Image {

	// MARK: Lifecycle

	init(imageFront: UIImage, imageBack: UIImage, layout: Layout = Layout(rawValue: 0)!) {
		imageFrontUIImage = imageFront
		imageBackUIImage = imageBack
		imageFrontCIImage = CIImage(image: imageFront)!
		imageBackCIImage = CIImage(image: imageBack)!
		originalImageFrontCIImage = imageFrontCIImage.copy() as! CIImage
		originalImageBackCIImage = imageBackCIImage.copy() as! CIImage
		self.layout = layout
	}

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
}
