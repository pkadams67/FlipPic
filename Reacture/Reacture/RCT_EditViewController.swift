import CoreImage
import UIKit

// MARK: - RCT_EditViewController

class RCT_EditViewController: UIViewController {

	static let lineWidth: CGFloat = 5.0

	//////////////////////////////

	// MARK: Variables

	//////////////////////////////

	// MARK: Swap Button:

	var swapImageButton = UIButton()
	var imagesAreSwapped = false
	var imageToSend: UIImage?
	var rCTImage: RCT_Image?
	var containerViewController: RCT_ContainerViewController?
	var frontImageView = UIImageView()
	var backImageView = UIImageView()

	// View Variables
	var frontImageZoomableView = PanGestureView()
	var frontImageScrollView = UIScrollView()
	var backImageZoomableView = ZoomableView()
	var backImageScrollView = UIScrollView()

	// Adjusting layout view variables
	var adjustLayoutView = UIView()
	var adjustLayoutVisibleView = UIView()
	var adjustLayoutViewLastPosition = CGPoint()
	var frontImageLastFrame = CGRect()
	var backImageLastFrame = CGRect()

	// MARK: Filter Variables

	let context = CIContext()
	var originalFrontImage: UIImage?
	var originalBackImage: UIImage?
	var arrayOfFilterButtonImageViews: [UIImageView] = []

	//////////////////////////////

	// MARK: Outlets

	//////////////////////////////

	@IBOutlet var toolbar: UIToolbar!
	@IBOutlet var toolbarLayoutOption: UIBarButtonItem!
	@IBOutlet var toolbarFilterOption: UIBarButtonItem!
	@IBOutlet var containerView: UIView!
	@IBOutlet var layoutButton: UIBarButtonItem!
	@IBOutlet var filterButton: UIBarButtonItem!
	@IBOutlet var RCT_ImageViewBackgroundView: UIView!
	@IBOutlet var rCTImageView: UIView!
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
//		RCT_ImageViewBackgroundView.backgroundColor = UIColor.flipPicGray()
//		view.backgroundColor = UIColor.flipPicGray()
//		containerView.backgroundColor = UIColor.flipPicGray()
//		toolbar.backgroundColor = UIColor.flipPicGray()
		toolbarLayoutOption.tintColor = UIColor.white
		toolbarFilterOption.tintColor = UIColor.white
		toolbar.clipsToBounds = true
		containerViewController = children.first! as? RCT_ContainerViewController
		containerViewController?.delegate = self
//		containerViewController!.view.backgroundColor = UIColor.flipPicGray()
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

