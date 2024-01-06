import AVFoundation
import UIKit

class CameraViewController: UIViewController {
    @IBOutlet var previewView: UIView!
    @IBOutlet var shutterButton: UIButton!
    @IBOutlet var shutterBorderView: UIView!
    @IBOutlet var switchCameraButton: UIButton!
    @IBOutlet var flashOnOffButton: UIButton!
    
    var captureSession: AVCaptureSession!
    
    var backCamera: AVCaptureDevice!
    var frontCamera: AVCaptureDevice!
    var currentCaptureDevice: AVCaptureDevice!
    var backInput: AVCaptureInput!
    var frontInput: AVCaptureInput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var videoOutput: AVCaptureVideoDataOutput!
    var photoOutput: AVCapturePhotoOutput!
    
    var flipPicImage: FlipPicImage?
    
    var takePicture = false
    var backCameraOn = true
    var isCapturedBackPhoto = false
    
    var soundID: SystemSoundID = 0
    
    // Image variables
    var frontImage = UIImage()
    // swiftlint:disable redundant_optional_initialization
    var backImage: UIImage? = nil
    // swiftlint:enable redundant_optional_initialization
    
    // Tap-to-focus variables
    var tapToFocusRecognizer = UITapGestureRecognizer()
    var previewPointOfTap = CGPoint()
    var captureDevicePointOfTap = CGPoint()
    var focusBox = UIView()
    var focusBoxInner = UIView()
    var focusBoxSize = 65.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupButtons()
        let path = Bundle.main.path(forResource: "photoShutter2", ofType: "caf")
        let filePath = NSURL(fileURLWithPath: path!, isDirectory: false) as CFURL
        AudioServicesCreateSystemSoundID(filePath, &soundID)
        setupFocusBox()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkPermissions()
        stopSession()
        setupAndStartCaptureSession()
    }
    
    func setMockImage() {
        let frontImage = UIImage(named: "mock_selfie") ?? self.frontImage
        let backImage = UIImage(named: "mock_landscape") ?? self.frontImage
        guard let layout = Layout(rawValue: 0) else { return }
        self.flipPicImage = ImageController.createFlipPicImageFromImages(imageFront: frontImage, imageBack: backImage, layout: layout)
        if let editImageVC = self.storyboard?.instantiateViewController(withIdentifier: "EditImageViewController") as? EditImageViewController {
            editImageVC.flipPicImage = self.flipPicImage
            editImageVC.modalPresentationStyle = .fullScreen
            self.present(editImageVC, animated: true)
        }
    }
    
    @IBAction func switchCameraAction(_ sender: Any) {
        print("Switch Camera Button Tapped")
        previewView.isHidden = false
        UIView.transition(with: previewView,
                          duration: 0.5,
                          options: [.transitionFlipFromRight, .curveEaseInOut],
                          animations: {
            self.previewView.alpha = 0
        },
                          completion: { _ in
            self.switchCameraInput()
            UIView.animate(withDuration: 0.1) {
                self.previewView.alpha = 1
            }
        })
    }
}

// MARK: - Private Methods

extension CameraViewController {
    
