import AVFoundation
import UIKit

var hasTakenFirstPicture: Bool?
var soundID: SystemSoundID = 0

// A Delay Function

func delay(seconds: Double, completion: @escaping () -> Void) {
	DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
		completion()
	}
}

// MARK: - RCT_CameraViewController

class RCT_CameraViewController: UIViewController {

	// MARK: - Variables

	// Bool for Switching Previews
	var backCameraIsPreview = true
	var rCTImage: RCT_Image? = nil
	var captureSession = AVCaptureSession()
	var frontInput: AVCaptureDeviceInput?
	var backInput: AVCaptureDeviceInput?
	var frontCaptureDevice: AVCaptureDevice?
	var backCaptureDevice: AVCaptureDevice?
	var currentCaptureDevice: AVCaptureDevice?
//	var stillImageOutput = AVCaptureStillImageOutput()
    var photoOutput: AVCapturePhotoOutput?
    
    var backCameraOutput: AVCapturePhotoOutput?
    var frontCameraOutput: AVCapturePhotoOutput?
    
	let previewView = UIView()
	var previewLayer = AVCaptureVideoPreviewLayer()

	// Flash Variables
	let currentBrightness = UIScreen.main.brightness

	// Image Variables
	var frontImage = UIImage()
	var backImage = UIImage()

	// Tap to focus variables
	var tapToFocusRecognizer = UITapGestureRecognizer()
	var previewPointOfTap = CGPoint()
	var captureDevicePointOfTap = CGPoint()
	var focusBox = UIView()
	var focusBoxInner = UIView()
	var focusBoxSize = 65.0

	// Session Queue
	let sessionQueue = DispatchQueue(label: "io.flippic.cameraCapture")

	// MARK: - Outlets

    @IBOutlet weak var shutterButton: UIButton!
    @IBOutlet weak var shutterBorderView: UIView!
    @IBOutlet var switchCameraButton: UIButton!
	@IBOutlet var flashOnOffButton: UIButton!

	// MARK: - Buttons

//	let shutterButton = UIButton()
//	let shutterButtonBorder = UIView()

	override var prefersStatusBarHidden: Bool {
		true
	}

	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
		if hasTakenFirstPicture! {
			hasTakenFirstPicture = false
		} else {
			AudioServicesPlaySystemSound(soundID)
			hasTakenFirstPicture = true
		}
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		tapToFocusRecognizer = UITapGestureRecognizer(target: self, action: #selector(RCT_CameraViewController.tapToFocus(_:)))
        setupCameraView()
		setupButtons()

		let path = Bundle.main.path(forResource: "photoShutter2", ofType: "caf")
		let filePath = NSURL(fileURLWithPath: path!, isDirectory: false) as CFURL
		AudioServicesCreateSystemSoundID(filePath, &soundID)

		// Initialize the Focal Box and Set Alpha Level to 0.0
		focusBox = UIView(frame: CGRect(x: 0.0, y: 0.0, width: focusBoxSize, height: focusBoxSize))
		focusBox.backgroundColor = UIColor.clear
		focusBox.layer.borderWidth = 1.0
		focusBox.layer.cornerRadius = CGFloat(focusBoxSize / 2)
		focusBox.layer.borderColor = UIColor.white.cgColor
		focusBox.alpha = 0.0
		focusBoxInner = UIView(frame: CGRect(x: 0.0, y: 0.0, width: focusBoxSize, height: focusBoxSize))
		focusBoxInner.center = CGPoint(x: focusBox.bounds.maxX / 2, y: focusBox.bounds.maxY / 2)
		focusBoxInner.layer.cornerRadius = CGFloat((focusBoxSize - 2) / 2)
		focusBoxInner.backgroundColor = UIColor.clear
		focusBoxInner.alpha = 0.0
		view.addSubview(focusBox)
		focusBox.addSubview(focusBoxInner)
	}

