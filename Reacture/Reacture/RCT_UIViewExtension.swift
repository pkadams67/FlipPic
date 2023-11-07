import UIKit

extension UIView {

	private var littleLineWidthPercentage: CGFloat { 0.5 }

	func leftBorder(littleImage: Bool = false) -> CALayer {

		var lineWidth = RCT_EditViewController.lineWidth
		if littleImage { lineWidth *= littleLineWidthPercentage }
		let layer = CALayer()
		layer.backgroundColor = UIColor.white.cgColor
		layer.frame = CGRect(x: 0.0, y: 0.0, width: lineWidth, height: frame.height)

		return layer
	}

	func rightBorder(littleImage: Bool = false) -> CALayer {

		var lineWidth = RCT_EditViewController.lineWidth
		if littleImage { lineWidth *= littleLineWidthPercentage }
		let layer = CALayer()
		layer.backgroundColor = UIColor.white.cgColor
		layer.frame = CGRect(x: bounds.maxX - lineWidth, y: 0.0, width: lineWidth, height: bounds.height)

		return layer
	}

	func topBorder(littleImage: Bool = false) -> CALayer {

		var lineWidth = RCT_EditViewController.lineWidth
		if littleImage { lineWidth *= littleLineWidthPercentage }
		let layer = CALayer()
		layer.backgroundColor = UIColor.white.cgColor
		layer.frame = CGRect(x: 0.0, y: 0.0, width: frame.width, height: lineWidth)

		return layer
	}

	func bottomBorder(littleImage: Bool = false) -> CALayer {

		var lineWidth = RCT_EditViewController.lineWidth
		if littleImage { lineWidth *= littleLineWidthPercentage }
		let layer = CALayer()
		layer.backgroundColor = UIColor.white.cgColor
		layer.frame = CGRect(x: 0.0, y: bounds.maxY - lineWidth, width: bounds.width, height: lineWidth)

		return layer
	}

	private var topLeftToBottomRightBorder: CAShapeLayer {

		let layer = CAShapeLayer()
		let path = UIBezierPath()
		path.move(to: CGPoint(x: 0.0, y: 0.0))
		path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.maxY))
		layer.path = path.cgPath
		layer.strokeColor = UIColor.white.cgColor
		layer.lineWidth = RCT_EditViewController.lineWidth
		layer.fillColor = UIColor.clear.cgColor

		return layer
	}

	private var topRightToBottomLeftBorder: CAShapeLayer {

		let layer = CAShapeLayer()
		let path = UIBezierPath()
		path.move(to: CGPoint(x: bounds.maxX, y: 0.0))
		path.addLine(to: CGPoint(x: 0.0, y: bounds.maxY))
		layer.path = path.cgPath
		layer.strokeColor = UIColor.white.cgColor
		layer.lineWidth = RCT_EditViewController.lineWidth
		layer.fillColor = UIColor.clear.cgColor

		return layer
	}

	func removeBorders() {
		print("Before: \(layer.sublayers?.count)")

		if (layer.sublayers?.count ?? 0) > 1 {
			var index = 0
			layer.sublayers?.forEach { layer in
				if index != 0 {
					layer.removeFromSuperlayer()
				}
				index += 1
			}
		}

		print("After: \(layer.sublayers?.count)")
	}

	func updateBorderForLayout(layout: SubLayout) {

		print(layer.sublayers?.count)

		switch layout {

			case .bottom:
				layer.addSublayer(leftBorder())
				layer.addSublayer(rightBorder())
				layer.addSublayer(bottomBorder())

			case .top:
				layer.addSublayer(leftBorder())
				layer.addSublayer(rightBorder())
				layer.addSublayer(topBorder())

			case .left:
				layer.addSublayer(leftBorder())
				layer.addSublayer(topBorder())
				layer.addSublayer(bottomBorder())

			case .right:
				layer.addSublayer(rightBorder())
				layer.addSublayer(topBorder())
				layer.addSublayer(bottomBorder())

			case .topRight:
				layer.addSublayer(topLeftToBottomRightBorder)

			case .bottomRight:
				layer.addSublayer(topRightToBottomLeftBorder)

			case .topLeft:
				layer.addSublayer(topRightToBottomLeftBorder)

			case .bottomLeft:
				layer.addSublayer(topLeftToBottomRightBorder)

			case .bigPicture:
				layer.addSublayer(leftBorder())
				layer.addSublayer(topBorder())
				layer.addSublayer(bottomBorder())
				layer.addSublayer(rightBorder())

			case .littlePicture:
				layer.addSublayer(leftBorder(littleImage: true))
				layer.addSublayer(topBorder(littleImage: true))
				layer.addSublayer(bottomBorder(littleImage: true))
				layer.addSublayer(rightBorder(littleImage: true))
			case .none:
				break
		}
	}
}