    private func setupButtons() {
        let cornerRadius = shutterButton.frame.width / 2
        let borderWidth: CGFloat = 3
        let borderColor = UIColor.white.cgColor
        shutterButton.layer.cornerRadius = cornerRadius
        shutterBorderView.layer.cornerRadius = cornerRadius
        shutterButton.backgroundColor = .white
        shutterButton.alpha = 0.5
        shutterBorderView.backgroundColor = .clear
        shutterBorderView.layer.borderWidth = borderWidth
        shutterBorderView.layer.borderColor = borderColor
        shutterButton.addTarget(self, action: #selector(shutterButtonTapped(_:)), for: .touchUpInside)
        switchCameraButton.alpha = 1
        switchCameraButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath.camera"), for: .normal)
        view.addSubview(switchCameraButton)
        flashOnOffButton.alpha = 1
    }
    
    private func configureCircularButton(_ button: UIButton) {
        button.layer.cornerRadius = button.frame.width / 2
        button.backgroundColor = .white
        button.alpha = 0.5
    }
    
    private func setupAndStartCaptureSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession = AVCaptureSession()
            self.captureSession.beginConfiguration()
            if self.captureSession.canSetSessionPreset(.photo) {
                self.captureSession.sessionPreset = .photo
            }
            self.captureSession.automaticallyConfiguresCaptureDeviceForWideColor = true
            self.setupInputs()
            DispatchQueue.main.async {
                self.setupPreviewLayer()
            }
            self.setupOutput()
            self.captureSession.commitConfiguration()
            self.startSession()
        }
    }
    
    private func startSession() {
        if !captureSession.isRunning {
            captureSession.commitConfiguration()
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
                print("Session Started Running.")
            }
        }
    }
    
    private func stopSession() {
        if captureSession != nil {
            if captureSession.isRunning {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.captureSession.stopRunning()
                    print("Session Stopped Running.")
                }
            }
        }
    }
    
    private func setupInputs() {
        func createInput(for device: AVCaptureDevice?) -> AVCaptureDeviceInput? {
            guard let device = device,
                  let input = try? AVCaptureDeviceInput(device: device) else {
                return nil
            }
            return input
        }
        backInput = createInput(for: AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back))
        frontInput = createInput(for: AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front))
        for input in [backInput, frontInput] where input != nil && captureSession.canAddInput(input!) {
            captureSession.addInput(input!)
        }
        if backInput == nil && frontInput == nil {
            print("No cameras available")
        }
    }
    
    private func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewView.layer.insertSublayer(previewLayer, below: switchCameraButton.layer)
        previewLayer.frame = previewView.layer.frame
        previewLayer.videoGravity = .resizeAspectFill
        previewView.addGestureRecognizer(tapToFocusRecognizer)
    }
    
    private func setupOutput() {
        videoOutput = AVCaptureVideoDataOutput()
        let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            print("could not add photo output")
        }
        videoOutput.connections.first?.videoOrientation = .portrait
    }
    
    private func switchCameraInput() {
        // Don't let user spam the button, fun for the user, not fun for performance
        switchCameraButton.isUserInteractionEnabled = false
        
        // Reconfigure the input
        captureSession.beginConfiguration()
        if let currentInput = self.captureSession.inputs.first {
            backCameraOn = (currentInput as? AVCaptureDeviceInput)?.device.position == .back
        }
        if backCameraOn {
            captureSession.removeInput(backInput)
            captureSession.addInput(frontInput)
            backCameraOn = false
        } else {
            captureSession.removeInput(frontInput)
            captureSession.addInput(backInput)
            backCameraOn = true
        }
        
        // Deal with the connection again for portrait mode
        videoOutput.connections.first?.videoOrientation = .portrait
        
        // Mirror the video stream for front camera
        videoOutput.connections.first?.isVideoMirrored = !backCameraOn
        
        // Commit config
        captureSession.commitConfiguration()
        
        // Acitvate the camera button again
        switchCameraButton.isUserInteractionEnabled = true
    }
    
    // MARK: - Permissions
    
    func checkPermissions() {
        guard AVCaptureDevice.authorizationStatus(for: .video) != .authorized else {
            return
        }
        AVCaptureDevice.requestAccess(for: .video) { authorized in
            DispatchQueue.main.async {
                if authorized {
                } else {
                    switch AVCaptureDevice.authorizationStatus(for: .video) {
                    case .denied:
                        print("denied")
                    case .restricted:
                        print("restricted")
                    case .notDetermined:
                        print("notDetermined")
                    default:
                        print("@unknown")
                    }
                }
            }
        }
    }
    
    // MARK: - Focus Box
    
    private func focusBox(centerPoint: CGPoint) {
        let focusBoxScaleTransform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        let focusBoxScaleTransformShrink = CGAffineTransform(scaleX: 0.77, y: 0.77)
        
        focusBox.center = centerPoint
        focusBox.bounds.size = CGSize(width: focusBoxSize, height: focusBoxSize)
        focusBoxInner.bounds.size = CGSize(width: focusBoxSize, height: focusBoxSize)
        focusBox.alpha = 1.0
        focusBoxInner.backgroundColor = .white
        
        UIView.animate(withDuration: 0.5, animations: {
            self.focusBox.alpha = 1.0
            self.focusBoxInner.alpha = 0.4
            self.focusBox.transform = focusBoxScaleTransform
        }, completion: { _ in
            UIView.animate(withDuration: 0.5, animations: {
                self.focusBox.transform = focusBoxScaleTransformShrink
                self.focusBox.alpha = 0.0
                self.focusBoxInner.alpha = 0.0
            })
        })
    }
    
    private func setupFocusBox() {
        tapToFocusRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapToFocus(_:)))
        focusBox = UIView(frame: CGRect(x: 0.0, y: 0.0, width: focusBoxSize, height: focusBoxSize))
        focusBox.backgroundColor = .clear
        focusBox.layer.borderWidth = 1.0
        focusBox.layer.cornerRadius = CGFloat(focusBoxSize / 2)
        focusBox.layer.borderColor = UIColor.white.cgColor
        focusBox.alpha = 0.0
        focusBoxInner = UIView(frame: CGRect(x: 0.0, y: 0.0, width: focusBoxSize, height: focusBoxSize))
        focusBoxInner.center = CGPoint(x: focusBox.bounds.maxX / 2, y: focusBox.bounds.maxY / 2)
        focusBoxInner.layer.cornerRadius = CGFloat((focusBoxSize - 2) / 2)
        focusBoxInner.backgroundColor = .clear
        focusBoxInner.alpha = 0.0
        view.addSubview(focusBox)
        focusBox.addSubview(focusBoxInner)
    }
}