	override func viewWillAppear(_ animated: Bool) {
		hasTakenFirstPicture = false
//		stillImageOutput.addObserver(self, forKeyPath: "capturingStillImage", options: [NSKeyValueObservingOptions.new], context: nil)
	}

	// MARK: - Actions

	@IBAction func iSightFlashButtonTapped(_ sender: UIButton) {
		print("iSight Flash Button Tapped")
		if let device = backCaptureDevice {
			if device.hasFlash == true {
				do {
					try device.lockForConfiguration()
				} catch {
					print("Error: iSight Flash Button Tapped")
				}
				if device.isFlashActive == false {
					print("Turning Off iSight Flash")
					device.flashMode = AVCaptureDevice.FlashMode.on
                    sender.isSelected = true

				} else {
					print("Turning On iSight Flash")
					device.flashMode = AVCaptureDevice.FlashMode.off
                    sender.isSelected = false
				}
				device.unlockForConfiguration()
			}
		}
	}

	@IBAction func shutterButtonTapped(_ sender: AnyObject) {
		print("Shutter Button Tapped")
//		previewLayer.removeFromSuperlayer()
		// setDarkBackground()

		// Flash Screen
		frontFlash()
//        self.capturePhotos()
        if self.backCameraIsPreview {
            if let backCameraOutput = self.backCameraOutput {
                capturePhoto(output: backCameraOutput)
            }
            
//            self.captureSession.beginConfiguration()
//            self.captureSession.removeInput(self.backInput!)
//            self.captureSession.addInput(self.frontInput!)
//            self.captureSession.commitConfiguration()
//            
//            delay(seconds: 0.1, completion: { () in
//                if let frontCameraOutput = self.frontCameraOutput {
//                    self.capturePhoto(output: frontCameraOutput)
//                }
//            }) // End of Delay Closure
            
            // Asynchronously switch to the front camera and capture photo
            self.captureSession.beginConfiguration()
            self.captureSession.removeInput(self.backInput!)
            
            if self.captureSession.canAddInput(self.frontInput!) {
                self.captureSession.addInput(self.frontInput!)
            }
            
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let frontCameraOutput = self.backCameraOutput {
                        self.capturePhoto(output: frontCameraOutput)
                    }
                    
//                    if let frontData = data {
//                        self.frontImage = UIImage(data: frontData)!
//                        print("Front Camera Data is Here")
//                        let layout = Layout(rawValue: 0)!
//                        self.rCTImage = RCT_ImageController.createRCTImageFromImages(imageFront: self.frontImage, imageBack: self.backImage, layout: layout)
//                        self.performSegue(withIdentifier: "ToEditView", sender: self)
//                        self.captureSesson.beginConfiguration()
//                        self.captureSesson.removeInput(self.frontInput!)
//                        self.captureSesson.addInput(self.backInput!)
//                        self.captureSesson.commitConfiguration()
//                    }
                }

            
            
        } else {
            if let frontCameraOutput = self.frontCameraOutput {
                capturePhoto(output: frontCameraOutput)
            }
            delay(seconds: 0.1, completion: { () in
                if let backCameraOutput = self.backCameraOutput {
                    self.capturePhoto(output: backCameraOutput)
                }
            }) // End of Delay Closure
        }

