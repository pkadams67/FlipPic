import AVFoundation
import Foundation

class RCT_CameraController {

	//////////////////////////////
	// Testing Ground
	//////////////////////////////

	var captureSession: AVCaptureSession?
	var stillImageOutput: AVCaptureStillImageOutput?
	var previewLayer: AVCaptureVideoPreviewLayer?
	let availableCameraDevices = AVCaptureDevice.devices(for: AVMediaType.video)

	//////////////////////////////
	// Testing Ground
	//////////////////////////////

	static func setupCamera(completion: () -> Void) {
		print("TEST: Camera Setup")
		completion()
	}

	static func takeFrontPicture(completion: (_ imageData: Data) -> Void) {
		print("TEST: Front Picture Taken")
		completion(Data())
	}

	static func takeBackPicture(completion: (_ imageData: Data) -> Void) {
		print("TEST: Back Picture Taken")
		completion(Data())
	}

	static func takeRCTImage(completion: (_ rCTImage: RCT_Image?) -> Void) { // TODO: REMOVE optional value of RCT_Image?

		// Call Take Front Picture
		// Call Take Back Picture (in correct order...)

		print("TEST: RCTImage Taken")
		completion(nil)
	}

	static func switchCamera(completion: () -> Void) {
		completion()
	}

	static func setFlash(flashOn: Bool) {}

	// METHODS FOR ENABLING/DISABLING/SWITCHING THE PREVIEW???

	// METHODS FOR SET FOCUS????
}
