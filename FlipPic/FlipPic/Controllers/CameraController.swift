import AVFoundation
import Foundation

class CameraController {
    private var captureSession: AVCaptureSession?
    private var stillImageOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private let availableCameraDevices: [AVCaptureDevice] = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
        mediaType: .video,
        position: .unspecified
    ).devices
    
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
    
    // TODO: Evaluate if takeFlipPicImage can fail to produce a FlipPicImage. If a FlipPicImage is always generated, 
    // consider removing the optional and returning FlipPicImage directly. Ensure to handle errors appropriately and
    // check for backward compatibility with existing code.

    static func takeFlipPicImage(completion: (_ flipPicImage: FlipPicImage?) -> Void) {
        print("TEST: FlipPicImage Taken")
        completion(nil)
    }
    
    static func switchCamera(completion: () -> Void) {
        completion()
    }
    
    static func setFlash(flashOn: Bool) {}
    
}
