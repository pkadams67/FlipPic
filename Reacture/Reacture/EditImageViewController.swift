//
//  EditImageViewController.swift
//  FlipPic
//
//  Created by Vaibhav Jhaveri on 09/12/23.
//  Copyright © 2023 BAEPS. All rights reserved.
//

import UIKit

class EditImageViewController: UIViewController {
    
    @IBOutlet var containerView: UIView!
    @IBOutlet var RCT_ImageViewBackgroundView: UIView!
    @IBOutlet var rCTImageView: UIView!
    @IBOutlet var topBar: UIStackView!
    @IBOutlet var doneUIButton: UIButton!
    @IBOutlet var swapImagesUIButton: UIButton!
    @IBOutlet weak var layoutButton: UIButton!
    @IBOutlet weak var filterButton: UIButton!
    
    var rCTImage: RCT_Image?
    var imagesAreSwapped = false
    
    var frontImageView = UIImageView()
    var backImageView = UIImageView()
    
    // View Variables
    var frontImageZoomableView = PanGestureView()
    var frontImageScrollView = UIScrollView()
    var backImageZoomableView = ZoomableView()
    var backImageScrollView = UIScrollView()
    
    var containerViewController: RCT_ContainerViewController?
    
    // MARK: - Filter Variables

    let context = CIContext()
    var originalFrontImage: UIImage?
    var originalBackImage: UIImage?
    var arrayOfFilterButtonImageViews: [UIImageView] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let rCTImage = self.rCTImage {
            self.setupController(rCTImage: rCTImage)
        }
        
        self.setupView()
        
    }

}

// MARK:  - Button actions

extension EditImageViewController {
    
    @IBAction func cancelButtonTapped(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
        print("Cancel Button Tapped")
    }
    
    @IBAction func shareButtonTapped(_ sender: AnyObject) {
        frontImageZoomableView.removeIsMovableView()
        let imageToSend = imageCapture()
        let text = "Shared with @FlipPic1 “Your Front/Back Camera App”"
        print("Sending Image")
        let items: [Any] = [text, imageToSend as Any]
        let shareViewController = UIActivityViewController(activityItems: items, applicationActivities: nil)
        shareViewController.popoverPresentationController?.sourceView = view
        present(shareViewController, animated: true, completion: nil)
    }
    
    @IBAction func doneButtonTapped(_ sender: AnyObject) {
        optionSelected(option: .none)
    }
    
    @IBAction func layoutButtonTapped(_ sender: AnyObject) {
        print("Layout Button Tapped")
        optionSelected(option: OptionType.layout)
    }

    @IBAction func filterButtonTapped(sender: AnyObject) {
        print("Filter Button Tapped")
        optionSelected(option: OptionType.filters)
    }
    
    @IBAction func swapImageButtonTapped(_ sender: AnyObject) {
        swapImages()
    }
    
}

// MARK: - Private methods

extension EditImageViewController {
    
    private func setupView() {

        containerViewController = children.first! as? RCT_ContainerViewController
        containerViewController?.delegate = self
        optionSelected(option: .none)
        doneUIButton.setTitleColor(UIColor.flipPicBlue(), for: .normal)

        if let rCTImage {
            frontImageView.image = rCTImage.imageFrontUIImage
            backImageView.image = rCTImage.imageBackUIImage
        } else {
            print("ERROR: rCTImage is nil!")
        }
        
        setupFilters()
        rCTImageView.frame.size = CGSize(width: view.bounds.width, height: view.bounds.width * 1.3)
        updateWithLayout(layout: rCTImage!.layout)
        containerViewController?.reloadCollection()
    }
    
    private func optionSelected(option: OptionType) {
        
        var optionToApply = option
        let currentOptionSelected = containerViewController!.optionSelected
        
        self.filterButton.tintColor = .white
        self.layoutButton.tintColor = .white
        self.doneUIButton.tintColor = .white
        self.swapImagesUIButton.tintColor = .white

        switch option {
            
        case .layout:
            
            self.layoutButton.tintColor = UIColor.flipPicGreen()
            animateContainerView(hide: false)
            
        case .filters:
            
            self.filterButton.tintColor = UIColor.flipPicGreen()
            animateContainerView(hide: false)
            
        case .none:
            
            optionToApply = .none
            // hide containerView
            animateContainerView(hide: true)
        }

        // set optionSelected of containerViewController = .Layout
        containerViewController?.optionSelected = optionToApply

        if optionToApply != .none {
            // Reload Collection View Data
            containerViewController?.reloadCollection()
        }

        // remove isMoveableView if it is applied.
        frontImageZoomableView.removeIsMovableView()
    }
    
