import UIKit

class EditImageViewController: UIViewController {
    @IBOutlet var containerView: UIView!
    @IBOutlet var imageViewBackgroundView: UIView!
    @IBOutlet var flipPicImageView: UIView!
    @IBOutlet var topBar: UIStackView!
    @IBOutlet var doneUIButton: UIButton!
    @IBOutlet var swapImagesUIButton: UIButton!
    @IBOutlet var layoutButton: UIButton!
    @IBOutlet var filterButton: UIButton!
    
    var flipPicImage: FlipPicImage?
    var imagesAreSwapped = false
    
    var frontImageView = UIImageView()
    var backImageView = UIImageView()
    
    // View Variables
    var frontImageZoomableView = PanGestureView()
    var frontImageScrollView = UIScrollView()
    var backImageZoomableView = ZoomableView()
    var backImageScrollView = UIScrollView()
    
    var containerViewController: ContainerViewController?
    
    // MARK: - Filter Variables
    
    let context = CIContext()
    var originalFrontImage: UIImage?
    var originalBackImage: UIImage?
    var arrayOfFilterButtonImageViews: [UIImageView] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let flipPicImage = flipPicImage {
            setupController(flipPicImage: flipPicImage)
        }
        setupView()
    }
}

// MARK: - Button actions

extension EditImageViewController {
    @IBAction func cancelButtonTapped(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
        print("Cancel Button Tapped")
    }
    
    @IBAction func shareButtonTapped(_ sender: AnyObject) {
        frontImageZoomableView.removeIsMovableView()
        let imageToSend = imageCapture()
        let text = "Created with “FlipPic—Your Front/Back Camera App”"
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
        containerViewController = children.first! as? ContainerViewController
        containerViewController?.delegate = self
        optionSelected(option: .none)
        doneUIButton.setTitleColor(.green, for: .normal)
        
        if let flipPicImage {
            frontImageView.image = flipPicImage.imageFrontUIImage
            backImageView.image = flipPicImage.imageBackUIImage
        } else {
            print("ERROR: flipPicImage is nil!")
        }
        
        setupFilters()
        flipPicImageView.frame.size = CGSize(width: view.bounds.width, height: view.bounds.width * 1.3)
        updateWithLayout(layout: flipPicImage!.layout)
        containerViewController?.reloadCollection()
    }
    
