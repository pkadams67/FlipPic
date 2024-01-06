import CoreImage
import UIKit

class EditViewController: UIViewController {
    static let lineWidth: CGFloat = 5.0
    
    // MARK: Variables
    
    // Swap Button
    var swapImageButton = UIButton()
    var imagesAreSwapped = false
    var imageToSend: UIImage?
    var flipPicImage: FlipPicImage?
    var containerViewController: ContainerViewController?
    var frontImageView = UIImageView()
    var backImageView = UIImageView()
    
    // Views
    var frontImageZoomableView = PanGestureView()
    var frontImageScrollView = UIScrollView()
    var backImageZoomableView = ZoomableView()
    var backImageScrollView = UIScrollView()
    
    // Adjusting Layout View
    var adjustLayoutView = UIView()
    var adjustLayoutVisibleView = UIView()
    var adjustLayoutViewLastPosition = CGPoint()
    var frontImageLastFrame = CGRect()
    var backImageLastFrame = CGRect()
    
    // Filter
    let context = CIContext()
    var originalFrontImage: UIImage?
    var originalBackImage: UIImage?
    var arrayOfFilterButtonImageViews: [UIImageView] = []
    
    // MARK: Outlets
    
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var toolbarLayoutOption: UIBarButtonItem!
    @IBOutlet var toolbarFilterOption: UIBarButtonItem!
    @IBOutlet var containerView: UIView!
    @IBOutlet var layoutButton: UIBarButtonItem!
    @IBOutlet var filterButton: UIBarButtonItem!
    @IBOutlet var imageViewBackgroundView: UIView!
    @IBOutlet var flipPicImageView: UIView!
    @IBOutlet var topBar: UIStackView!
    @IBOutlet var doneButton: UIBarButtonItem!
    @IBOutlet var doneButtonFlexSpace: UIBarButtonItem!
    @IBOutlet var doneUIButton: UIButton!
    @IBOutlet var swapImagesBarButton: UIBarButtonItem!
    @IBOutlet var swapImagesUIButton: UIButton!
    
