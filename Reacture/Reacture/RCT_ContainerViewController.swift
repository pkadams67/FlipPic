import UIKit

// MARK: - RCT_ContainerViewControllerProtocol

protocol RCT_ContainerViewControllerProtocol {
	func itemSelected(indexPath: IndexPath, optionSelected: OptionType)
}

// MARK: - RCT_ContainerViewController

class RCT_ContainerViewController: UIViewController {

	var optionSelected = OptionType(rawValue: 0)!
	var selectedFrameZero: CGRect?
	var layoutSelected = 0
	var filterSelected = 0
	let borderWidth: CGFloat = 2.0

	@IBOutlet var collectionView: UICollectionView!

	// Filter Button Images
	var arrayOfFilterButtonImageViews: [UIImageView] = []
	var delegate: RCT_ContainerViewControllerProtocol?

	override func viewDidLoad() {
		setupCollectionView()
	}

	func loadFilterButtonImages(arrayOfImageViews: [UIImageView]) {
		print("Handling Filter Button Images")
		arrayOfFilterButtonImageViews = arrayOfImageViews
		collectionView.reloadData()
		print("Reloading Collection View")
	}

	func reloadCollection() {
		print("Collection View Reloaded")

		collectionView.reloadData()

		switch optionSelected {
			case .layout:
				collectionView.selectItem(at: IndexPath(item: layoutSelected, section: 0), animated: false, scrollPosition: .centeredHorizontally)

			case .filters:
				collectionView.selectItem(at: IndexPath(item: filterSelected, section: 0), animated: false, scrollPosition: .centeredHorizontally)

			case .none:
				break
		}
	}

	func setupCollectionView() {
		collectionView.backgroundColor = UIColor.flipPicGray().withAlphaComponent(1)

		switch optionSelected {
			case .layout:
				print("Layout is Selected, Present Layout Options")
			case .filters:
				print("Filter is Selected, Present Filter Options")
			case .none:
				print("None is selected. Hide stuff.")
		}
	}
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource

extension RCT_ContainerViewController: UICollectionViewDelegate, UICollectionViewDataSource {

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OptionItemCell", for: indexPath) as! RCT_OptionItemCollectionViewCell

		switch optionSelected {
			case .layout:

				cell.imageView.backgroundColor = UIColor.white
				if indexPath.item == layoutSelected {
					cell.imageView.layer.borderWidth = borderWidth
					cell.imageView.layer.borderColor = UIColor.flipPicGreen().cgColor
					cell.imageView.backgroundColor = UIColor.flipPicGreen()

				} else {
					cell.imageView.layer.borderWidth = 0
					cell.imageView.layer.borderColor = UIColor.flipPicGreen().cgColor
				}
				cell.label.isHidden = true
				cell.imageView.image = layoutIcons[indexPath.item]

			case .filters:

				cell.backgroundColor = UIColor.clear
				cell.label.textColor = UIColor.white
				cell.label.isHidden = false

				if indexPath.item == filterSelected {
					cell.imageView.layer.borderWidth = borderWidth
					cell.imageView.layer.borderColor = UIColor.flipPicGreen().cgColor
					cell.label.textColor = UIColor.flipPicGreen()
				} else {
					cell.imageView.layer.borderWidth = 0
					cell.imageView.layer.borderColor = UIColor.flipPicGreen().cgColor
				}
				let labelText = Filter(rawValue: indexPath.item)?.string
				cell.label.text = labelText
				// Setting Images for Filter Buttons
				if arrayOfFilterButtonImageViews.count == Filter.count.rawValue {
					let imageView = arrayOfFilterButtonImageViews[indexPath.item]
					let image = imageView.image
					cell.imageView.image = image
					cell.imageView.contentMode = .scaleAspectFill
				}

			case .none:
				break
		}
		return cell
	}

	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		switch optionSelected {
			case .layout:
				return Layout.count.rawValue
			case .filters:
				return Filter.count.rawValue
			case .none:
				return 0
		}
	}

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

		let cell = collectionView.cellForItem(at: indexPath) as! RCT_OptionItemCollectionViewCell

		cell.imageView.layer.borderWidth = borderWidth
		cell.imageView.layer.borderColor = UIColor.flipPicGreen().cgColor

		switch optionSelected {

			case .layout:
				layoutSelected = indexPath.item
				cell.imageView.backgroundColor = UIColor.flipPicGreen()

			case .filters:
				filterSelected = indexPath.item
				cell.label.textColor = UIColor.flipPicGreen()

			case .none:
				break
		}
		delegate?.itemSelected(indexPath: indexPath, optionSelected: optionSelected)
	}

	func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
		if let cell = collectionView.cellForItem(at: indexPath) as? RCT_OptionItemCollectionViewCell {

			switch optionSelected {

				case .layout:
					cell.imageView.layer.borderWidth = 0
					cell.imageView.layer.borderColor = UIColor.flipPicGreen().cgColor
					cell.imageView.backgroundColor = UIColor.white
					layoutSelected = indexPath.item

				case .filters:
					cell.imageView.layer.borderWidth = 0
					cell.imageView.layer.borderColor = UIColor.flipPicGreen().cgColor
					cell.label.textColor = UIColor.white
					filterSelected = indexPath.item

				case .none:
					break
			}
		}
	}
}