    private func animateContainerView(hide: Bool, additionalCode: (() -> Void) = {}) {
        if hide {
            doneUIButton.isHidden = hide
            swapImagesUIButton.isHidden = hide

            UIView.animate(withDuration: 0.4, animations: { () in
                self.containerView.alpha = 0.0
                self.containerView.isHidden = hide
                self.topBar.alpha = 1.0
                self.topBar.isHidden = !hide

            }, completion: { _ in
            })

        } else {

            doneUIButton.isHidden = hide
            swapImagesUIButton.isHidden = hide

            UIView.animate(withDuration: 0.4, animations: { () in
                self.containerView.alpha = 1.0
                self.containerView.isHidden = hide
                self.topBar.alpha = 0.0
                self.topBar.isHidden = !hide

            }, completion: { _ in

            })
        }
    }
    
    private func setupController(rCTImage: RCT_Image) {
        self.rCTImage = rCTImage
        
        // setup zoomable views
        frontImageZoomableView = PanGestureView(frame: CGRect(x: 0.0, y: 0.0, width: rCTImageView.bounds.width, height: rCTImageView.bounds.height / 2))
        frontImageZoomableView.delegate = self
        backImageZoomableView = ZoomableView(frame: CGRect(x: 0.0, y: rCTImageView.bounds.maxY / 2, width: rCTImageView.bounds.width, height: rCTImageView.bounds.height / 2))
        
        rCTImageView.addSubview(backImageZoomableView)
        rCTImageView.addSubview(frontImageZoomableView)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(detectLongPress(recognizer:)))
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapToRemoveView(recognizer:)))
        frontImageZoomableView.gestureRecognizers = [longPressRecognizer, tapGestureRecognizer]
        backImageZoomableView.addGestureRecognizer(tapGestureRecognizer)
        
        // Setup scroll views
        
        self.frontImageScrollView = UIScrollView(frame: self.frontImageZoomableView.bounds)
        self.frontImageScrollView.delegate = self
        self.frontImageScrollView.backgroundColor = UIColor.flipPicGray()
        
        self.frontImageZoomableView.addSubview(self.frontImageScrollView)
        self.frontImageZoomableView.scrollView = self.frontImageScrollView
        
        self.backImageScrollView = UIScrollView(frame: self.backImageZoomableView.bounds)
        self.backImageScrollView.delegate = self
        self.backImageScrollView.backgroundColor = UIColor.flipPicGray()
        
        self.backImageZoomableView.addSubview(self.backImageScrollView)
        //        self.backImageZoomableView.scrollView = self.backImageScrollView
        
        // Setup Image Views
        self.frontImageView = UIImageView(image: self.rCTImage!.imageFrontUIImage)
        self.frontImageScrollView.addSubview(self.frontImageView)
        
        self.backImageView = UIImageView(image: self.rCTImage!.imageBackUIImage)
        self.backImageScrollView.addSubview(self.backImageView)
        
        //        setupAdjustLayoutView()
        rCTImageView.updateBorderForLayout(layout: .littlePicture)
        
        self.updateWithLayout(layout: .pictureInPicture)
        
        self.frontImageView.frame = self.frontImageZoomableView.bounds
        self.frontImageScrollView.frame = self.frontImageZoomableView.bounds
        
        self.backImageView.frame = self.backImageZoomableView.bounds
        self.backImageScrollView.frame = self.backImageZoomableView.bounds
        
        self.setupScrollViews()
        
    }
    
    private func setupScrollViews() {
        
        let frontImageZoomScaleWidth = frontImageZoomableView.bounds.width / (frontImageView.bounds.width)
        let frontImageZoomScaleHeight = frontImageZoomableView.bounds.height / (frontImageView.bounds.height)
        let frontImageMinZoomScale: CGFloat = min(frontImageZoomScaleWidth, frontImageZoomScaleHeight)
        
        frontImageScrollView.minimumZoomScale = frontImageMinZoomScale
        frontImageScrollView.maximumZoomScale = 5.0
        frontImageScrollView.zoomScale = frontImageMinZoomScale
        
        let backImageZoomScaleWidth = backImageZoomableView.bounds.width / (backImageView.bounds.width)
        let backImageZoomScaleHeight = backImageZoomableView.bounds.height / (backImageView.bounds.height)
        let backImageMinZoomScale: CGFloat = min(backImageZoomScaleWidth, backImageZoomScaleHeight)
        
        backImageScrollView.minimumZoomScale = backImageMinZoomScale
        backImageScrollView.maximumZoomScale = 5.0
        backImageScrollView.zoomScale = backImageMinZoomScale
        
        centerImagesOnYAxis()
    }
    
    private func centerImagesOnYAxis(animated: Bool = false) {
        
        // Offset it By the Difference of Size Divided by Two. This Makes the Center of the Image at the Center of the scrollView
        let frontY = (frontImageScrollView.contentSize.height - frontImageScrollView.bounds.height) / 2
        let backY = (backImageScrollView.contentSize.height - backImageScrollView.bounds.height) / 2
        print("\(frontImageScrollView.contentSize.height) \(backImageScrollView.contentSize.height)")
        frontImageScrollView.setContentOffset(CGPoint(x: 0, y: frontY), animated: animated)
        backImageScrollView.setContentOffset(CGPoint(x: 0, y: backY), animated: animated)
    }
    
    private func imageCapture() -> UIImage {
        print("Attempted Image Capture")
        var image = UIImage()
        UIGraphicsBeginImageContextWithOptions(rCTImageView.frame.size, view.isOpaque, 0.0)
        rCTImageView.layer.render(in: UIGraphicsGetCurrentContext()!)
        image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    // MARK: - swap images
    
    func swapImages(withAnimation: Bool = true) {

        print("frontImageZoom: \(frontImageScrollView.zoomScale); backImageZoom: \(backImageScrollView.zoomScale)")
        print("frontImageMinZoom: \(frontImageScrollView.minimumZoomScale); backImageMinZoom: \(backImageScrollView.minimumZoomScale)")

        imagesAreSwapped = !imagesAreSwapped
        print("Swap Image Button Tapped")
        let currentBackImage = rCTImage?.imageBackUIImage
        let currentFrontImage = rCTImage?.imageFrontUIImage
        rCTImage?.imageBackUIImage = currentFrontImage!
        rCTImage?.imageFrontUIImage = currentBackImage!
        let tempImage = originalBackImage
        originalBackImage = originalFrontImage
        originalFrontImage = tempImage

        if withAnimation {
            frontImageView.alpha = 0
            backImageView.alpha = 0
            frontImageView.image = rCTImage?.imageFrontUIImage
            backImageView.image = rCTImage?.imageBackUIImage

            centerImagesOnYAxis()
            frontImageScrollView.zoomScale = frontImageScrollView.minimumZoomScale
            backImageScrollView.zoomScale = backImageScrollView.minimumZoomScale

            UIView.animate(withDuration: 0.5, animations: { () in
                self.frontImageView.alpha = 1
                self.backImageView.alpha = 1
            }, completion: { _ in
            })
        } else {
            frontImageView.image = rCTImage?.imageFrontUIImage
            backImageView.image = rCTImage?.imageBackUIImage
        }
    }

    func clearSwappedImages() {
        if imagesAreSwapped {
            swapImages(withAnimation: false)
        }
    }

}

