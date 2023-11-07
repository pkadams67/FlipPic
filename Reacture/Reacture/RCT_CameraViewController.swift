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
	var captureSesson = AVCaptureSession()
	var frontInput: AVCaptureDeviceInput?
	var backInput: AVCaptureDeviceInput?
	var frontCaptureDevice: AVCaptureDevice?
	var backCaptureDevice: AVCaptureDevice?
	var currentCaptureDevice: AVCaptureDevice?
	var stillImageOutput = AVCaptureStillImageOutput()
	let previewView = UIView()
	var previewLayer = AVCaptureVideoPreviewLayer()

	// Flash Variables
	let flashView = UIView()
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

	@IBOutlet var switchCameraButton: UIButton!

	// MARK: - Buttons

	let shutterButton = UIButton()
	let iSightFlashButton = UIButton()
	let shutterButtonBorder = UIView()

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
		setupCamera()
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
		stillImageOutput.addObserver(self, forKeyPath: "capturingStillImage", options: [NSKeyValueObservingOptions.new], context: nil)
	}

	// MARK: - Actions

	@IBAction func iSightFlashButtonTapped(_ sender: AnyObject) {
		print("iSight Flash Button Tapped")
		if let device = backCaptureDevice {
			if device.hasFlash == true {
				do {
					let iSightFlashConfiguration = try device.lockForConfiguration()
				} catch {
					print("Error: iSight Flash Button Tapped")
				}
				if device.isFlashActive == true {
					print("Turning Off iSight Flash")
					device.flashMode = AVCaptureDevice.FlashMode.off
					iSightFlashButton.setBackgroundImage(UIImage(named: "iSightFlashButton_Off")!, for: .normal)
					iSightFlashButton.alpha = 1

				} else {
					print("Turning On iSight Flash")
					device.flashMode = AVCaptureDevice.FlashMode.on
					iSightFlashButton.setBackgroundImage(UIImage(named: "iSightFlashButton_On")!, for: .normal)
					iSightFlashButton.alpha = 1
				}
				device.unlockForConfiguration()
			}
		}
	}

	@IBAction func shutterButtonTapped(_ sender: AnyObject) {
		print("Shutter Button Tapped")
		previewLayer.removeFromSuperlayer()
		// setDarkBackground()

		// Flash Screen
		frontFlash()

		if backCameraIsPreview == true {
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
		}
	}

	@IBAction func switchCameraButtonTapped(sender: AnyObject) {
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
				self.captureSesson.beginConfiguration()
				self.captureSesson.removeInput(self.backInput!)
				self.captureSesson.addInput(self.frontInput!)
				self.captureSesson.commitConfiguration()
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
				self.captureSesson.beginConfiguration()
				self.captureSesson.removeInput(self.frontInput!)
				self.captureSesson.addInput(self.backInput!)
				self.captureSesson.commitConfiguration()
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

	func takePic(device: AVCaptureDevice, session: AVCaptureSession, completion: @escaping (_ data: Data?) -> Void) {
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
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(true)
		stillImageOutput.removeObserver(self, forKeyPath: "capturingStillImage")
	}

	override func viewDidDisappear(_ animated: Bool) {
		previewView.layer.addSublayer(previewLayer)
		view.bringSubviewToFront(shutterButton)
		view.bringSubviewToFront(switchCameraButton)
		view.bringSubviewToFront(iSightFlashButton)
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
		let rect = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
		flashView.frame = rect
		flashView.backgroundColor = UIColor(red: 1.0, green: 0.7176, blue: 0.47, alpha: 1.0)
		flashView.alpha = 1.0
		view.addSubview(flashView)
		delay(seconds: 0.3) { () in
			UIScreen.main.brightness = 1.0
		}
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
					error
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
		let width = view.frame.width / 6
		let borderWidth: CGFloat = (view.frame.width + 3) / 6
		// Shutter Button
		shutterButton.frame.size = CGSize(width: width, height: width)
		shutterButtonBorder.frame.size = CGSize(width: borderWidth, height: borderWidth)
		shutterButtonBorder.center.x = view.center.x
		shutterButton.center = CGPoint(x: shutterButtonBorder.bounds.maxX / 2, y: shutterButtonBorder.bounds.maxY / 2)
		shutterButtonBorder.frame.origin.y = view.frame.size.height - shutterButton.frame.size.height - 10
		flashView.backgroundColor = UIColor(red: 1, green: 0.718, blue: 0.318, alpha: 0.75)
		shutterButton.layer.cornerRadius = width / 2
		shutterButtonBorder.layer.cornerRadius = borderWidth / 2
		shutterButton.backgroundColor = UIColor.white
		shutterButton.alpha = 0.5
		shutterButtonBorder.backgroundColor = UIColor.clear
		shutterButtonBorder.layer.borderWidth = 3
		shutterButtonBorder.layer.borderColor = UIColor.white.cgColor
		shutterButton.addTarget(self, action: #selector(shutterButtonTapped(_:)), for: UIControl.Event.touchUpInside)
		view.addSubview(shutterButtonBorder)
		shutterButtonBorder.addSubview(shutterButton)
		shutterButton.sendSubviewToBack(shutterButtonBorder)
		// iSight Flash Button
		iSightFlashButton.frame.size = CGSize(width: 25, height: 44)
		iSightFlashButton.frame.origin.x = 20
		iSightFlashButton.frame.origin.y = 8
		iSightFlashButton.setBackgroundImage(UIImage(named: "iSightFlashButton_Off")!, for: .normal)
		iSightFlashButton.imageView?.contentMode = .scaleAspectFit
		iSightFlashButton.alpha = 1
		iSightFlashButton.addTarget(self, action: #selector(iSightFlashButtonTapped(_:)), for: UIControl.Event.touchUpInside)
		view.addSubview(iSightFlashButton)
		// Switch Camera Button
		switchCameraButton.alpha = 1
	}

	// MARK: - Navigation

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		UIView.animate(withDuration: 3, animations: { () in
			UIScreen.main.brightness = self.currentBrightness
			self.flashView.alpha = 0
		}, completion: { _ in
			self.flashView.alpha = 1
			self.flashView.removeFromSuperview()
		})
		if segue.identifier == "ToEditView" {
			let editVC = segue.destination as! RCT_EditViewController
			editVC.setupController(rCTImage: rCTImage!)
		}
		AudioServicesPlaySystemSound(soundID)
	}
}

extension RCT_CameraViewController {

	// MARK: - Setting up Camera

	func setupCamera() {

		print("Setting Up Camera")
		captureSesson.sessionPreset = AVCaptureSession.Preset.photo
		stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]

		let devices = AVCaptureDevice.devices()

		print(devices.count)

		for device in devices where device.hasMediaType(AVMediaType.video) {
			if device.position == AVCaptureDevice.Position.back {
				backCaptureDevice = device as? AVCaptureDevice
				print("Has Back Camera")
			}
			if device.position == AVCaptureDevice.Position.front {
				frontCaptureDevice = device as? AVCaptureDevice
				print("Has Front Camera")
				getFrontInput()
			}
		}

		if let backCamera = backCaptureDevice {

			do {
				let input = try AVCaptureDeviceInput(device: backCamera)

				backInput = input

				if captureSesson.canAddInput(input) {
					captureSesson.addInput(input)
					currentCaptureDevice = backCamera
					print("Back Camera Input was Added")

					if captureSesson.canAddOutput(stillImageOutput) {
						captureSesson.addOutput(stillImageOutput)
						print("Back Camera Output was Added")
						setupPreview()
						captureSesson.startRunning()
						print("Session has Started")
					}
				}
			} catch {
				error
				print("Error Getting Input from Back")
			}
		}
	}

	func getFrontInput() {

		if let frontCamera = frontCaptureDevice {
			do {
				let input = try AVCaptureDeviceInput(device: frontCamera)
				frontInput = input
				currentCaptureDevice = frontCamera
			} catch {
				error
			}
		}
	}

	func setupPreview() {

		// Setting size of preview
		previewView.frame = view.frame
		previewView.center.x = view.center.x
		view.addSubview(previewView)
		view.bringSubviewToFront(previewView)
		print("Setting up Preview")
		previewLayer = AVCaptureVideoPreviewLayer(session: captureSesson)

		previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill

		print("\(previewLayer.frame.size)")
		previewView.layer.addSublayer(previewLayer)
		previewLayer.frame = previewView.frame
		previewView.addGestureRecognizer(tapToFocusRecognizer)

		view.bringSubviewToFront(shutterButton)
		view.bringSubviewToFront(switchCameraButton)
		view.bringSubviewToFront(iSightFlashButton)
		// print("PreviewLayer: \(previewLayer.bounds.size) PreviewView: \(previewView.bounds.size)")
	}

	func flipPreviewLayer(animationOption: UIView.AnimationOptions) {
		UIView.transition(with: previewView, duration: 1, options: [UIView.AnimationOptions.curveEaseInOut, animationOption], animations: { () in
			self.previewView.isHidden = false
		}, completion: { _ in
		})
	}
}
