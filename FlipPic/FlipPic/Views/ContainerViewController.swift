import UIKit

// MARK: - ContainerViewControllerProtocol

protocol ContainerViewControllerProtocol {
    func didSelectItem(at indexPath: IndexPath, with option: OptionType)
}

// MARK: - ContainerViewController

class ContainerViewController: UIViewController {
    enum State {
        case layout(selectedIndex: Int)
        case filter(selectedIndex: Int)
        case none
    }
    
    var state: State = .none
    let borderWidth: CGFloat = 2.0
    
    @IBOutlet var collectionView: UICollectionView!
    
    var layoutButtonImages: [UIImage] = []
    var filterButtonImages: [UIImage] = []
    var delegate: ContainerViewControllerProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        layoutButtonImages = layoutIcons.compactMap { $0 }
    }
    
    func updateFilterButtonImages(_ images: [UIImage]) {
        filterButtonImages = images
        if case .filter = state {
            collectionView.reloadSections(IndexSet(integer: 0))
        }
    }
    
    func reloadCollection() {
        collectionView.reloadData()
    }
    
    private func setupCollectionView() {
        collectionView.backgroundColor = .darkGray
        collectionView.delegate = self
        collectionView.dataSource = self
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource

extension ContainerViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OptionItemCell", for: indexPath) as! OptionItemCollectionViewCell
        configure(cell: cell, at: indexPath)
        return cell
    }
    
    private func configure(cell: OptionItemCollectionViewCell, at indexPath: IndexPath) {
        switch state {
        case .layout(let selectedIndex):
            let image = layoutButtonImages[indexPath.item]
            configureLayoutCell(cell, isSelected: indexPath.item == selectedIndex, image: image)
            
        case .filter(let selectedIndex):
            let image = filterButtonImages[indexPath.item]
            configureFilterCell(cell, isSelected: indexPath.item == selectedIndex, image: image, at: indexPath)
            
        case .none:
            cell.resetToDefault()
        }
    }
    
    private func configureLayoutCell(_ cell: OptionItemCollectionViewCell, isSelected: Bool, image: UIImage) {
        cell.imageView.image = image
        cell.imageView.tintColor = isSelected ? UIColor.green : UIColor.gray
        cell.imageView.backgroundColor = .clear
        cell.imageView.layer.borderWidth = 0
        // cell.imageView.layer.borderColor = UIColor.green.cgColor
        cell.label.isHidden = true
    }
    
    private func configureFilterCell(_ cell: OptionItemCollectionViewCell, isSelected: Bool, image: UIImage, at indexPath: IndexPath) {
        cell.imageView.image = image
        cell.imageView.contentMode = .scaleAspectFill
        cell.imageView.layer.borderWidth = isSelected ? borderWidth : 0
        cell.imageView.layer.borderColor = UIColor.green.cgColor

        let labelText = Filter(rawValue: indexPath.item)?.string ?? "Unknown"
        cell.label.text = labelText
        cell.label.isHidden = false
        cell.label.textColor = isSelected ? .green : .white
        // Set filter-specific properties here
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch state {
        case .layout:
            return layoutButtonImages.count
        case .filter:
            return filterButtonImages.count
        case .none:
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch state {
        case .layout:
            state = .layout(selectedIndex: indexPath.item)
        case .filter:
            state = .filter(selectedIndex: indexPath.item)
        case .none:
            break
        }
        collectionView.reloadData()
        delegate?.didSelectItem(at: indexPath, with: state.optionType)
    }
}

// MARK: - State Extension

extension ContainerViewController.State {
    var optionType: OptionType {
        switch self {
        case .layout:
            return .layout
        case .filter:
            return .filters
        case .none:
            return .none
        }
    }
}

// MARK: - OptionItemCollectionViewCell Extension

extension OptionItemCollectionViewCell {
    func resetToDefault() {
        imageView.image = nil
        imageView.layer.borderWidth = 0
        label.isHidden = true
    }
}