extension EditImageViewController: PanGestureViewProtocol {
    
    @objc func detectLongPress(recognizer: UILongPressGestureRecognizer) {
        
        if recognizer.state.rawValue == 1, rCTImage?.layout == Layout.pictureInPicture {
            
            frontImageZoomableView.toggleIsMoveable()
            frontImageZoomableView.setLastLocation()
            frontImageZoomableView.lastPointLocation = recognizer.location(in: rCTImageView)
            print("Long press ended")
            
        } else if recognizer.state.rawValue == 2, rCTImage?.layout == Layout.pictureInPicture {
            // pass the press along to the panDetected Method
            if frontImageZoomableView.isMoveableView != nil {
                let pointCenter = recognizer.location(in: rCTImageView)
                let center = frontImageZoomableView.getPoint(touchPoint: pointCenter)
                panDetected(center: center)
            }
        }
    }
    
    // Tap gesture to remove isMovableView
    @objc func tapToRemoveView(recognizer: UITapGestureRecognizer) {
        
        frontImageZoomableView.removeIsMovableView()
    }
    
    func panDetected(center: CGPoint) {
        
        let heightRatio = frontImageZoomableView.bounds.height / rCTImageView.bounds.height
        let widthRatio = frontImageZoomableView.bounds.width / rCTImageView.bounds.width
        let topmostBound: CGFloat = (rCTImageView.bounds.maxY * heightRatio) / 2
        let bottommostBound: CGFloat = (rCTImageView.bounds.maxY - topmostBound)
        let leftmostBound: CGFloat = (rCTImageView.bounds.maxX * widthRatio) / 2
        let rightmostBound: CGFloat = (rCTImageView.bounds.maxX - leftmostBound)
        var frontImageX: CGFloat = 0.0
        var frontImageY: CGFloat = 0.0
        
        if center.x <= rightmostBound, center.x >= leftmostBound {
            
            // Center.x is Valid
            frontImageX = center.x
        } else {
            
            // Center.x is NOT Valid
            if center.x > rightmostBound {
                
                // Center.x is Too Far Right, Set frontImageX to rightmostBound
                frontImageX = rightmostBound
            } else {
                
                // Center.x is Too Far Left, Set frontImageX to leftmostBound
                frontImageX = leftmostBound
            }
        }
        
        if center.y <= bottommostBound, center.y >= topmostBound {
            
            // Center.y is Valid
            frontImageY = center.y
        } else {
            
            // Center.y is NOT Valid
            if center.y > bottommostBound {
                
                // Center.y is Too Far Down, Set frontImageY to lowermostBound
                frontImageY = bottommostBound
            } else {
                
                // Center.y is Too Far Up, Set frontImageY to uppermostBound
                frontImageY = topmostBound
            }
        }
        
        frontImageZoomableView.center = CGPoint(x: frontImageX, y: frontImageY)
    }
}

