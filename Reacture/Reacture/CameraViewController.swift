//
//  NewCameraViewController.swift
//  FlipPic
//
//  Created by Priyanshi Bhikadiya 2 on 01/12/23.
//  Copyright © 2023 BAEPS. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var shutterButton: UIButton!
    @IBOutlet weak var shutterBorderView: UIView!
    @IBOutlet var switchCameraButton: UIButton!
    @IBOutlet var flashOnOffButton: UIButton!
    
    var captureSession : AVCaptureSession!
    
    var backCamera : AVCaptureDevice!
    var frontCamera : AVCaptureDevice!
    var currentCaptureDevice : AVCaptureDevice!
    var backInput : AVCaptureInput!
    var frontInput : AVCaptureInput!
    var previewLayer : AVCaptureVideoPreviewLayer!
    var videoOutput : AVCaptureVideoDataOutput!
    var photoOutput : AVCapturePhotoOutput!
    
    var rCTImage: RCT_Image? = nil
    
    var takePicture = false
    var backCameraOn = true
    var isCapturedBackPhoto = false
    
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setMockImage()
        
        return
        
        self.setupButtons()
        
        let path = Bundle.main.path(forResource: "photoShutter2", ofType: "caf")
        let filePath = NSURL(fileURLWithPath: path!, isDirectory: false) as CFURL
        AudioServicesCreateSystemSoundID(filePath, &soundID)
        
        self.setupFocusBox()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        checkPermissions()
//        stopSession()
//        setupAndStartCaptureSession()
    }
    
    #warning("Remove below function")
    
    func setMockImage() {
        let frontImage = UIImage(named: "mock_selfie") ?? self.frontImage
        let backImage = UIImage(named: "mock_landscape") ?? self.frontImage
//        let frontImageData = RCT_ImageController.imageToData(image: frontImage)!
//        let backImageData = RCT_ImageController.imageToData(image: backImage)!
        
        DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
            let layout = Layout(rawValue: 0)!
            self.rCTImage = RCT_ImageController.createRCTImageFromImages(imageFront: frontImage, imageBack: backImage, layout: layout)
            let editVc = self.storyboard?.instantiateViewController(withIdentifier: "EditImageViewController") as! EditImageViewController
            editVc.rCTImage = self.rCTImage
            editVc.modalPresentationStyle = .fullScreen
            self.present(editVc, animated: true)
        }
        
    }
    
    
    @IBAction func switchCameraAction(_ sender: Any) {
        
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
        self.switchCameraInput()
//        delay(seconds: 0.1, completion: { () in
//            print("Switching to Front Preview")
//            self.captureSession.beginConfiguration()
//            self.captureSession.removeInput(self.backInput!)
//            self.captureSession.addInput(self.frontInput!)
//            self.captureSession.commitConfiguration()
//            self.backCameraIsPreview = false
//        })
        
    }
    
}

// MARK: - private methods

extension CameraViewController {
    
    private func setupButtons() {
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
    
    private func setupAndStartCaptureSession() {
        
        DispatchQueue.global(qos: .userInitiated).async {
            
            self.captureSession = AVCaptureSession()
            self.captureSession.beginConfiguration()
            
            //session specific configuration
            if self.captureSession.canSetSessionPreset(.photo) {
                self.captureSession.sessionPreset = .photo
            }
            
            self.captureSession.automaticallyConfiguresCaptureDeviceForWideColor = true
            
            //setup inputs
            self.setupInputs()
            
            DispatchQueue.main.async {
                //setup preview layer
                self.setupPreviewLayer()
            }
            
            //setup output
            self.setupOutput()
            
            //commit configuration
            self.captureSession.commitConfiguration()
            //start running it
            self.startSession()
        }
    }
    
    private func startSession() {
        if !captureSession.isRunning {
            captureSession.commitConfiguration()
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
                debugPrint("Session is Start Runnging.")
            }
        }
    }
    
