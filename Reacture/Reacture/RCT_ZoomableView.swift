import SpriteKit
import UIKit

class ZoomableView: UIView {

	// MARK: Internal

	var scrollView: UIScrollView!

	var maskLayout = MaskLayout.none {
		didSet {
			setNeedsLayout()
		}
	}

	//////////////////////////////

	// MARK: Functions

	//////////////////////////////

	override func layoutSubviews() {
		super.layoutSubviews()
		updateShape()
	}

	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		// Specify if a touch should be considered valid
		// Not valid if in the mask area.
		if RCT_LayoutController.isCornersLayout {
			if let path = shapeLayer.path {
				let convertedPoint = layer.convert(point, to: shapeLayer)
				return path.contains(convertedPoint)
			}
		}
		return super.point(inside: point, with: event)
	}

	// MARK: Private

	//////////////////////////////

	// MARK: Variables

	//////////////////////////////

	private var shapeLayer = CAShapeLayer()

	private func updateShape() {

		layer.mask = nil

		if let pathLayout = pathForLayout(maskLayout: maskLayout) {
			let path = pathLayout.cgPath
			shapeLayer.frame = frame
			shapeLayer.path = path
			layer.mask = shapeLayer
		}
	}

	private func pathForLayout(maskLayout: MaskLayout) -> UIBezierPath? {

		var path: UIBezierPath! = UIBezierPath()

		let layerHeight = bounds.height
		let layerWidth = bounds.width

		let topRightPoint = CGPoint(x: layerWidth, y: 0)
		let topLeftPoint = CGPoint(x: 0, y: 0)
		let bottomRightPoint = CGPoint(x: layerWidth, y: layerHeight)
		let bottomLeftPoint = CGPoint(x: 0, y: layerHeight)

		print("test: Layout: \(maskLayout) selected")

		switch maskLayout {

			case .none:
				path = nil

			case .topRight:
				path.move(to: bottomRightPoint)
				path.addLine(to: topRightPoint)
				path.addLine(to: topLeftPoint)
				path.addLine(to: bottomRightPoint)

			case .bottomLeft:
				path.move(to: bottomRightPoint)
				path.addLine(to: bottomLeftPoint)
				path.addLine(to: topLeftPoint)
				path.addLine(to: bottomRightPoint)

			case .topLeft:
				path.move(to: bottomLeftPoint)
				path.addLine(to: topLeftPoint)
				path.addLine(to: topRightPoint)
				path.addLine(to: bottomLeftPoint)

			case .bottomRight:
				path.move(to: bottomLeftPoint)
				path.addLine(to: bottomRightPoint)
				path.addLine(to: topRightPoint)
				path.addLine(to: bottomLeftPoint)
		}

		return path
	}
}