// MARK: - Layout methods

extension EditImageViewController {
    
    func clearMasks() {
        frontImageZoomableView.maskLayout = MaskLayout.none
        backImageZoomableView.maskLayout = MaskLayout.none
        RCT_LayoutController.isCornersLayout = false
    }
    
    private func updateWithLayout(layout: Layout) {
        rCTImage?.layout = layout
        clearMasks()
        clearSwappedImages()
        updateLayoutViewForLayout()
        frontImageZoomableView.removeIsMovableView()
        frontImageZoomableView.removeBorders()
        backImageZoomableView.removeBorders()
        
        var frontImageX: CGFloat
        var frontImageY: CGFloat
        var frontImageWidth: CGFloat
        var frontImageHeight: CGFloat
        var backImageX: CGFloat
        var backImageY: CGFloat
        var backImageWidth: CGFloat
        var backImageHeight: CGFloat
        var frontImageSubLayout = SubLayout.none
        var backImageSubLayout = SubLayout.none
        
        switch layout {
                
            case .topBottom:
                
                frontImageX = 0.0
                frontImageY = 0.0
                frontImageWidth = rCTImageView.bounds.width
                frontImageHeight = rCTImageView.bounds.height / 2
                backImageX = 0.0
                backImageY = rCTImageView.bounds.maxY / 2
                backImageWidth = rCTImageView.bounds.width
                backImageHeight = rCTImageView.bounds.height / 2
                
            case .leftRight:
                
                frontImageX = 0.0
                frontImageY = 0.0
                frontImageWidth = rCTImageView.bounds.width / 2
                frontImageHeight = rCTImageView.bounds.height
                backImageX = rCTImageView.bounds.maxX / 2
                backImageY = 0.0
                backImageWidth = rCTImageView.bounds.width / 2
                backImageHeight = rCTImageView.bounds.height
                
            case .pictureInPicture:
                
                let yBuffer: CGFloat = 8.0
                let xBuffer: CGFloat = 8.0
                
                frontImageX = (rCTImageView.bounds.maxX - (rCTImageView.bounds.maxX / 3 + xBuffer))
                frontImageY = (rCTImageView.bounds.maxY - (rCTImageView.bounds.maxY / 3 + yBuffer))
                frontImageWidth = rCTImageView.bounds.width / 3
                frontImageHeight = rCTImageView.bounds.height / 3
                backImageX = 0.0
                backImageY = 0.0
                backImageWidth = rCTImageView.bounds.width
                backImageHeight = rCTImageView.bounds.height
                
                // Add Borders
                frontImageSubLayout = SubLayout.littlePicture
                
            case .upperLeftLowerRight:
                RCT_LayoutController.isCornersLayout = true
                frontImageX = 0.0
                frontImageY = 0.0
                frontImageWidth = rCTImageView.bounds.width
                frontImageHeight = rCTImageView.bounds.height
                backImageX = 0.0
                backImageY = 0.0
                backImageWidth = rCTImageView.bounds.width
                backImageHeight = rCTImageView.bounds.height
                
                frontImageZoomableView.maskLayout = MaskLayout.topLeft
                backImageZoomableView.maskLayout = MaskLayout.bottomRight
                
                // Add Borders
                frontImageSubLayout = SubLayout.topLeft
                backImageSubLayout = SubLayout.bottomRight
                
            case .upperRightLowerLeft:
                RCT_LayoutController.isCornersLayout = true
                frontImageX = 0.0
                frontImageY = 0.0
                frontImageWidth = rCTImageView.bounds.width
                frontImageHeight = rCTImageView.bounds.height
                backImageX = 0.0
                backImageY = 0.0
                backImageWidth = rCTImageView.bounds.width
                backImageHeight = rCTImageView.bounds.height
                
                frontImageZoomableView.maskLayout = MaskLayout.topRight
                backImageZoomableView.maskLayout = MaskLayout.bottomLeft
                
                // Add Borders
                frontImageSubLayout = SubLayout.topRight
                backImageSubLayout = SubLayout.bottomLeft
                
            case .count:
                frontImageX = 0.0
                frontImageY = 0.0
                frontImageWidth = 0.0
                frontImageHeight = 0.0
                backImageX = 0.0
                backImageY = 0.0
                backImageWidth = 0.0
                backImageHeight = 0.0
        }
        
        frontImageZoomableView.frame = CGRect(x: frontImageX, y: frontImageY, width: frontImageWidth, height: frontImageHeight)
        backImageZoomableView.frame = CGRect(x: backImageX, y: backImageY, width: backImageWidth, height: backImageHeight)
        frontImageScrollView.frame = frontImageZoomableView.bounds
        backImageScrollView.frame = backImageZoomableView.bounds
        
        // Set the Borders
        frontImageZoomableView.updateBorderForLayout(layout: frontImageSubLayout)
        backImageZoomableView.updateBorderForLayout(layout: backImageSubLayout)
        
        updateScrollViews()
    }
    
    
    func updateScrollViews() {
        
        print("rctImageView width: \(rCTImageView.bounds.width), rctImageView height: \(rCTImageView.bounds.height)")
        
        let frontImageZoomScaleWidth = frontImageZoomableView.bounds.width / (frontImageView.bounds.width)
        let frontImageZoomScaleHeight = frontImageZoomableView.bounds.height / (frontImageView.bounds.height)
        let frontImageMinZoomScale: CGFloat
        
        print("frontWidth: \(frontImageZoomableView.bounds.width) / \(frontImageView.bounds.width) = \(frontImageZoomScaleWidth), frontHeight: \(frontImageZoomableView.bounds.height) / \(frontImageView.bounds.height) = \(frontImageZoomScaleHeight)")
        
        frontImageZoomScaleWidth > frontImageZoomScaleHeight ? (frontImageMinZoomScale = frontImageZoomScaleWidth) : (frontImageMinZoomScale = frontImageZoomScaleHeight)
        
        frontImageScrollView.minimumZoomScale = frontImageMinZoomScale
        frontImageScrollView.maximumZoomScale = 5.0
        
        if frontImageScrollView.zoomScale < frontImageMinZoomScale || rCTImage?.layout == Layout.pictureInPicture {
            frontImageScrollView.zoomScale = frontImageMinZoomScale
        }
        
        let backImageZoomScaleWidth = backImageZoomableView.bounds.width / (backImageView.bounds.width)
        let backImageZoomScaleHeight = backImageZoomableView.bounds.height / (backImageView.bounds.height)
        let backImageMinZoomScale: CGFloat
        
        print("backWidth: \(backImageZoomableView.bounds.width) / \(backImageView.bounds.width) = \(backImageZoomScaleWidth), backHeight: \(backImageZoomableView.bounds.height) / \(backImageView.bounds.height) = \(backImageZoomScaleHeight)")
        
        backImageZoomScaleWidth > backImageZoomScaleHeight ? (backImageMinZoomScale = backImageZoomScaleWidth) : (backImageMinZoomScale = backImageZoomScaleHeight)
        
        backImageScrollView.minimumZoomScale = backImageMinZoomScale
        backImageScrollView.maximumZoomScale = 5.0
        
        if backImageScrollView.zoomScale < backImageMinZoomScale || rCTImage?.layout == Layout.pictureInPicture {
            backImageScrollView.zoomScale = backImageMinZoomScale
        }
    }
    
