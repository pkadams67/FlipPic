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
    var backInput : AVCaptureInput!
    var frontInput : AVCaptureInput!
    var previewLayer : AVCaptureVideoPreviewLayer!
    var videoOutput : AVCaptureVideoDataOutput!
    
    var rCTImage: RCT_Image? = nil
    
    var takePicture = false
    var backCameraOn = true
    var isCapturedBackPhoto = false
    
    // Image Variables
    var frontImage = UIImage()
    var backImage = UIImage()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupButtons()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkPermissions()
        setupAndStartCaptureSession()
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
    
    func setupAndStartCaptureSession(){
        DispatchQueue.global(qos: .userInitiated).async{
            
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
    
    func setupInputs() {
        //get back camera
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            backCamera = device
        } else {
            //handle this appropriately for production purposes
            fatalError("no back camera")
        }
        
        //get front camera
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            frontCamera = device
        } else {
            fatalError("no front camera")
        }
        
        //now we need to create an input objects from our devices
        guard let bInput = try? AVCaptureDeviceInput(device: backCamera) else {
            fatalError("could not create input device from back camera")
        }
        backInput = bInput
        if !captureSession.canAddInput(backInput) {
            fatalError("could not add back camera input to capture session")
        }
        
        guard let fInput = try? AVCaptureDeviceInput(device: frontCamera) else {
            fatalError("could not create input device from front camera")
        }
        frontInput = fInput
        if !captureSession.canAddInput(frontInput) {
            fatalError("could not add front camera input to capture session")
        }
        
        //connect back camera input to session
        captureSession.addInput(backInput)
    }
    
    
    func setupPreviewLayer(){
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewView.layer.insertSublayer(previewLayer, below: switchCameraButton.layer)
        previewLayer.frame = self.previewView.layer.frame
    }
    
    func setupOutput(){
        videoOutput = AVCaptureVideoDataOutput()
        let videoQueue = DispatchQueue(label: "videoQueue", qos: .userInteractive)
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
        
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            fatalError("could not add video output")
        }
        
        videoOutput.connections.first?.videoOrientation = .portrait
    }
    
    func switchCameraInput(){
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
}

//MARK: - Button Actions

extension CameraViewController {
    
    @IBAction func shutterButtonTapped(_ sender: AnyObject) {
        self.takePicture = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isCapturedBackPhoto = true
            self.switchCameraInput()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.takePicture = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let layout = Layout(rawValue: 0)!
                    self.rCTImage = RCT_ImageController.createRCTImageFromImages(imageFront: self.frontImage, imageBack: self.backImage, layout: layout)
//                    self.performSegue(withIdentifier: "ToEditView", sender: self)
                    let editVc = self.storyboard?.instantiateViewController(withIdentifier: "EditImageViewController") as! EditImageViewController
                    editVc.rCTImage = self.rCTImage
                    editVc.modalPresentationStyle = .fullScreen
//                    editVc.setupController(rCTImage: self.rCTImage!)
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