// MARK: - Button Actions

extension CameraViewController {
    
    @IBAction func shutterButtonTapped(_ sender: UIButton) {
        self.takePicture = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            AudioServicesPlaySystemSound(self.soundID)
            print("Back Image captured", self.frontImage, self.backImage ?? UIImage(), self.isCapturedBackPhoto)
            self.isCapturedBackPhoto = self.backImage != nil
            self.switchCameraInput()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
                self.takePicture = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.switchCameraInput()
                    print("Captured both images", self.frontImage, self.backImage ?? UIImage(), self.isCapturedBackPhoto)
                    let layout = Layout(rawValue: 0)!
                    self.flipPicImage = ImageController.createFlipPicImageFromImages(imageFront: self.frontImage, imageBack: self.backImage ?? UIImage(), layout: layout)
                    let editImageVC = self.storyboard?.instantiateViewController(withIdentifier: "EditImageViewController") as! EditImageViewController
                    editImageVC.flipPicImage = self.flipPicImage
                    editImageVC.modalPresentationStyle = .fullScreen
                    self.present(editImageVC, animated: true)
                }
            }
        }
    }
    
    @IBAction func iSightFlashButtonTapped(_ sender: UIButton) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = device.isTorchActive ? .off : .on
            sender.isSelected = device.isTorchActive
            print(device.isTorchActive ? "Turning Off iSight Flash" : "Turning On iSight Flash")
        } catch {
            print("Error: iSight Flash Button Tapped")
        }
        device.unlockForConfiguration()
    }
    
    @objc func tapToFocus(_ recognizer: UIGestureRecognizer) {
        let previewPoint = recognizer.location(in: view)
        focusBox(centerPoint: previewPoint)
        let captureDevicePoint = previewLayer.captureDevicePointConverted(fromLayerPoint: previewPoint)
        let deviceToFocus = backCameraOn ? backCamera : frontCamera
        guard let focusDevice = deviceToFocus else {
            print("No capture device available")
            return
        }
        guard focusDevice.isFocusPointOfInterestSupported else {
            showFocusErrorAlert("Focus point of interest not supported")
            return
        }
        do {
            try focusDevice.lockForConfiguration()
            focusDevice.focusPointOfInterest = captureDevicePoint
            focusDevice.unlockForConfiguration()
        } catch {
            print("Failed to lock configuration: \(error.localizedDescription)")
            showFocusErrorAlert("Error focusing camera")
        }
        if focusDevice.isFocusModeSupported(.autoFocus) {
            focusDevice.focusMode = .autoFocus
        }
    }
    
    func showFocusErrorAlert(_ message: String) {
        let alertController = UIAlertController(title: "Focus Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard takePicture,
              let cvBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvImageBuffer: cvBuffer)
        let uiImage = UIImage(ciImage: ciImage)
        self.isCapturedBackPhoto ? (frontImage = uiImage) : (backImage = uiImage)
        print("Image detected", uiImage)
        DispatchQueue.main.async {
            self.takePicture = false
        }
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            print("Could not capture still image: %@", error?.localizedDescription as Any)
            return
        }
        if isCapturedBackPhoto {
            frontImage = image
            switchCameraInput()
            isCapturedBackPhoto = false
            DispatchQueue.main.async {
                guard let layout = Layout(rawValue: 0) else { return }
                self.flipPicImage = ImageController.createFlipPicImageFromImages(imageFront: self.frontImage, imageBack: self.backImage ?? UIImage(), layout: layout)
                if let editImageVC = self.storyboard?.instantiateViewController(withIdentifier: "EditImageViewController") as? EditImageViewController {
                    editImageVC.flipPicImage = self.flipPicImage
                    editImageVC.modalPresentationStyle = .fullScreen
                    self.present(editImageVC, animated: true)
                }
            }
        } else {
            backImage = image
            isCapturedBackPhoto = true
            switchCameraInput()
            shutterButtonTapped(UIButton())
        }
    }
}