		/* if backCameraIsPreview == true {
			if let backCamera = backCaptureDevice {
				takePic(device: backCamera, session: captureSesson, completion: { data in
					if let backData = data {
						print("back camera data is here")

						// TODO: - Refactor

						self.backImage = UIImage(data: backData)!
						self.captureSesson.beginConfiguration()
						self.captureSesson.removeInput(self.backInput!)
						self.captureSesson.addInput(self.frontInput!)
						self.captureSesson.commitConfiguration()

						// TODO: - Possibly Add KVO

						delay(seconds: 0.1, completion: { () in
							if let frontCamera = self.frontCaptureDevice {
								self.takePic(device: frontCamera, session: self.captureSesson, completion: { data in
									if let frontData = data {
										self.frontImage = UIImage(data: frontData)!
										print("Front Camera Data is Here")
										let layout = Layout(rawValue: 0)!
										self.rCTImage = RCT_ImageController.createRCTImageFromImages(imageFront: self.frontImage, imageBack: self.backImage, layout: layout)
										self.performSegue(withIdentifier: "ToEditView", sender: self)
										self.captureSesson.beginConfiguration()
										self.captureSesson.removeInput(self.frontInput!)
										self.captureSesson.addInput(self.backInput!)
										self.captureSesson.commitConfiguration()
									}
								})
							}
						}) // End of Delay Closure
					}
				})
			}
		} else {
			// Front camera should already be on Preview Layer
			if let frontCamera = frontCaptureDevice {
				takePic(device: frontCamera, session: captureSesson, completion: { data in

					if let frontData = data {
						print("Front Camera Data is Here")

						// TODO: - Refactor

						self.frontImage = UIImage(data: frontData)!
						self.captureSesson.beginConfiguration()
						self.captureSesson.removeInput(self.frontInput!)
						self.captureSesson.addInput(self.backInput!)
						self.captureSesson.commitConfiguration()

						// TODO: - Possibly add KVO

						delay(seconds: 0.1, completion: { () in
							if let backCamera = self.backCaptureDevice {
								self.takePic(device: backCamera, session: self.captureSesson, completion: { data in
									if let backData = data {
										self.backImage = UIImage(data: backData)!
										print("Back Camera Data is Here")
										let layout = Layout(rawValue: 0)!
										self.rCTImage = RCT_ImageController.createRCTImageFromImages(imageFront: self.frontImage, imageBack: self.backImage, layout: layout)
										self.performSegue(withIdentifier: "ToEditView", sender: self)
										self.captureSesson.beginConfiguration()
										// This is questionable if we need to do this switch
										self.captureSesson.removeInput(self.backInput!)
										self.captureSesson.addInput(self.frontInput!)
										self.captureSesson.commitConfiguration()
									}
								})
							}
						}) // End of Delay Closure
					}
				})
			}
		} */
	}

	@IBAction func switchCameraButtonTapped(_ sender: AnyObject) {
		print("Camera Switched")
		if backCameraIsPreview == true {
			// Back is Preview, Switching to Front
			UIView.transition(with: previewView, duration: 0.5, options: [UIView.AnimationOptions.curveEaseInOut, UIView.AnimationOptions.transitionFlipFromRight], animations: { () in
				// self.previewView.hidden = true
				print("Animating Flip Preview to Front")
				UIView.animate(withDuration: 0.1, animations: { () in
					self.previewView.alpha = 0
				})
			}, completion: { _ in
				self.previewView.isHidden = false
				UIView.animate(withDuration: 0.1, animations: { () in
					self.previewView.alpha = 1
				})
			})
			delay(seconds: 0.1, completion: { () in
				print("Switching to Front Preview")
				self.captureSession.beginConfiguration()
				self.captureSession.removeInput(self.backInput!)
				self.captureSession.addInput(self.frontInput!)
				self.captureSession.commitConfiguration()
				self.backCameraIsPreview = false
			})

		} else {

			// Front is Preview, Switching to Back
			print("Switching to Back Preview")
			UIView.transition(with: previewView, duration: 0.5, options: [UIView.AnimationOptions.curveEaseInOut, UIView.AnimationOptions.transitionFlipFromRight], animations: { () in
				self.previewView.isHidden = true
				print("Animating Flip Preview to Front")
				UIView.animate(withDuration: 0.1, animations: { () in
					self.previewView.alpha = 0
				})
			}, completion: { _ in
				self.previewView.isHidden = false
				UIView.animate(withDuration: 0.1, animations: { () in
					self.previewView.alpha = 1
				})
			})
			delay(seconds: 0.1, completion: { () in
				self.captureSession.beginConfiguration()
				self.captureSession.removeInput(self.frontInput!)
				self.captureSession.addInput(self.backInput!)
				self.captureSession.commitConfiguration()
				self.backCameraIsPreview = true
			})
		}
	}

	// MARK: Functions

	func setMockImage() {
		let frontImage = UIImage(named: "mock_selfie")
		let backImage = UIImage(named: "mock_landscape")
		let frontImageData = RCT_ImageController.imageToData(image: frontImage!)!
		let backImageData = RCT_ImageController.imageToData(image: backImage!)!
		rCTImage = RCT_ImageController.createRCTImage(imageFront: frontImageData, imageBack: backImageData)
	}

	/* func takePic(device: AVCaptureDevice, session: AVCaptureSession, completion: @escaping (_ data: Data?) -> Void) {
		sessionQueue.async {

			// session.sessionPreset = AVCaptureSessionPresetPhoto
			if let connection = self.stillImageOutput.connection(with: AVMediaType.video) {
				print("Connection Established")

				var orientation: AVCaptureVideoOrientation
				switch UIDevice.current.orientation {
					case .portrait:
						orientation = .portrait
					case .portraitUpsideDown:
						orientation = .portraitUpsideDown
					case .landscapeLeft:
						orientation = .landscapeRight
					case .landscapeRight:
						orientation = .landscapeLeft
					default:
						orientation = .portrait
				}
				connection.videoOrientation = orientation

				// TODO: Change Code to Allow Landscape

				self.stillImageOutput.captureStillImageAsynchronously(from: connection, completionHandler: { cmSampleBuffer, _ in
					if let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(cmSampleBuffer!) {
						completion(imageData)
					}
				})
			}
		}
	} */

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(true)
//		stillImageOutput.removeObserver(self, forKeyPath: "capturingStillImage")
	}

	override func viewDidDisappear(_ animated: Bool) {
		previewView.layer.addSublayer(previewLayer)
		view.bringSubviewToFront(shutterButton)
		view.bringSubviewToFront(switchCameraButton)
        view.bringSubviewToFront(flashOnOffButton)
		view.bringSubviewToFront(shutterBorderView)
	}

	func setDarkBackground() {
		let rect = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
		let darkView = UIView()
		darkView.frame = rect
		darkView.backgroundColor = UIColor.black
		view.addSubview(darkView)
	}

	// Focus Box Animation
	func focusBox(centerPoint: CGPoint) {

		let focusBoxScaleTransform = CGAffineTransformMakeScale(0.75, 0.75)
		let focusBoxScaleTransformShrink = CGAffineTransformMakeScale(0.77, 0.77)
		focusBox.center = centerPoint
		focusBox.bounds.size = CGSize(width: focusBoxSize, height: focusBoxSize)
		focusBoxInner.bounds.size = CGSize(width: focusBoxSize, height: focusBoxSize)
		focusBox.alpha = 1.0
		focusBoxInner.backgroundColor = UIColor.white

		UIView.animate(withDuration: 0.5, animations: { () in

			self.focusBox.alpha = 1.0
			self.focusBoxInner.alpha = 0.4
			self.focusBox.transform = focusBoxScaleTransform
			//            self.focusBoxInner.transform = focusBoxScaleTransform

		}) { _ in

			UIView.animate(withDuration: 0.5, animations: { () in

				self.focusBox.transform = focusBoxScaleTransformShrink
				self.focusBox.alpha = 0.0
				self.focusBoxInner.alpha = 0.0

			}) { _ in
			}
		}
	}

	func frontFlash() {
//		let rect = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
//		flashView.frame = rect
//		flashView.backgroundColor = UIColor(red: 1.0, green: 0.7176, blue: 0.47, alpha: 1.0)
//		flashView.alpha = 1.0
//		view.addSubview(flashView)
//		delay(seconds: 0.3) { () in
//			UIScreen.main.brightness = 1.0
//		}
	}

	// MARK: - Tap to Focus

	// Setup Tap Gesture Recognizer
	@objc func tapToFocus(_ recognizer: UIGestureRecognizer) {

		previewPointOfTap = recognizer.location(in: view)
		focusBox(centerPoint: previewPointOfTap)
		captureDevicePointOfTap = previewLayer.captureDevicePointConverted(fromLayerPoint: previewPointOfTap)

		if let focusDevice = currentCaptureDevice {
			if focusDevice.isFocusPointOfInterestSupported {
				do {
					try focusDevice.lockForConfiguration()
					focusDevice.focusPointOfInterest = captureDevicePointOfTap
					if focusDevice.isFocusModeSupported(.autoFocus) {
						focusDevice.focusMode = .autoFocus
					}
					focusDevice.unlockForConfiguration()
					print("Point in Capture Device: \(previewLayer.captureDevicePointConverted(fromLayerPoint: captureDevicePointOfTap))")

				} catch {
					print("Lock for Configuration Unsuccessful \(error)")
				}
			}
		}

		print("Focus Mode: \(currentCaptureDevice!.focusMode.rawValue)")
		print("Point in previewView: \(previewPointOfTap)")
	}

	func focusAreaBox(recognizer: UIGestureRecognizer) {}

	// MARK: - Setup UI

	func setupButtons() {
		shutterButton.layer.cornerRadius = shutterButton.frame.width / 2
        shutterBorderView.layer.cornerRadius = shutterBorderView.frame.width / 2
		shutterButton.backgroundColor = UIColor.white
		shutterButton.alpha = 0.5
        shutterBorderView.backgroundColor = UIColor.clear
        shutterBorderView.layer.borderWidth = 3
        shutterBorderView.layer.borderColor = UIColor.white.cgColor
        shutterButton.addTarget(self, action: #selector(shutterButtonTapped(_:)), for: .touchUpInside)
        
		// Switch Camera Button
        switchCameraButton.alpha = 1
		flashOnOffButton.alpha = 1
	}

	// MARK: - Navigation

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		UIView.animate(withDuration: 3, animations: { () in
			UIScreen.main.brightness = self.currentBrightness
//			self.flashView.alpha = 0
		}, completion: { _ in
//			self.flashView.alpha = 1
//			self.flashView.removeFromSuperview()
		})
		if segue.identifier == "ToEditView" {
			let editVC = segue.destination as! RCT_EditViewController
			editVC.setupController(rCTImage: rCTImage!)
		}
		AudioServicesPlaySystemSound(soundID)
	}
}