    private func stopSession() {
        if captureSession != nil {
            if captureSession.isRunning {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.captureSession.stopRunning()
                    debugPrint("Session is Stop Runnging.")
                }
            }
        }
        
    }
    
    private func setupInputs() {
        //get back camera
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            backCamera = device
        } else {
            debugPrint("no back camera")
        }
        
        //get front camera
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            frontCamera = device
        } else {
            debugPrint("no front camera")
        }
        
        // now we need to create an input objects from our devices
        guard let bInput = try? AVCaptureDeviceInput(device: backCamera) else {
            debugPrint("could not create input device from back camera")
            return
        }
        backInput = bInput
        if !captureSession.canAddInput(backInput) {
            debugPrint("could not add back camera input to capture session")
        }
        
        guard let fInput = try? AVCaptureDeviceInput(device: frontCamera) else {
            debugPrint("could not create input device from front camera")
            return
        }
        frontInput = fInput
        if !captureSession.canAddInput(frontInput) {
            debugPrint("could not add front camera input to capture session")
        }
        
        //connect back camera input to session
        captureSession.addInput(backInput)
    }
    
    private func setupPreviewLayer() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewView.layer.insertSublayer(previewLayer, below: switchCameraButton.layer)
        previewLayer.frame = self.previewView.layer.frame
        previewLayer.videoGravity = .resizeAspectFill
        previewView.addGestureRecognizer(tapToFocusRecognizer)
    }
    
   private func setupOutput() {
        videoOutput = AVCaptureVideoDataOutput()
        let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
//        self.photoOutput = AVCapturePhotoOutput()
//        self.photoOutput.isHighResolutionCaptureEnabled = true
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            debugPrint("could not add photo output")
        }
        
        videoOutput.connections.first?.videoOrientation = .portrait
    }
    
   private func switchCameraInput() {
        //don't let user spam the button, fun for the user, not fun for performance
        switchCameraButton.isUserInteractionEnabled = false
        
        //reconfigure the input
        captureSession.beginConfiguration()
        if backCameraOn {
            captureSession.removeInput(backInput)
            captureSession.addInput(frontInput)
            backCameraOn = false
        } else {
            captureSession.removeInput(frontInput)
            captureSession.addInput(backInput)
            backCameraOn = true
        }
        
        //deal with the connection again for portrait mode
        videoOutput.connections.first?.videoOrientation = .portrait
        
        //mirror the video stream for front camera
        videoOutput.connections.first?.isVideoMirrored = !backCameraOn
        
        //commit config
        captureSession.commitConfiguration()
        
        //acitvate the camera button again
        switchCameraButton.isUserInteractionEnabled = true
    }
    
    //MARK: - Permissions
    
    func checkPermissions() {
        let cameraAuthStatus =  AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch cameraAuthStatus {
        case .authorized:
            return
        case .denied:
            debugPrint("denied")
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler:
                                            { (authorized) in
                if(!authorized){
                    debugPrint("notDetermined")
                }
            })
        case .restricted:
            debugPrint("restricted")
        @unknown default:
            debugPrint("@unknown")
        }
    }
    
    // MARK: - Focus box
    
    private func focusBox(centerPoint: CGPoint) {
        
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
    
    private func setupFocusBox() {
        
        tapToFocusRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapToFocus(_:)))
        
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
}

//MARK: - Button Actions

extension CameraViewController {
    
    @IBAction func shutterButtonTapped(_ sender: UIButton) {
//        let photoSettings = AVCapturePhotoSettings()
//        self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
//        
        self.takePicture = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            AudioServicesPlaySystemSound(soundID)
            self.isCapturedBackPhoto = true
            self.switchCameraInput()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
                self.takePicture = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.switchCameraInput()
                    let layout = Layout(rawValue: 0)!
                    self.rCTImage = RCT_ImageController.createRCTImageFromImages(imageFront: self.frontImage, imageBack: self.backImage, layout: layout)
                    let editVc = self.storyboard?.instantiateViewController(withIdentifier: "EditImageViewController") as! EditImageViewController
                    editVc.rCTImage = self.rCTImage
                    editVc.modalPresentationStyle = .fullScreen
                    self.present(editVc, animated: true)
                    // self.navigationController?.pushViewController(editVc, animated: true)
//                    self.captureSesson.beginConfiguration()
//                    // This is questionable if we need to do this switch
//                    self.captureSesson.removeInput(self.backInput!)
//                    self.captureSesson.addInput(self.frontInput!)
//                    self.captureSesson.commitConfiguration()
                }
            }
        }
    }
    
    @IBAction func iSightFlashButtonTapped(_ sender: UIButton) {
        print("iSight Flash Button Tapped")
        
        if let device = AVCaptureDevice.default(for: .video) {
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
    
    // Setup Tap Gesture Recognizer
    @objc func tapToFocus(_ recognizer: UIGestureRecognizer) {

        previewPointOfTap = recognizer.location(in: view)
        focusBox(centerPoint: previewPointOfTap)
        captureDevicePointOfTap = previewLayer.captureDevicePointConverted(fromLayerPoint: previewPointOfTap)
        
        currentCaptureDevice = self.backCameraOn ? self.backCamera : self.frontCamera

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
    
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if !takePicture {
            return //we have nothing to do with the image buffer
        }
        
        //try and get a CVImageBuffer out of the sample buffer
        guard let cvBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        //get a CIImage out of the CVImageBuffer
        let ciImage = CIImage(cvImageBuffer: cvBuffer)
        
        //get UIImage out of CIImage
        let uiImage = UIImage(ciImage: ciImage)
        if self.isCapturedBackPhoto {
            self.frontImage = uiImage
        } else {
            self.backImage = uiImage
        }
        
        debugPrint("Image detected", uiImage)
        
        DispatchQueue.main.async {
//            self.capturedImageView.image = uiImage
            self.takePicture = false
        }
    }
        
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if (error != nil) {
            debugPrint("Could not capture still image: %@", error?.localizedDescription as Any)
            return
        }
        
        let newPhoto: Data? = photo.fileDataRepresentation()
        
        if let data = newPhoto {
            let image = UIImage(data: data) ?? UIImage()
            
            if self.isCapturedBackPhoto {
                self.frontImage = image
                self.switchCameraInput()
                self.isCapturedBackPhoto = false
                DispatchQueue.main.async {
                    let layout = Layout(rawValue: 0)!
                    self.rCTImage = RCT_ImageController.createRCTImageFromImages(imageFront: self.frontImage, imageBack: self.backImage, layout: layout)
                    let editVc = self.storyboard?.instantiateViewController(withIdentifier: "EditImageViewController") as! EditImageViewController
                    editVc.rCTImage = self.rCTImage
                    editVc.modalPresentationStyle = .fullScreen
                    self.present(editVc, animated: true)
                }
            } else {
                self.backImage = image
                self.isCapturedBackPhoto = true
                self.switchCameraInput()
                self.shutterButtonTapped(UIButton())
            }
                        
        }
        
    }
    
}