    private func optionSelected(option: OptionType) {
        var optionToApply = option
        
        filterButton.tintColor = .white
        layoutButton.tintColor = .white
        doneUIButton.tintColor = .white
        swapImagesUIButton.tintColor = .white
        
        switch option {
        case .layout:
            layoutButton.tintColor = .green
            animateContainerView(hide: false)
            
        case .filters:
            filterButton.tintColor = .green
            animateContainerView(hide: false)
            
        case .none:
            optionToApply = .none
            // hide containerView
            animateContainerView(hide: true)
        }
        
        switch optionToApply {
        case .layout:
            containerViewController?.state = .layout(selectedIndex: 0)
        case .filters:
            containerViewController?.state = .filter(selectedIndex: 0)
        case .none:
            containerViewController?.state = .none
        }
        
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
    
    private func setupController(flipPicImage: FlipPicImage) {
        self.flipPicImage = flipPicImage
        
        // setup zoomable views
        frontImageZoomableView = PanGestureView(frame: CGRect(x: 0.0, y: 0.0, width: flipPicImageView.bounds.width, height: flipPicImageView.bounds.height / 2))
        frontImageZoomableView.delegate = self
        backImageZoomableView = ZoomableView(frame: CGRect(x: 0.0, y: flipPicImageView.bounds.maxY / 2, width: flipPicImageView.bounds.width, height: flipPicImageView.bounds.height / 2))
        
        flipPicImageView.addSubview(backImageZoomableView)
        flipPicImageView.addSubview(frontImageZoomableView)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(detectLongPress(recognizer:)))
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapToRemoveView(recognizer:)))
        frontImageZoomableView.gestureRecognizers = [longPressRecognizer, tapGestureRecognizer]
        backImageZoomableView.addGestureRecognizer(tapGestureRecognizer)
        
        // Setup scroll views
        
        frontImageScrollView = UIScrollView(frame: frontImageZoomableView.bounds)
        frontImageScrollView.delegate = self
        frontImageScrollView.backgroundColor = .darkGray
        
        frontImageZoomableView.addSubview(frontImageScrollView)
        frontImageZoomableView.scrollView = frontImageScrollView
        
        backImageScrollView = UIScrollView(frame: backImageZoomableView.bounds)
        backImageScrollView.delegate = self
        backImageScrollView.backgroundColor = .darkGray
        
        backImageZoomableView.addSubview(backImageScrollView)
        
        // Setup Image Views
        frontImageView = UIImageView(image: self.flipPicImage!.imageFrontUIImage)
        frontImageScrollView.addSubview(frontImageView)
        
        backImageView = UIImageView(image: self.flipPicImage!.imageBackUIImage)
        backImageScrollView.addSubview(backImageView)
        
        flipPicImageView.updateBorderForLayout(layout: .littlePicture)
        
        updateWithLayout(layout: .pictureInPicture)
        
        frontImageView.frame = frontImageZoomableView.bounds
        frontImageScrollView.frame = frontImageZoomableView.bounds
        
        backImageView.frame = backImageZoomableView.bounds
        backImageScrollView.frame = backImageZoomableView.bounds
        
        setupScrollViews()
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
        let frontY = (frontImageScrollView.contentSize.height - frontImageScrollView.bounds.height) / 2
        let backY = (backImageScrollView.contentSize.height - backImageScrollView.bounds.height) / 2
        print("\(frontImageScrollView.contentSize.height) \(backImageScrollView.contentSize.height)")
        frontImageScrollView.setContentOffset(CGPoint(x: 0, y: frontY), animated: animated)
        backImageScrollView.setContentOffset(CGPoint(x: 0, y: backY), animated: animated)
    }
    
    private func imageCapture() -> UIImage {
        print("Attempted Image Capture")
        var image = UIImage()
        UIGraphicsBeginImageContextWithOptions(flipPicImageView.frame.size, view.isOpaque, 0.0)
        flipPicImageView.layer.render(in: UIGraphicsGetCurrentContext()!)
        image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
    
    // MARK: - Swap Images
    
    func swapImages(withAnimation: Bool = true) {
        print("frontImageZoom: \(frontImageScrollView.zoomScale); backImageZoom: \(backImageScrollView.zoomScale)")
        print("frontImageMinZoom: \(frontImageScrollView.minimumZoomScale); backImageMinZoom: \(backImageScrollView.minimumZoomScale)")
        
        imagesAreSwapped = !imagesAreSwapped
        print("Swap Image Button Tapped")
        let currentBackImage = flipPicImage?.imageBackUIImage
        let currentFrontImage = flipPicImage?.imageFrontUIImage
        flipPicImage?.imageBackUIImage = currentFrontImage!
        flipPicImage?.imageFrontUIImage = currentBackImage!
        let tempImage = originalBackImage
        originalBackImage = originalFrontImage
        originalFrontImage = tempImage
        
        if withAnimation {
            frontImageView.alpha = 0
            backImageView.alpha = 0
            frontImageView.image = flipPicImage?.imageFrontUIImage
            backImageView.image = flipPicImage?.imageBackUIImage
            
            centerImagesOnYAxis()
            frontImageScrollView.zoomScale = frontImageScrollView.minimumZoomScale
            backImageScrollView.zoomScale = backImageScrollView.minimumZoomScale
            
            UIView.animate(withDuration: 0.5, animations: { () in
                self.frontImageView.alpha = 1
                self.backImageView.alpha = 1
            }, completion: { _ in
            })
        } else {
            frontImageView.image = flipPicImage?.imageFrontUIImage
            backImageView.image = flipPicImage?.imageBackUIImage
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
        if recognizer.state.rawValue == 1, flipPicImage?.layout == Layout.pictureInPicture {
            frontImageZoomableView.toggleIsMoveable()
            frontImageZoomableView.setLastLocation()
            frontImageZoomableView.lastPointLocation = recognizer.location(in: flipPicImageView)
            print("Long press ended")
            
        } else if recognizer.state.rawValue == 2, flipPicImage?.layout == Layout.pictureInPicture {
            // pass the press along to the panDetected Method
            if frontImageZoomableView.isMoveableView != nil {
                let pointCenter = recognizer.location(in: flipPicImageView)
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
        let heightRatio = frontImageZoomableView.bounds.height / flipPicImageView.bounds.height
        let widthRatio = frontImageZoomableView.bounds.width / flipPicImageView.bounds.width
        let topmostBound: CGFloat = (flipPicImageView.bounds.maxY * heightRatio) / 2
        let bottommostBound: CGFloat = (flipPicImageView.bounds.maxY - topmostBound)
        let leftmostBound: CGFloat = (flipPicImageView.bounds.maxX * widthRatio) / 2
        let rightmostBound: CGFloat = (flipPicImageView.bounds.maxX - leftmostBound)
        var frontImageX: CGFloat = 0.0
        var frontImageY: CGFloat = 0.0
        
        if center.x <= rightmostBound, center.x >= leftmostBound {
            frontImageX = center.x
        } else {
            if center.x > rightmostBound {
                frontImageX = rightmostBound
            } else {
                frontImageX = leftmostBound
            }
        }
        if center.y <= bottommostBound, center.y >= topmostBound {
            frontImageY = center.y
        } else {
            if center.y > bottommostBound {
                frontImageY = bottommostBound
            } else {
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
        LayoutController.isCornersLayout = false
    }
    
    private func updateWithLayout(layout: Layout) {
        flipPicImage?.layout = layout
        clearMasks()
        clearSwappedImages()
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
            print("Top/Bottom Layout Selected")
            frontImageX = 0.0
            frontImageY = 0.0
            frontImageWidth = flipPicImageView.bounds.width
            frontImageHeight = flipPicImageView.bounds.height / 2
            backImageX = 0.0
            backImageY = flipPicImageView.bounds.maxY / 2
            backImageWidth = flipPicImageView.bounds.width
            backImageHeight = flipPicImageView.bounds.height / 2
            
        case .leftRight:
            print("Left/Right Layout Selected")
            frontImageX = 0.0
            frontImageY = 0.0
            frontImageWidth = flipPicImageView.bounds.width / 2
            frontImageHeight = flipPicImageView.bounds.height
            backImageX = flipPicImageView.bounds.maxX / 2
            backImageY = 0.0
            backImageWidth = flipPicImageView.bounds.width / 2
            backImageHeight = flipPicImageView.bounds.height
            
        case .pictureInPicture:
            print("Picture-in-Picture Layout Selected")
            let yBuffer: CGFloat = 8.0
            let xBuffer: CGFloat = 8.0
            
            frontImageX = (flipPicImageView.bounds.maxX - (flipPicImageView.bounds.maxX / 3 + xBuffer))
            frontImageY = (flipPicImageView.bounds.maxY - (flipPicImageView.bounds.maxY / 3 + yBuffer))
            frontImageWidth = flipPicImageView.bounds.width / 3
            frontImageHeight = flipPicImageView.bounds.height / 3
            backImageX = 0.0
            backImageY = 0.0
            backImageWidth = flipPicImageView.bounds.width
            backImageHeight = flipPicImageView.bounds.height
            
            // Add Borders
            frontImageSubLayout = SubLayout.littlePicture
            
        case .upperLeftLowerRight:
            print("UpperLeft/LowerRight Layout Selected")
            LayoutController.isCornersLayout = true
            frontImageX = 0.0
            frontImageY = 0.0
            frontImageWidth = flipPicImageView.bounds.width
            frontImageHeight = flipPicImageView.bounds.height
            backImageX = 0.0
            backImageY = 0.0
            backImageWidth = flipPicImageView.bounds.width
            backImageHeight = flipPicImageView.bounds.height
            
            frontImageZoomableView.maskLayout = MaskLayout.topLeft
            backImageZoomableView.maskLayout = MaskLayout.bottomRight
            
            // Add Borders
            frontImageSubLayout = SubLayout.topLeft
            backImageSubLayout = SubLayout.bottomRight
            
        case .upperRightLowerLeft:
            print("UpperRight/LowerLeft Layout Selected")
            LayoutController.isCornersLayout = true
            frontImageX = 0.0
            frontImageY = 0.0
            frontImageWidth = flipPicImageView.bounds.width
            frontImageHeight = flipPicImageView.bounds.height
            backImageX = 0.0
            backImageY = 0.0
            backImageWidth = flipPicImageView.bounds.width
            backImageHeight = flipPicImageView.bounds.height
            
            frontImageZoomableView.maskLayout = MaskLayout.topRight
            backImageZoomableView.maskLayout = MaskLayout.bottomLeft
            
            // Add Borders
            frontImageSubLayout = SubLayout.topRight
            backImageSubLayout = SubLayout.bottomLeft
            
        case .count:
            print("Layout Enum Count")
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
        print("flipPicImageView width: \(flipPicImageView.bounds.width), flipPicImageView height: \(flipPicImageView.bounds.height)")
        
        let frontImageZoomScaleWidth = frontImageZoomableView.bounds.width / (frontImageView.bounds.width)
        let frontImageZoomScaleHeight = frontImageZoomableView.bounds.height / (frontImageView.bounds.height)
        let frontImageMinZoomScale: CGFloat
        
        print("frontWidth: \(frontImageZoomableView.bounds.width) / \(frontImageView.bounds.width) = \(frontImageZoomScaleWidth), frontHeight: \(frontImageZoomableView.bounds.height) / \(frontImageView.bounds.height) = \(frontImageZoomScaleHeight)")
        
        frontImageZoomScaleWidth > frontImageZoomScaleHeight ? (frontImageMinZoomScale = frontImageZoomScaleWidth) : (frontImageMinZoomScale = frontImageZoomScaleHeight)
        
        frontImageScrollView.minimumZoomScale = frontImageMinZoomScale
        frontImageScrollView.maximumZoomScale = 5.0
        
        if frontImageScrollView.zoomScale < frontImageMinZoomScale || flipPicImage?.layout == Layout.pictureInPicture {
            frontImageScrollView.zoomScale = frontImageMinZoomScale
        }
        
        let backImageZoomScaleWidth = backImageZoomableView.bounds.width / (backImageView.bounds.width)
        let backImageZoomScaleHeight = backImageZoomableView.bounds.height / (backImageView.bounds.height)
        let backImageMinZoomScale: CGFloat
        
        print("backWidth: \(backImageZoomableView.bounds.width) / \(backImageView.bounds.width) = \(backImageZoomScaleWidth), backHeight: \(backImageZoomableView.bounds.height) / \(backImageView.bounds.height) = \(backImageZoomScaleHeight)")
        
        backImageZoomScaleWidth > backImageZoomScaleHeight ? (backImageMinZoomScale = backImageZoomScaleWidth) : (backImageMinZoomScale = backImageZoomScaleHeight)
        
        backImageScrollView.minimumZoomScale = backImageMinZoomScale
        backImageScrollView.maximumZoomScale = 5.0
        
        if backImageScrollView.zoomScale < backImageMinZoomScale || flipPicImage?.layout == Layout.pictureInPicture {
            backImageScrollView.zoomScale = backImageMinZoomScale
        }
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

// MARK: - ContainerViewControllerProtocol

extension EditImageViewController: ContainerViewControllerProtocol {
    func didSelectItem(at indexPath: IndexPath, with option: OptionType) {
        switch option {
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
        
        if flipPicImage != nil {
            switch filter {
            case .none:
                print("None Filter Selected")
                frontImageView.image = originalFrontImage
                backImageView.image = originalBackImage
                
            case .tonal, .noir, .fade, .chrome, .comic, .poster:
                performFilter(filter: filter)
                
            case .count:
                print("Filter Enum Count")
            }
        }
    }
    
    func setupFilters() {
        if let flipPicImage {
            originalFrontImage = flipPicImage.imageFrontUIImage
            originalBackImage = flipPicImage.imageBackUIImage
        }
        setupFilterThumbnails()
    }

    // TODO: Consider moving intensive image processing/loading tasks to a background thread for performance 
    // optimization. Ensure thread safety for any shared data and switch back to the main thread for UI updates.
    // Implement appropriate error handling and validate performance improvements. This change aims to enhance the
    // responsiveness of the app by preventing UI blockages on the main thread.

    func setupFilterThumbnails() {
        let filterButtonsCount = Filter.count.rawValue
        print("Filter Button Count is: \(Filter.count.rawValue)")
        
        for filterButtonIndex in 0 ... filterButtonsCount {
            if filterButtonIndex == filterButtonsCount {
                let images = arrayOfFilterButtonImageViews.compactMap { $0.image }
                containerViewController?.updateFilterButtonImages(images)
            }
            let filterRawValue = filterButtonIndex
            if let filterSelected = Filter(rawValue: filterRawValue) {
                filterAllThumbnails(filter: filterSelected)
            }
        }
    }
    
    func filterAllThumbnails(filter: Filter) {
        if flipPicImage != nil {
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
            thumbnailScale = thumbnailFrame.height / height // May need aspect adjustment to make square thumbnail
            // Getting CI Image
            beginFrontImage = CIImage(image: frontImage) ?? frontImage.ciImage
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
            // Completed UI Images Update on Image Model
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
            beginFrontImage = CIImage(image: frontImage) ?? frontImage.ciImage
        }
        if let backImage = originalBackImage {
            // Getting CI Image
            backImageOrientation = backImage.imageOrientation
            beginBackImage = CIImage(image: backImage) ?? backImage.ciImage
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
            flipPicImage?.imageFrontUIImage = UIImage(cgImage: cGImage, scale: scale!, orientation: frontImageOrientation!)
            // Completed UI Images Update on Image Model
            // Reloading Front Image View
            frontImageView.image = flipPicImage!.imageFrontUIImage
        }
        
        // Back Image:
        if let outputImage = beginBackImage?.applyingFilter(filter.filterName, parameters: options) {
            print("We Have a Back Output Image")
            let cGImage: CGImage = context.createCGImage(outputImage, from: outputImage.extent)!
            flipPicImage?.imageBackUIImage = UIImage(cgImage: cGImage, scale: scale!, orientation: backImageOrientation!)
            // Completed UI Images Update on Image Model
            // Reloading Back Image View
            backImageView.image = flipPicImage!.imageBackUIImage
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