		// setup layout of editViewController
		//        RCT_ImageViewBackgroundView.center = CGPoint(x: RCT_ImageViewBackgroundView.center.x, y: RCT_ImageViewBackgroundView.center.y +  containerView.bounds.size.height/2)
		//        RCT_ImageViewBackgroundView.backgroundColor = UIColor.green
	}

	func setMockData() {
		//        let frontImage = UIImage(named: "mock_selfie")
		//        let backImage = UIImage(named: "mock_landscape")
		//        let frontImageData = RCT_ImageController.imageToData(frontImage!)!
		//        let backImageData = RCT_ImageController.imageToData(backImage!)!
		//        let image1 = RCT_ImageController.dataToImage(frontImageData)!
		//        let image2 = RCT_ImageController.dataToImage(backImageData)!
		//        rCTImageView.backgroundColor = UIColor(patternImage: image)
		//        setUpImages(image1, back: image2)
	}

	// End Filter Variables

	//////////////////////////////

	// MARK: Functions

	//////////////////////////////

	func setupAdjustLayoutView() {
		adjustLayoutView.frame = rCTImageView!.frame
		adjustLayoutView.backgroundColor = UIColor.clear
		adjustLayoutVisibleView.backgroundColor = UIColor.white
		adjustLayoutView.addSubview(adjustLayoutVisibleView)
		rCTImageView.addSubview(adjustLayoutView)
		adjustLayoutView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(adjustLayoutView(recognizer:))))
		updateLayoutViewForLayout()
	}

	func updateLayoutViewForLayout() {
		adjustLayoutView.isHidden = false
		let invisibleLineWidth: CGFloat = 25.0

		switch rCTImage!.layout {

			case .topBottom:
				adjustLayoutView.frame = CGRect(x: 0.0, y: 0.0, width: rCTImageView.frame.width, height: invisibleLineWidth)
				adjustLayoutView.center = CGPoint(x: rCTImageView.bounds.maxX / 2, y: rCTImageView.bounds.maxY / 2)
				adjustLayoutVisibleView.frame = CGRect(x: 0.0, y: 0.0, width: rCTImageView.bounds.width, height: RCT_EditViewController.lineWidth)
				adjustLayoutVisibleView.center = CGPoint(x: adjustLayoutView.bounds.maxX / 2, y: adjustLayoutView.bounds.maxY / 2)

			case .leftRight:
				adjustLayoutView.frame = CGRect(x: 0.0, y: 0.0, width: invisibleLineWidth, height: rCTImageView.frame.height)
				adjustLayoutView.center = CGPoint(x: rCTImageView.bounds.maxX / 2, y: rCTImageView.bounds.maxY / 2)
				adjustLayoutVisibleView.frame = CGRect(x: 0.0, y: 0.0, width: RCT_EditViewController.lineWidth, height: rCTImageView.bounds.height)
				adjustLayoutVisibleView.center = CGPoint(x: adjustLayoutView.bounds.maxX / 2, y: adjustLayoutView.bounds.maxY / 2)

			default:
				adjustLayoutView.isHidden = true
		}

		rCTImageView.bringSubviewToFront(adjustLayoutView)
	}

	@objc func adjustLayoutView(recognizer: UIPanGestureRecognizer) {

		if recognizer.state == .began {
			adjustLayoutViewLastPosition = adjustLayoutView.center
			frontImageLastFrame = frontImageZoomableView.frame
			backImageLastFrame = backImageZoomableView.frame
		}
		let translation = recognizer.translation(in: rCTImageView)
		switch rCTImage!.layout {

			case .topBottom:
				var layoutViewY: CGFloat = adjustLayoutViewLastPosition.y + translation.y
				let adjustmentBuffer = rCTImageView.frame.height / 4 // each image must be at least 1/4 of the rCTImageView
				let uppermostBound: CGFloat = (rCTImageView.bounds.minY + adjustmentBuffer)
				let lowermostBound: CGFloat = (rCTImageView.bounds.maxY - adjustmentBuffer)
				var frontImageHeight: CGFloat = frontImageLastFrame.height + translation.y
				var backImageHeight: CGFloat = backImageLastFrame.height - translation.y
				var backImageY: CGFloat = backImageLastFrame.origin.y + translation.y

				// Check for invalid Y position
				if layoutViewY > lowermostBound {

					layoutViewY = lowermostBound

					let yPositionPercentage = (lowermostBound / rCTImageView.bounds.maxY)
					frontImageHeight = rCTImageView.bounds.height * yPositionPercentage
					backImageHeight = rCTImageView.bounds.height - (rCTImageView.bounds.height * yPositionPercentage) // width times percentage of where the x point is.
					backImageY = lowermostBound
					print("rCTImageView.bounds.height: \(rCTImageView.bounds.height); yPositionPercentage: \(yPositionPercentage)")

				} else if layoutViewY < uppermostBound {

					layoutViewY = uppermostBound

					let yPositionPercentage = (uppermostBound / rCTImageView.bounds.maxY)
					frontImageHeight = rCTImageView.bounds.height * yPositionPercentage
					backImageHeight = rCTImageView.bounds.height - (rCTImageView.bounds.height * yPositionPercentage) // width times percentage of where the x point is.
					backImageY = uppermostBound
				}

				adjustLayoutView.center = CGPoint(x: rCTImageView.bounds.maxX / 2, y: layoutViewY)
				frontImageZoomableView.frame.size.height = frontImageHeight
				backImageZoomableView.frame.size.height = backImageHeight
				backImageZoomableView.frame.origin.y = backImageY

			case .leftRight:
				var layoutViewX: CGFloat = adjustLayoutViewLastPosition.x + translation.x
				let adjustmentBuffer = rCTImageView.frame.width / 4 // each image must be at least 1/4 of the rCTImageView
				let rightmostBound: CGFloat = (rCTImageView.bounds.maxX - adjustmentBuffer)
				let leftmostBound: CGFloat = (rCTImageView.bounds.minX + adjustmentBuffer)
				var frontImageWidth = frontImageLastFrame.width + translation.x
				var backImageWidth = backImageLastFrame.width - translation.x
				var backImageX = backImageLastFrame.origin.x + translation.x

				// Check for invalid X position
				if layoutViewX > rightmostBound {

					layoutViewX = rightmostBound

					let xPositionPercentage = (rightmostBound / rCTImageView.bounds.maxX)
					frontImageWidth = rCTImageView.bounds.width * xPositionPercentage
					backImageWidth = rCTImageView.bounds.width - (rCTImageView.bounds.width * xPositionPercentage) // width times percentage of where the x point is.
					backImageX = rightmostBound

				} else if layoutViewX < leftmostBound {

					layoutViewX = leftmostBound

					let xPositionPercentage = (leftmostBound / rCTImageView.bounds.maxX)
					frontImageWidth = rCTImageView.bounds.width * xPositionPercentage
					backImageWidth = rCTImageView.bounds.width - (rCTImageView.bounds.width * xPositionPercentage) // width times percentage of where the x point is.
					backImageX = leftmostBound
				}
				adjustLayoutView.center = CGPoint(x: layoutViewX, y: rCTImageView.bounds.maxY / 2)
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

		// Offset it By the Difference of Size Divided by Two. This Makes the Center of the Image at the Center of the scrollView
		let frontY = (frontImageScrollView.contentSize.height - frontImageScrollView.bounds.height) / 2
		let backY = (backImageScrollView.contentSize.height - backImageScrollView.bounds.height) / 2
		print("\(frontImageScrollView.contentSize.height) \(backImageScrollView.contentSize.height)")
		frontImageScrollView.setContentOffset(CGPoint(x: 0, y: frontY), animated: animated)
		backImageScrollView.setContentOffset(CGPoint(x: 0, y: backY), animated: animated)
	}

	// TODO: - Change Frame to Bounds?

	func updateScrollViews() {

		print("rctImageView width: \(rCTImageView.bounds.width), rctImageView height: \(rCTImageView.bounds.height)")

		let frontImageZoomScaleWidth = frontImageZoomableView.bounds.width / (frontImageView.image?.size.width)!
		let frontImageZoomScaleHeight = frontImageZoomableView.bounds.height / (frontImageView.image?.size.height)!
		let frontImageMinZoomScale: CGFloat

		print("frontWidth: \(frontImageZoomableView.bounds.width) / \(frontImageView.image?.size.width) = \(frontImageZoomScaleWidth), frontHeight: \(frontImageZoomableView.bounds.height) / \(frontImageView.image?.size.height) = \(frontImageZoomScaleHeight)")

		frontImageZoomScaleWidth > frontImageZoomScaleHeight ? (frontImageMinZoomScale = frontImageZoomScaleWidth) : (frontImageMinZoomScale = frontImageZoomScaleHeight)

		frontImageScrollView.minimumZoomScale = frontImageMinZoomScale
		frontImageScrollView.maximumZoomScale = 5.0

		if frontImageScrollView.zoomScale < frontImageMinZoomScale || rCTImage?.layout == Layout.pictureInPicture {
			frontImageScrollView.zoomScale = frontImageMinZoomScale
		}

		let backImageZoomScaleWidth = backImageZoomableView.bounds.width / (backImageView.image?.size.width)!
		let backImageZoomScaleHeight = backImageZoomableView.bounds.height / (backImageView.image?.size.height)!
		let backImageMinZoomScale: CGFloat

		print("backWidth: \(backImageZoomableView.bounds.width) / \(backImageView.image?.size.width ?? 0.0) = \(backImageZoomScaleWidth), backHeight: \(backImageZoomableView.bounds.height) / \(backImageView.image?.size.height ?? 0.0) = \(backImageZoomScaleHeight)")

		backImageZoomScaleWidth > backImageZoomScaleHeight ? (backImageMinZoomScale = backImageZoomScaleWidth) : (backImageMinZoomScale = backImageZoomScaleHeight)

		backImageScrollView.minimumZoomScale = backImageMinZoomScale
		backImageScrollView.maximumZoomScale = 5.0

		if backImageScrollView.zoomScale < backImageMinZoomScale || rCTImage?.layout == Layout.pictureInPicture {
			backImageScrollView.zoomScale = backImageMinZoomScale
		}
	}

	func setupController(rCTImage: RCT_Image) {
		self.rCTImage = rCTImage

		_ = view
		_ = rCTImageView
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
		frontImageScrollView = UIScrollView(frame: frontImageZoomableView.bounds)
		frontImageScrollView.delegate = self
		frontImageScrollView.backgroundColor = UIColor.flipPicGray()
		backImageScrollView = UIScrollView(frame: backImageZoomableView.bounds)
		backImageScrollView.delegate = self
		backImageScrollView.backgroundColor = UIColor.flipPicGray()

		frontImageZoomableView.addSubview(frontImageScrollView)
		frontImageZoomableView.scrollView = frontImageScrollView
		backImageZoomableView.addSubview(backImageScrollView)
		backImageZoomableView.scrollView = frontImageScrollView

		// Setup Image Views
		frontImageView = UIImageView(image: rCTImage.imageFrontUIImage)
		backImageView = UIImageView(image: rCTImage.imageBackUIImage)

		frontImageScrollView.addSubview(frontImageView)
		backImageScrollView.addSubview(backImageView)

		setupScrollViews()
		setupAdjustLayoutView()

		rCTImageView.updateBorderForLayout(layout: .bigPicture)
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
		UIGraphicsBeginImageContextWithOptions(rCTImageView.frame.size, view.isOpaque, 0.0)
		rCTImageView.layer.render(in: UIGraphicsGetCurrentContext()!)
		imageToSend = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
	}

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

	//////////////////////////////

	// MARK: Actions

	//////////////////////////////

	// TODO: camelCase CancelButtonTapped

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
		let shareTextRCTImage = "Shared with @FlipPic1 “Your Front/Back Camera App”"
		if let image = imageToSend {
			print("Sending Image")
			let shareViewController = UIActivityViewController(activityItems: [image, shareTextRCTImage], applicationActivities: nil)
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
		let currentOptionSelected = containerViewController!.optionSelected

		switch option {
			case .layout:
				switch currentOptionSelected {
					case .layout:
						// They are DESELECTING Layout

						// move RCT_ImageViewBackgroundView down half of the containerViews height
						//                RCT_ImageViewBackgroundView.center = CGPoint(x: RCT_ImageViewBackgroundView.center.x, y: RCT_ImageViewBackgroundView.center.y +  containerView.bounds.size.height/2)
						// hide containerView.
						animateContainerView(hide: true)
						// unselect Layout button (change image)
						toolbarLayoutOption.tintColor = UIColor.white
						// set optionToApply to be .None
						optionToApply = .none

					case .filters:
						// They are SELECTING Layout from Filters

						// unselect Filter button (change image)
						toolbarFilterOption.tintColor = UIColor.white
						// select Layout button (change image)
						toolbarLayoutOption.tintColor = UIColor.flipPicGreen()

					case .none:
						// They are SELECTING Layout from Being Hidden

						// unhide containerView
						animateContainerView(hide: false)
						// select Layout button (change image)
						toolbarLayoutOption.tintColor = UIColor.flipPicGreen()
				}

			case .filters:

				switch currentOptionSelected {
					case .layout:
						// They are SELECTING Filters from Layout

						// unselect Layout button (change image)
						toolbarLayoutOption.tintColor = UIColor.white
						// select Filters button (change image)
						toolbarFilterOption.tintColor = UIColor.flipPicGreen()

					case .filters:
						// They are DESELECTING Filters

						// hide containerView
						animateContainerView(hide: true)
						// unselect Filters button (change image)
						toolbarFilterOption.tintColor = UIColor.white
						// set optionToApply to be .None
						optionToApply = .none

					case .none:
						// They are SELECTING Filters from Being Hidden

						// unhide containerView
						animateContainerView(hide: false)
						// select Filters button (change image)
						toolbarFilterOption.tintColor = UIColor.flipPicGreen()
				}

			case .none:

				// hide containerView
				animateContainerView(hide: true)

				switch currentOptionSelected {
					case .filters:

						// unselect Filters button (change image)
						toolbarFilterOption.tintColor = UIColor.white

					case .layout:

						// unselect Layouts button (change image)
						toolbarLayoutOption.tintColor = UIColor.white

					case .none:
						break
				}

				// set optionToApply to be .None
				optionToApply = .none
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

	func animateContainerView(hide: Bool, additionalCode: (() -> Void) = {}) {
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

// MARK: - RCT_ContainerViewControllerProtocol

extension RCT_EditViewController: RCT_ContainerViewControllerProtocol {

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

extension RCT_EditViewController {

	func updateWithFilter(filter: Filter) {
		frontImageZoomableView.removeIsMovableView()

		_ = "CIPhotoEffectMono"
		let tonalFilterName = "CIPhotoEffectTonal"
		let noirFilterName = "CIPhotoEffectNoir"
		let fadeFilterName = "CIPhotoEffectFade"
		let chromeFilterName = "CIPhotoEffectChrome"
		let comicFilterName = "CIComicEffect"
		let posterFilterName = "CIColorPosterize"

		if rCTImage != nil {

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
		let tonalFilterName = "CIPhotoEffectTonal"
		let noirFilterName = "CIPhotoEffectNoir"
		let fadeFilterName = "CIPhotoEffectFade"
		let chromeFilterName = "CIPhotoEffectChrome"
		let comicFilterName = "CIComicEffect"
		let posterFilterName = "CIColorPosterize"

		if rCTImage != nil {

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
		var scale: CGFloat?
		var thumbnailScale: CGFloat?
		var orientation: UIImage.Orientation?
		var beginFrontImage: CIImage?

		let thumbnailFrame = CGRect(x: 0, y: 0, width: 100, height: 100)

		if let frontImage = originalFrontImage {
			scale = frontImage.scale
			orientation = frontImage.imageOrientation
			let height = frontImage.size.height
			_ = frontImage.size.width
			thumbnailScale = thumbnailFrame.height / height // May Need Aspect Adjustment to Make Square Thumbnail
			// Getting CI Image
			beginFrontImage = CIImage(image: frontImage)
		}

        var options: [String: AnyObject]? = [:]
		if filterName == "None" {
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

	func performFilter(filterName: String) {
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

		var options: [String: AnyObject]?
		if filterName == "CISepiaTone" {
			options = ["inputIntensity": 0.8 as AnyObject]
		}

		// Getting Output Using Filter Name Parameter and Options

		// Front Image:
		if let outputImage = beginFrontImage?.applyingFilter(filterName, parameters: options!) {
			print("We Have a Front Output Image")
			let cGImage: CGImage = context.createCGImage(outputImage, from: outputImage.extent)!
			rCTImage?.imageFrontUIImage = UIImage(cgImage: cGImage, scale: scale!, orientation: frontImageOrientation!)
			// Completed UI Images Update on RCT_Image Model
			// Reloading Front Image View
			frontImageView.image = rCTImage!.imageFrontUIImage
		}

		// Back Image:
		if let outputImage = beginBackImage?.applyingFilter(filterName, parameters: options!) {
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

// MARK: Layout Methods

extension RCT_EditViewController {

	func clearMasks() {
		frontImageZoomableView.maskLayout = MaskLayout.none
		backImageZoomableView.maskLayout = MaskLayout.none
		RCT_LayoutController.isCornersLayout = false
	}

	func updateWithLayout(layout: Layout) {
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
}

// MARK: - UIScrollViewDelegate

extension RCT_EditViewController: UIScrollViewDelegate {

	func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
		if scrollView == frontImageScrollView {
			return frontImageView
		} else {
			return backImageView
		}
	}
}

// MARK: - PanGestureViewProtocol

extension RCT_EditViewController: PanGestureViewProtocol {

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

	// Pan Gesture for Moving Image in Image Layout
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