    func updateLayoutViewForLayout() {
//        adjustLayoutView.isHidden = false
//        let invisibleLineWidth: CGFloat = 25.0
//
//        switch rCTImage!.layout {
//
//            case .topBottom:
//                adjustLayoutView.frame = CGRect(x: 0.0, y: 0.0, width: rCTImageView.frame.width, height: invisibleLineWidth)
//                adjustLayoutView.center = CGPoint(x: rCTImageView.bounds.maxX / 2, y: rCTImageView.bounds.maxY / 2)
//                adjustLayoutVisibleView.frame = CGRect(x: 0.0, y: 0.0, width: rCTImageView.bounds.width, height: RCT_EditViewController.lineWidth)
//                adjustLayoutVisibleView.center = CGPoint(x: adjustLayoutView.bounds.maxX / 2, y: adjustLayoutView.bounds.maxY / 2)
//
//            case .leftRight:
//                adjustLayoutView.frame = CGRect(x: 0.0, y: 0.0, width: invisibleLineWidth, height: rCTImageView.frame.height)
//                adjustLayoutView.center = CGPoint(x: rCTImageView.bounds.maxX / 2, y: rCTImageView.bounds.maxY / 2)
//                adjustLayoutVisibleView.frame = CGRect(x: 0.0, y: 0.0, width: RCT_EditViewController.lineWidth, height: rCTImageView.bounds.height)
//                adjustLayoutVisibleView.center = CGPoint(x: adjustLayoutView.bounds.maxX / 2, y: adjustLayoutView.bounds.maxY / 2)
//
//            default:
//                adjustLayoutView.isHidden = true
//        }
//
//        rCTImageView.bringSubviewToFront(adjustLayoutView)
    }
}

