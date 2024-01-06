import UIKit

// MARK: - OptionType

enum OptionType: Int {
    case none = 0
    case filters
    case layout
}

// MARK: - Layout

enum Layout: Int {
    case pictureInPicture = 0
    case leftRight
    case topBottom
    case upperLeftLowerRight
    case upperRightLowerLeft
    case count
}

let layoutIcons = [UIImage(systemName: "square.split.bottomrightquarter")?.withRenderingMode(.alwaysTemplate),
                   UIImage(systemName: "square.split.2x1")?.withRenderingMode(.alwaysTemplate),
                   UIImage(systemName: "square.split.1x2")?.withRenderingMode(.alwaysTemplate),
                   UIImage(systemName: "square.split.diagonal")?.withRenderingMode(.alwaysTemplate),
                   UIImage(systemName: "square.split.diagonal.fill")?.withRenderingMode(.alwaysTemplate)]

// MARK: - SubLayout

enum SubLayout: Int {
    case none = 0
    case top
    case bottom
    case left
    case right
    case topRight
    case bottomRight
    case topLeft
    case bottomLeft
    case bigPicture
    case littlePicture
}

// MARK: - MaskLayout

enum MaskLayout: Int {
    case none = 0
    case topRight
    case bottomLeft
    case topLeft
    case bottomRight
}

// MARK: - Filter

enum Filter: Int {
    case none = 0
    case fade
    case chrome
    case poster
    case comic
    case tonal
    case noir
    case count
    
    // MARK: Internal
    
    var string: String {
        switch self {
        case .none:
            return "None"
        case .fade:
            return "Fade"
        case .chrome:
            return "Chrome"
        case .poster:
            return "Poster"
        case .comic:
            return "Comic"
        case .tonal:
            return "Tonal"
        case .noir:
            return "Noir"
        case .count:
            return "Count"
        }
    }
    
    var filterName: String {
        switch self {
        case .none:
            return "None"
        case .fade:
            return "CIPhotoEffectFade"
        case .chrome:
            return "CIPhotoEffectChrome"
        case .poster:
            return "CIColorPosterize"
        case .comic:
            return "CIComicEffect"
        case .tonal:
            return "CIPhotoEffectTonal"
        case .noir:
            return "CIPhotoEffectNoir"
        case .count:
            return "Count"
        }
    }
}