// MARK: - Private camera methods
extension RCT_CameraViewController {
    
    private func setupCameraView() {
        
        print("Setting Up Camera")
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        if let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            self.flashOnOffButton.isHidden = !backCamera.hasFlash
            let backCameraInput = setupCameraInput(device: backCamera)
            self.backInput = backCameraInput
            backCameraOutput = AVCapturePhotoOutput()
            self.setupCameraOutput(output: self.backCameraOutput)
            currentCaptureDevice = backCamera
        }
        
        // Set up the front camera
        if let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            let frontCameraInput = setupCameraInput(device: frontCamera)
            self.frontInput = frontCameraInput
            frontCameraOutput = AVCapturePhotoOutput()
            setupCameraOutput(output: frontCameraOutput)
            currentCaptureDevice = frontCamera
        }
        
        //        stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
        
//        let devices = AVCaptureDevice.DiscoverySession(deviceTypes: <#T##[AVCaptureDevice.DeviceType]#>, mediaType: <#T##AVMediaType?#>, position: <#T##AVCaptureDevice.Position#>)
//        print(devices.count)
//        
//        for device in devices where device.hasMediaType(AVMediaType.video) {
//            if device.position == AVCaptureDevice.Position.back {
//                backCaptureDevice = device
//                print("Has Back Camera")
//            }
//            if device.position == AVCaptureDevice.Position.front {
//                frontCaptureDevice = device
//                print("Has Front Camera")
//                getFrontInput()
//            }
//        }
        
        /* if let backCamera = backCaptureDevice {
            self.flashOnOffButton.isHidden = !backCamera.hasFlash
            
            do {
                let input = try AVCaptureDeviceInput(device: backCamera)
                backInput = input
                frontCameraOutput = AVCapturePhotoOutput()
                photoOutput = AVCapturePhotoOutput()
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                    currentCaptureDevice = backCamera
                    print("Back Camera Input was Added")
                    if let photoOutput = self.photoOutput {
                        if captureSession.canAddOutput(photoOutput) {
                            captureSession.addOutput(photoOutput)
                            print("Back Camera Output was Added")
                            setupPreview()
                            self.startSession()
                            print("Session has Started")
                        }
                    }
                    
                }
            } catch {
                print("Error Getting Input from Back", error.localizedDescription)
            }
        } */
    }
    
    private func setupCameraInput(device: AVCaptureDevice) -> AVCaptureDeviceInput? {
        do {
            let cameraInput = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(cameraInput) {
                captureSession.addInput(cameraInput)
            }
            return cameraInput
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    private func setupCameraOutput(output: AVCapturePhotoOutput?) {
        if let photoOutput = output {
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
                print("Back Camera Output was Added")
                setupPreview()
                self.startSession()
                print("Session has Started")
            }
        }
    }
    
    private func startSession() {
        let currentSession = captureSession
        if !captureSession.isRunning {
            currentSession.commitConfiguration()
            DispatchQueue.global(qos: .userInitiated).async {
                currentSession.startRunning()
                debugPrint("Session is Start Runnging.")
            }
        }
    }
    
    private func stopSession() {
        self.captureSession.stopRunning()
        debugPrint("Session is Stop Runnging.")
    }
    
    private func setupPreview() {
        
        // Setting size of preview
        previewView.frame = view.frame
        previewView.center.x = view.center.x
        view.addSubview(previewView)
        view.bringSubviewToFront(previewView)
        print("Setting up Preview")
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        print("\(previewLayer.frame.size)")
        previewView.layer.addSublayer(previewLayer)
        previewLayer.frame = previewView.frame
        previewView.addGestureRecognizer(tapToFocusRecognizer)
        
        view.bringSubviewToFront(shutterButton)
        view.bringSubviewToFront(switchCameraButton)
        view.bringSubviewToFront(flashOnOffButton)
        view.bringSubviewToFront(shutterBorderView)
        // print("PreviewLayer: \(previewLayer.bounds.size) PreviewView: \(previewView.bounds.size)")
    }
    
    private func getFrontInput() {
        
        if let frontCamera = frontCaptureDevice {
            do {
                let input = try AVCaptureDeviceInput(device: frontCamera)
                frontInput = input
                currentCaptureDevice = frontCamera
            } catch {
                print("Error Getting Input from Back", error.localizedDescription)
            }
        }
    }
    
    private func flipPreviewLayer(animationOption: UIView.AnimationOptions) {
        UIView.transition(with: previewView, duration: 1, options: [UIView.AnimationOptions.curveEaseInOut, animationOption], animations: { () in
            self.previewView.isHidden = false
        }, completion: { _ in
        })
    }
    
    @objc func capturePhotos() {
        if let backCameraOutput = self.backCameraOutput {
            capturePhoto(output: backCameraOutput)
        }
        
        if let frontCameraOutput = self.frontCameraOutput {
            capturePhoto(output: frontCameraOutput)
        }
        
    }
    
    private func capturePhoto(output: AVCapturePhotoOutput) {
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
    
}

extension RCT_CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if (error != nil) {
            debugPrint("Could not capture still image: %@", error?.localizedDescription as Any)
            return
        }
        
        let photo = getPhotoFromCapturePhoto(photo: photo)
        debugPrint(photo)
        let image = UIImage(data: photo)!
        print(image)
        
    }
    
    func getPhotoFromCapturePhoto(photo : AVCapturePhoto)  -> Data{
        var newPhoto : Data? = nil
        newPhoto = photo.fileDataRepresentation()
        return newPhoto!
    }
}

extension RCT_CameraViewController: AVCapturePhotoFileDataRepresentationCustomizer {
    
}