extension EditImageViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        if scrollView == frontImageScrollView {
            return frontImageView
        } else {
            return backImageView
        }
    }
        
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        print(#function)
    }
    
}

// MARK: - RCT_ContainerViewControllerProtocol

extension EditImageViewController: RCT_ContainerViewControllerProtocol {

    func itemSelected(indexPath: IndexPath, optionSelected: OptionType) {
        switch optionSelected {
            case .layout:
                let layoutSelected = Layout(rawValue: indexPath.item)!
                updateWithLayout(layout: layoutSelected)
            case .filters:
                let filterSelected = Filter(rawValue: indexPath.item)!
                updateWithFilter(filter: filterSelected)
            case .none:
                break
        }
    }
}

// MARK: Filter Methods

extension EditImageViewController {

    func updateWithFilter(filter: Filter) {
        frontImageZoomableView.removeIsMovableView()
        
        if rCTImage != nil {
            
            switch filter {
                
            case .none:
                print("None Filter Selected")
                frontImageView.image = originalFrontImage
                backImageView.image = originalBackImage
                
            case .tonal, .noir, .fade, .chrome, .comic, .poster:
                performFilter(filter: filter)
                
            case .count:
                print("Count Enum")
                
            }
        }
    }

    func setupFilters() {
        if let rCTImage {
            originalFrontImage = rCTImage.imageFrontUIImage
            originalBackImage = rCTImage.imageBackUIImage
        }
        setupFilterThumbnails()
    }

    func setupFilterThumbnails() {

        // TODO: Put on Background Thread (asynch)

        let filterButtonsCount = Filter.count.rawValue
        print("Filter Button Count is: \(Filter.count.rawValue)")

        for filterButtonIndex in 0 ... filterButtonsCount {
            if filterButtonIndex == filterButtonsCount {
                // All Button Images Complete
                // Pass to Container View to populate buttons and reload

                containerViewController?.loadFilterButtonImages(arrayOfImageViews: arrayOfFilterButtonImageViews)
            }
            let filterRawValue = filterButtonIndex
            if let filterSelected = Filter(rawValue: filterRawValue) {
                filterAllThumbnails(filter: filterSelected)
            }
        }
    }