    override var prefersStatusBarHidden: Bool {
        true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        toolbarLayoutOption.tintColor = .white
        toolbarFilterOption.tintColor = .white
        toolbar.clipsToBounds = true
        containerViewController = children.first as? ContainerViewController
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
    
    func setMockData() {
        //        let frontImage = UIImage(named: "mock_selfie")
        //        let backImage = UIImage(named: "mock_landscape")
        //        let frontImageData = ImageController.imageToData(frontImage!)!
        //        let backImageData = ImageController.imageToData(backImage!)!
        //        let image1 = ImageController.dataToImage(frontImageData)!
        //        let image2 = ImageController.dataToImage(backImageData)!
        //        flipPicImageView.backgroundColor = UIColor(patternImage: image)
        //        setUpImages(image1, back: image2)
    }
    
    // MARK: Functions
    
    func setupAdjustLayoutView() {
        adjustLayoutView.frame = flipPicImageView!.frame
        adjustLayoutView.backgroundColor = .clear
        adjustLayoutVisibleView.backgroundColor = .white
        adjustLayoutView.addSubview(adjustLayoutVisibleView)
        flipPicImageView.addSubview(adjustLayoutView)
        adjustLayoutView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(adjustLayoutView(recognizer:))))
        updateLayoutViewForLayout()
    }
    
    func updateLayoutViewForLayout() {
        adjustLayoutView.isHidden = false
        let invisibleLineWidth: CGFloat = 25.0
        
        switch flipPicImage!.layout {
        case .topBottom:
            adjustLayoutView.frame = CGRect(x: 0.0, y: 0.0, width: flipPicImageView.frame.width, height: invisibleLineWidth)
            adjustLayoutView.center = CGPoint(x: flipPicImageView.bounds.maxX / 2, y: flipPicImageView.bounds.maxY / 2)
            adjustLayoutVisibleView.frame = CGRect(x: 0.0, y: 0.0, width: flipPicImageView.bounds.width, height: EditViewController.lineWidth)
            adjustLayoutVisibleView.center = CGPoint(x: adjustLayoutView.bounds.maxX / 2, y: adjustLayoutView.bounds.maxY / 2)
            
        case .leftRight:
            adjustLayoutView.frame = CGRect(x: 0.0, y: 0.0, width: invisibleLineWidth, height: flipPicImageView.frame.height)
            adjustLayoutView.center = CGPoint(x: flipPicImageView.bounds.maxX / 2, y: flipPicImageView.bounds.maxY / 2)
            adjustLayoutVisibleView.frame = CGRect(x: 0.0, y: 0.0, width: EditViewController.lineWidth, height: flipPicImageView.bounds.height)
            adjustLayoutVisibleView.center = CGPoint(x: adjustLayoutView.bounds.maxX / 2, y: adjustLayoutView.bounds.maxY / 2)
            
        default:
            adjustLayoutView.isHidden = true
        }
        
        flipPicImageView.bringSubviewToFront(adjustLayoutView)
    }
    
    @objc func adjustLayoutView(recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .began {
            adjustLayoutViewLastPosition = adjustLayoutView.center
            frontImageLastFrame = frontImageZoomableView.frame
            backImageLastFrame = backImageZoomableView.frame
        }
        let translation = recognizer.translation(in: flipPicImageView)
        switch flipPicImage!.layout {
        case .topBottom:
            var layoutViewY: CGFloat = adjustLayoutViewLastPosition.y + translation.y
            let adjustmentBuffer = flipPicImageView.frame.height / 4 // each image must be at least 1/4 of the flipPicImageView
            let uppermostBound: CGFloat = (flipPicImageView.bounds.minY + adjustmentBuffer)
            let lowermostBound: CGFloat = (flipPicImageView.bounds.maxY - adjustmentBuffer)
            var frontImageHeight: CGFloat = frontImageLastFrame.height + translation.y
            var backImageHeight: CGFloat = backImageLastFrame.height - translation.y
            var backImageY: CGFloat = backImageLastFrame.origin.y + translation.y
            
            if layoutViewY > lowermostBound {
                layoutViewY = lowermostBound
                
                let yPositionPercentage = (lowermostBound / flipPicImageView.bounds.maxY)
                frontImageHeight = flipPicImageView.bounds.height * yPositionPercentage
                backImageHeight = flipPicImageView.bounds.height - (flipPicImageView.bounds.height * yPositionPercentage)
                backImageY = lowermostBound
                print("flipPicImageView.bounds.height: \(flipPicImageView.bounds.height); yPositionPercentage: \(yPositionPercentage)")
                
            } else if layoutViewY < uppermostBound {
                layoutViewY = uppermostBound
                
                let yPositionPercentage = (uppermostBound / flipPicImageView.bounds.maxY)
                frontImageHeight = flipPicImageView.bounds.height * yPositionPercentage
                backImageHeight = flipPicImageView.bounds.height - (flipPicImageView.bounds.height * yPositionPercentage)
                backImageY = uppermostBound
            }
            
            adjustLayoutView.center = CGPoint(x: flipPicImageView.bounds.maxX / 2, y: layoutViewY)
            frontImageZoomableView.frame.size.height = frontImageHeight
            backImageZoomableView.frame.size.height = backImageHeight
            backImageZoomableView.frame.origin.y = backImageY
            
        case .leftRight:
            var layoutViewX: CGFloat = adjustLayoutViewLastPosition.x + translation.x
            let adjustmentBuffer = flipPicImageView.frame.width / 4
            let rightmostBound: CGFloat = (flipPicImageView.bounds.maxX - adjustmentBuffer)
            let leftmostBound: CGFloat = (flipPicImageView.bounds.minX + adjustmentBuffer)
            var frontImageWidth = frontImageLastFrame.width + translation.x
            var backImageWidth = backImageLastFrame.width - translation.x
            var backImageX = backImageLastFrame.origin.x + translation.x
            
            if layoutViewX > rightmostBound {
                layoutViewX = rightmostBound
                let xPositionPercentage = (rightmostBound / flipPicImageView.bounds.maxX)
                frontImageWidth = flipPicImageView.bounds.width * xPositionPercentage
                backImageWidth = flipPicImageView.bounds.width - (flipPicImageView.bounds.width * xPositionPercentage)
                backImageX = rightmostBound
                
            } else if layoutViewX < leftmostBound {
                layoutViewX = leftmostBound
                let xPositionPercentage = (leftmostBound / flipPicImageView.bounds.maxX)
                frontImageWidth = flipPicImageView.bounds.width * xPositionPercentage
                backImageWidth = flipPicImageView.bounds.width - (flipPicImageView.bounds.width * xPositionPercentage)
                backImageX = leftmostBound
            }
            adjustLayoutView.center = CGPoint(x: layoutViewX, y: flipPicImageView.bounds.maxY / 2)
            frontImageZoomableView.frame.size.width = frontImageWidth
            backImageZoomableView.frame.size.width = backImageWidth
            backImageZoomableView.frame.origin.x = backImageX
        default:
            
            break
        }
        frontImageScrollView.frame = frontImageZoomableView.bounds
        backImageScrollView.frame = backImageZoomableView.bounds
    }
    
    func setupScrollViews() {
        let frontImageZoomScaleWidth = frontImageZoomableView.bounds.width / (frontImageView.image?.size.width)!
        let frontImageZoomScaleHeight = frontImageZoomableView.bounds.height / (frontImageView.image?.size.height)!
        let frontImageMinZoomScale: CGFloat
        
        frontImageZoomScaleWidth > frontImageZoomScaleHeight ? (frontImageMinZoomScale = frontImageZoomScaleWidth) : (frontImageMinZoomScale = frontImageZoomScaleHeight)
        
        frontImageScrollView.minimumZoomScale = frontImageMinZoomScale
        frontImageScrollView.maximumZoomScale = 5.0
        frontImageScrollView.zoomScale = frontImageMinZoomScale
        
        let backImageZoomScaleWidth = backImageZoomableView.bounds.width / (backImageView.image?.size.width)!
        let backImageZoomScaleHeight = backImageZoomableView.bounds.height / (backImageView.image?.size.height)!
        let backImageMinZoomScale: CGFloat
        
        backImageZoomScaleWidth > backImageZoomScaleHeight ? (backImageMinZoomScale = backImageZoomScaleWidth) : (backImageMinZoomScale = backImageZoomScaleHeight)
        
        backImageScrollView.minimumZoomScale = backImageMinZoomScale
        backImageScrollView.maximumZoomScale = 5.0
        backImageScrollView.zoomScale = backImageMinZoomScale
        
        centerImagesOnYAxis()
    }
    
    func centerImagesOnYAxis(animated: Bool = false) {
        let frontY = (frontImageScrollView.contentSize.height - frontImageScrollView.bounds.height) / 2
        let backY = (backImageScrollView.contentSize.height - backImageScrollView.bounds.height) / 2
        print("\(frontImageScrollView.contentSize.height) \(backImageScrollView.contentSize.height)")
        frontImageScrollView.setContentOffset(CGPoint(x: 0, y: frontY), animated: animated)
        backImageScrollView.setContentOffset(CGPoint(x: 0, y: backY), animated: animated)
    }
    
    // TODO: Evaluate the use of 'frame' vs 'bounds' in the context of zooming and scrolling. 'Bounds' might be more 
    // appropriate for calculations related to the view's own coordinate system, especially for zoom scale computation.
    // Ensure that changing to 'bounds' aligns with the view's layout and does not disrupt the expected zooming and
    // scrolling behavior.
    
    func updateScrollViews() {
        print("flipPicImageView width: \(flipPicImageView.bounds.width), flipPicImageView height: \(flipPicImageView.bounds.height)")
        let frontImageZoomScaleWidth = frontImageZoomableView.bounds.width / (frontImageView.image?.size.width)!
        let frontImageZoomScaleHeight = frontImageZoomableView.bounds.height / (frontImageView.image?.size.height)!
        let frontImageMinZoomScale: CGFloat
        
        print("frontWidth: \(frontImageZoomableView.bounds.width) / \(String(describing: frontImageView.image?.size.width)) = \(frontImageZoomScaleWidth), frontHeight: \(frontImageZoomableView.bounds.height) / \(String(describing: frontImageView.image?.size.height)) = \(frontImageZoomScaleHeight)")
        
        frontImageZoomScaleWidth > frontImageZoomScaleHeight ? (frontImageMinZoomScale = frontImageZoomScaleWidth) : (frontImageMinZoomScale = frontImageZoomScaleHeight)
        
        frontImageScrollView.minimumZoomScale = frontImageMinZoomScale
        frontImageScrollView.maximumZoomScale = 5.0
        
        if frontImageScrollView.zoomScale < frontImageMinZoomScale || flipPicImage?.layout == Layout.pictureInPicture {
            frontImageScrollView.zoomScale = frontImageMinZoomScale
        }
        
        let backImageZoomScaleWidth = backImageZoomableView.bounds.width / (backImageView.image?.size.width)!
        let backImageZoomScaleHeight = backImageZoomableView.bounds.height / (backImageView.image?.size.height)!
        let backImageMinZoomScale: CGFloat
        
        print("backWidth: \(backImageZoomableView.bounds.width) / \(backImageView.image?.size.width ?? 0.0) = \(backImageZoomScaleWidth), backHeight: \(backImageZoomableView.bounds.height) / \(backImageView.image?.size.height ?? 0.0) = \(backImageZoomScaleHeight)")
        
        backImageZoomScaleWidth > backImageZoomScaleHeight ? (backImageMinZoomScale = backImageZoomScaleWidth) : (backImageMinZoomScale = backImageZoomScaleHeight)
        
        backImageScrollView.minimumZoomScale = backImageMinZoomScale
        backImageScrollView.maximumZoomScale = 5.0
        
        if backImageScrollView.zoomScale < backImageMinZoomScale || flipPicImage?.layout == Layout.pictureInPicture {
            backImageScrollView.zoomScale = backImageMinZoomScale
        }
    }
    
    func setupController(flipPicImage: FlipPicImage) {
        self.flipPicImage = flipPicImage
        
        _ = view
        _ = flipPicImageView
        
        // Setup zoomable views
        frontImageZoomableView = PanGestureView(frame: CGRect(x: 0.0, y: 0.0, width: flipPicImageView.bounds.width, height: flipPicImageView.bounds.height / 2))
        frontImageZoomableView.delegate = self
        backImageZoomableView = ZoomableView(frame: CGRect(x: 0.0, y: flipPicImageView.bounds.maxY / 2, width: flipPicImageView.bounds.width, height: flipPicImageView.bounds.height / 2))
        
        flipPicImageView.addSubview(backImageZoomableView)
        flipPicImageView.addSubview(frontImageZoomableView)
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(detectLongPress(recognizer:)))
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapToRemoveView(recognizer:)))
        frontImageZoomableView.gestureRecognizers = [longPressRecognizer, tapGestureRecognizer]
        backImageZoomableView.addGestureRecognizer(tapGestureRecognizer)
        
        // Setup Scroll Views
        frontImageScrollView = UIScrollView(frame: frontImageZoomableView.bounds)
        frontImageScrollView.delegate = self
        frontImageScrollView.backgroundColor = .darkGray
        backImageScrollView = UIScrollView(frame: backImageZoomableView.bounds)
        backImageScrollView.delegate = self
        backImageScrollView.backgroundColor = .darkGray
        
        frontImageZoomableView.addSubview(frontImageScrollView)
        frontImageZoomableView.scrollView = frontImageScrollView
        backImageZoomableView.addSubview(backImageScrollView)
        backImageZoomableView.scrollView = frontImageScrollView
        
        // Setup Image Views
        frontImageView = UIImageView(image: flipPicImage.imageFrontUIImage)
        backImageView = UIImageView(image: flipPicImage.imageBackUIImage)
        
        frontImageScrollView.addSubview(frontImageView)
        backImageScrollView.addSubview(backImageView)
        
        setupScrollViews()
        setupAdjustLayoutView()
        
        flipPicImageView.updateBorderForLayout(layout: .bigPicture)
        updateWithLayout(layout: Layout(rawValue: 0)!)
    }
    
    func setUpImages(front: UIImage, back: UIImage) {
        //        let image1View = UIImageView()
        //        image1View.frame.origin.x = self.view.frame.origin.x
        //        image1View.frame.size = CGSize(width: self.view.frame.width / CGFloat(2) , height: self.view.frame.height)
        //        image1View.contentMode = .ScaleAspectFit
        //        self.view.addSubview(image1View)
        //        let image2View = UIImageView()
        //        image2View.frame.origin.x = self.view.frame.width / 2
        //        image2View.frame.size = CGSize(width: self.view.frame.width / CGFloat(2) , height: self.view.frame.height)
        //        image2View.contentMode = .ScaleAspectFit
        //        self.view.addSubview(image2View)
        //        image1View.image = front
        //        image2View.image = back
    }
    
    func imageCapture() {
        print("Attempted Image Capture")
        UIGraphicsBeginImageContextWithOptions(flipPicImageView.frame.size, view.isOpaque, 0.0)
        flipPicImageView.layer.render(in: UIGraphicsGetCurrentContext()!)
        imageToSend = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
    }
    
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
    
    // MARK: Actions
    
    @IBAction func doneButtonTapped(_ sender: AnyObject) {
        optionSelected(option: .none)
    }
    
    @IBAction func cancelButtonTapped(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
        print("Cancel Button Tapped")
    }
    
    @IBAction func swapImageButtonTapped(_ sender: AnyObject) {
        swapImages()
    }
    
    @IBAction func shareButtonTapped(_ sender: AnyObject) {
        frontImageZoomableView.removeIsMovableView()
        imageCapture()
        print("Share Button Tapped")
        let shareTextFlipPicImage = "Created with “FlipPic—Your Front/Back Camera App”"
        if let image = imageToSend {
            print("Sending Image")
            let shareViewController = UIActivityViewController(activityItems: [image, shareTextFlipPicImage], applicationActivities: nil)
            shareViewController.popoverPresentationController?.sourceView = view
            present(shareViewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func layoutButtonTapped(_ sender: AnyObject) {
        print("Layout Button Tapped")
        
        optionSelected(option: OptionType.layout)
    }
    
    @IBAction func filterButtonTapped(sender: AnyObject) {
        print("Filter Button Tapped")
        
        optionSelected(option: OptionType.filters)
    }
    
    func optionSelected(option: OptionType) {
        var optionToApply = option
        let currentOptionSelected: OptionType?
        if let state = containerViewController?.state {
            switch state {
            case .layout:
                currentOptionSelected = .layout
            case .filter:
                currentOptionSelected = .filters
            case .none:
                currentOptionSelected = OptionType.none
            }
        } else {
            currentOptionSelected = nil
        }
        
        switch option {
        case .layout:
            switch currentOptionSelected {
            case .layout:
                animateContainerView(hide: true)
                toolbarLayoutOption.tintColor = .white
                optionToApply = .none
                
            case .filters:
                toolbarFilterOption.tintColor = .white
                toolbarLayoutOption.tintColor = .green
                
            case .none?:
                animateContainerView(hide: false)
                toolbarLayoutOption.tintColor = .green
                
            case nil: break
                
            }
            
        case .filters:
            
            switch currentOptionSelected {
            case .layout:
                toolbarLayoutOption.tintColor = .white
                toolbarFilterOption.tintColor = .green
                
            case .filters:
                animateContainerView(hide: true)
                toolbarFilterOption.tintColor = .white
                optionToApply = .none
                
            case .none?:
                animateContainerView(hide: false)
                toolbarFilterOption.tintColor = .green
                
            case nil: break
            }
            
        case .none:
            animateContainerView(hide: true)
            
            switch currentOptionSelected {
            case .filters:
                toolbarFilterOption.tintColor = .white
                
            case .layout:
                toolbarLayoutOption.tintColor = .white
                
            case .none?: break
                
            case nil: break
                
            }
            optionToApply = .none
        }
        
        switch optionToApply {
        case .layout:
            containerViewController?.state = .layout(selectedIndex: 0) // Use an appropriate index
        case .filters:
            containerViewController?.state = .filter(selectedIndex: 0) // Use an appropriate index
        case .none:
            containerViewController?.state = .none
        }
        
        if optionToApply != .none {
            containerViewController?.reloadCollection()
        }
        
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
}

// MARK: - ContainerViewControllerProtocol

extension EditViewController: ContainerViewControllerProtocol {
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

extension EditViewController {
    func updateWithFilter(filter: Filter) {
        frontImageZoomableView.removeIsMovableView()
        
        _ = "CIPhotoEffectMono"
        let tonalFilterName = "CIPhotoEffectTonal"
        let noirFilterName = "CIPhotoEffectNoir"
        let fadeFilterName = "CIPhotoEffectFade"
        let chromeFilterName = "CIPhotoEffectChrome"
        let comicFilterName = "CIComicEffect"
        let posterFilterName = "CIColorPosterize"
        
        if flipPicImage != nil {
            switch filter {
            case .none:
                print("None Filter Selected")
                frontImageView.image = originalFrontImage
                backImageView.image = originalBackImage
                
            case .tonal:
                print("Tonal Filter Selected")
                performFilter(filterName: tonalFilterName)
                
            case .noir:
                print("Noir Filter Selected")
                performFilter(filterName: noirFilterName)
                
            case .fade:
                print("Fade Filter Selected")
                performFilter(filterName: fadeFilterName)
                
            case .chrome:
                print("Chrome Filter Selected")
                performFilter(filterName: chromeFilterName)
                
            case .comic:
                print("Comic Filter Selected")
                performFilter(filterName: comicFilterName)
                
            case .poster:
                print("Poster Filter Selected")
                performFilter(filterName: posterFilterName)
                
            case .count:
                print("Count Enum")
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
    
    func setupFilterThumbnails() {
        let filterButtonsCount = Filter.count.rawValue
        print("Filter Button Count is: \(filterButtonsCount)")
        
        var images: [UIImage] = []
        for filterButtonIndex in 0..<filterButtonsCount {
            let filterRawValue = filterButtonIndex
            if let filterSelected = Filter(rawValue: filterRawValue) {
                filterAllThumbnails(filter: filterSelected)
            }           
            if let imageView = arrayOfFilterButtonImageViews[safe: filterButtonIndex], let image = imageView.image {
                images.append(image)
            }
        }
        containerViewController?.updateFilterButtonImages(images)
    }
    
    func filterAllThumbnails(filter: Filter) {
        let tonalFilterName = "CIPhotoEffectTonal"
        let noirFilterName = "CIPhotoEffectNoir"
        let fadeFilterName = "CIPhotoEffectFade"
        let chromeFilterName = "CIPhotoEffectChrome"
        let comicFilterName = "CIComicEffect"
        let posterFilterName = "CIColorPosterize"
        
        if flipPicImage != nil {
            switch filter {
            case .none:
                print("None Filter Selected")
                performThumbnailFilter(filterName: "None")
                
            case .tonal:
                print("Tonal Filter Selected")
                performThumbnailFilter(filterName: tonalFilterName)
                
            case .noir:
                print("Noir Filter Selected")
                performThumbnailFilter(filterName: noirFilterName)
                
            case .fade:
                print("Fade Filter Selected")
                performThumbnailFilter(filterName: fadeFilterName)
                
            case .chrome:
                print("Chrome Filter Selected")
                performThumbnailFilter(filterName: chromeFilterName)
                
            case .comic:
                print("Comic Filter Selected")
                performThumbnailFilter(filterName: comicFilterName)
                
            case .poster:
                print("Poster Filter Selected")
                performThumbnailFilter(filterName: posterFilterName)
                
            case .count:
                print("Count Enum")
            }
        }
    }
    
    func performThumbnailFilter(filterName: String) {
        var filterName = filterName
        var thumbnailScale: CGFloat?
        var orientation: UIImage.Orientation?
        var beginFrontImage: CIImage?
        
        let thumbnailFrame = CGRect(x: 0, y: 0, width: 100, height: 100)
        
        if let frontImage = originalFrontImage {
            orientation = frontImage.imageOrientation
            let height = frontImage.size.height
            _ = frontImage.size.width
            thumbnailScale = thumbnailFrame.height / height
            beginFrontImage = CIImage(image: frontImage)
        }
        
        var options: [String: AnyObject]? = [:]
        if filterName == "None" {
            filterName = "CISepiaTone"
            options = ["inputIntensity": 0 as AnyObject]
        }
        
        if let outputImage = beginFrontImage?.applyingFilter(filterName, parameters: options!) {
            print("Front Thumbnail Image Name: \(filterName)")
            let cGImage: CGImage = context.createCGImage(outputImage, from: outputImage.extent)!
            let image = UIImage(cgImage: cGImage, scale: thumbnailScale!, orientation: orientation!)
            let filterButtonImageView = UIImageView()
            filterButtonImageView.frame.size = thumbnailFrame.size
            filterButtonImageView.contentMode = .scaleAspectFill
            filterButtonImageView.image = image
            arrayOfFilterButtonImageViews.append(filterButtonImageView)
        }
    }
    
    func performFilter(filterName: String) {
        var scale: CGFloat?
        var frontImageOrientation: UIImage.Orientation?
        var backImageOrientation: UIImage.Orientation?
        var beginFrontImage: CIImage?
        var beginBackImage: CIImage?
        
        if let frontImage = originalFrontImage {
            scale = frontImage.scale
            frontImageOrientation = frontImage.imageOrientation
            beginFrontImage = CIImage(image: frontImage)
        }
        if let backImage = originalBackImage {
            backImageOrientation = backImage.imageOrientation
            beginBackImage = CIImage(image: backImage)
        }
        
        var options: [String: AnyObject]?
        if filterName == "CISepiaTone" {
            options = ["inputIntensity": 0.8 as AnyObject]
        }
        
        if let outputImage = beginFrontImage?.applyingFilter(filterName, parameters: options!) {
            print("We Have a Front Output Image")
            let cGImage: CGImage = context.createCGImage(outputImage, from: outputImage.extent)!
            flipPicImage?.imageFrontUIImage = UIImage(cgImage: cGImage, scale: scale!, orientation: frontImageOrientation!)
            frontImageView.image = flipPicImage!.imageFrontUIImage
        }
        
        if let outputImage = beginBackImage?.applyingFilter(filterName, parameters: options!) {
            print("We Have a Back Output Image")
            let cGImage: CGImage = context.createCGImage(outputImage, from: outputImage.extent)!
            flipPicImage?.imageBackUIImage = UIImage(cgImage: cGImage, scale: scale!, orientation: backImageOrientation!)
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

// MARK: Layout Methods

extension EditViewController {
    func clearMasks() {
        frontImageZoomableView.maskLayout = MaskLayout.none
        backImageZoomableView.maskLayout = MaskLayout.none
        LayoutController.isCornersLayout = false
    }
    
    func updateWithLayout(layout: Layout) {
        flipPicImage?.layout = layout
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
            frontImageWidth = flipPicImageView.bounds.width
            frontImageHeight = flipPicImageView.bounds.height / 2
            backImageX = 0.0
            backImageY = flipPicImageView.bounds.maxY / 2
            backImageWidth = flipPicImageView.bounds.width
            backImageHeight = flipPicImageView.bounds.height / 2
            
        case .leftRight:
            frontImageX = 0.0
            frontImageY = 0.0
            frontImageWidth = flipPicImageView.bounds.width / 2
            frontImageHeight = flipPicImageView.bounds.height
            backImageX = flipPicImageView.bounds.maxX / 2
            backImageY = 0.0
            backImageWidth = flipPicImageView.bounds.width / 2
            backImageHeight = flipPicImageView.bounds.height
            
        case .pictureInPicture:
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
            frontImageSubLayout = SubLayout.littlePicture
            
        case .upperLeftLowerRight:
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
            frontImageSubLayout = SubLayout.topLeft
            backImageSubLayout = SubLayout.bottomRight
            
        case .upperRightLowerLeft:
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
        frontImageZoomableView.updateBorderForLayout(layout: frontImageSubLayout)
        backImageZoomableView.updateBorderForLayout(layout: backImageSubLayout)
        updateScrollViews()
    }
}

// MARK: - UIScrollViewDelegate

extension EditViewController: UIScrollViewDelegate {
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        if scrollView == frontImageScrollView {
            return frontImageView
        } else {
            return backImageView
        }
    }
}

// MARK: - PanGestureViewProtocol

extension EditViewController: PanGestureViewProtocol {
    @objc func detectLongPress(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state.rawValue == 1, flipPicImage?.layout == Layout.pictureInPicture {
            frontImageZoomableView.toggleIsMoveable()
            frontImageZoomableView.setLastLocation()
            frontImageZoomableView.lastPointLocation = recognizer.location(in: flipPicImageView)
            print("Long press ended")
            
        } else if recognizer.state.rawValue == 2, flipPicImage?.layout == Layout.pictureInPicture {
            if frontImageZoomableView.isMoveableView != nil {
                let pointCenter = recognizer.location(in: flipPicImageView)
                let center = frontImageZoomableView.getPoint(touchPoint: pointCenter)
                panDetected(center: center)
            }
        }
    }
    
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