    func filterAllThumbnails(filter: Filter) {

        if rCTImage != nil {
            performThumbnailFilter(filter: filter)
        }
        
    }

    func performThumbnailFilter(filter: Filter) {
        var filterName = filter.filterName
        var thumbnailScale: CGFloat?
        var orientation: UIImage.Orientation?
        var beginFrontImage: CIImage?

        let thumbnailFrame = CGRect(x: 0, y: 0, width: 100, height: 100)

        if let frontImage = originalFrontImage {
            orientation = frontImage.imageOrientation
            let height = frontImage.size.height
            _ = frontImage.size.width
            thumbnailScale = thumbnailFrame.height / height // May Need Aspect Adjustment to Make Square Thumbnail
            // Getting CI Image
            beginFrontImage = CIImage(image: frontImage)
        }

        var options: [String: AnyObject]? = [:]
        if filter == .none {
            filterName = "CISepiaTone"
            options = ["inputIntensity": 0 as AnyObject]
        }

        // Getting Output Using Filter Name Parameter and Options

        // Front Image:
        
        if let outputImage = beginFrontImage?.applyingFilter(filterName, parameters: options!) {
            print("Front Thumbnail Image Name: \(filterName)")
            let cGImage: CGImage = context.createCGImage(outputImage, from: outputImage.extent)!
            let image = UIImage(cgImage: cGImage, scale: thumbnailScale!, orientation: orientation!)
            // Completed UI Images Update on RCT_Image Model
            let filterButtonImageView = UIImageView()
            filterButtonImageView.frame.size = thumbnailFrame.size
            filterButtonImageView.contentMode = .scaleAspectFill // Square?
            filterButtonImageView.image = image
            // Apending to Array of Image Buttons
            arrayOfFilterButtonImageViews.append(filterButtonImageView)
        }
    }

    func performFilter(filter: Filter) {
        var scale: CGFloat?
        var frontImageOrientation: UIImage.Orientation?
        var backImageOrientation: UIImage.Orientation?
        var beginFrontImage: CIImage?
        var beginBackImage: CIImage?

        if let frontImage = originalFrontImage {
            scale = frontImage.scale
            frontImageOrientation = frontImage.imageOrientation

            // Getting CI Image
            beginFrontImage = CIImage(image: frontImage)
        }
        if let backImage = originalBackImage {
            // Getting CI Image
            backImageOrientation = backImage.imageOrientation
            beginBackImage = CIImage(image: backImage)
        }

        var options: [String: AnyObject] = [:]
        if filter.filterName == "CISepiaTone" {
            options = ["inputIntensity": 0.8 as AnyObject]
        }

        // Getting Output Using Filter Name Parameter and Options

        // Front Image:
        if let outputImage = beginFrontImage?.applyingFilter(filter.filterName, parameters: options) {
            print("We Have a Front Output Image")
            let cGImage: CGImage = context.createCGImage(outputImage, from: outputImage.extent)!
            rCTImage?.imageFrontUIImage = UIImage(cgImage: cGImage, scale: scale!, orientation: frontImageOrientation!)
            // Completed UI Images Update on RCT_Image Model
            // Reloading Front Image View
            frontImageView.image = rCTImage!.imageFrontUIImage
        }

        // Back Image:
        if let outputImage = beginBackImage?.applyingFilter(filter.filterName, parameters: options) {
            print("We Have a Back Output Image")
            let cGImage: CGImage = context.createCGImage(outputImage, from: outputImage.extent)!
            rCTImage?.imageBackUIImage = UIImage(cgImage: cGImage, scale: scale!, orientation: backImageOrientation!)
            // Completed UI Images Update on RCT_Image Model
            // Reloading Back Image View
            backImageView.image = rCTImage!.imageBackUIImage
        }
    }

    func logAllFilters() {
        let properties = CIFilter.filterNames(inCategory: kCICategoryStillImage)
        print("These are all Apple's available filters:\n\(properties)")
        for filterName in properties {
            let filter = CIFilter(name: filterName as String)
            print("\(filter?.attributes ?? [:])")
        }
    }
    
}
