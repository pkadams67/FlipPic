import UIKit

// MARK: - PanGestureViewProtocol

protocol PanGestureViewProtocol {
    func panDetected(center: CGPoint)
}

// MARK: - PanGestureView

class PanGestureView: ZoomableView {
    var lastLocation = CGPoint(x: 0.0, y: 0.0)
    var lastPointLocation = CGPoint(x: 0.0, y: 0.0) // for longPressRecognizer
    var isMoveableView: UIView?
    var delegate: PanGestureViewProtocol?
    
    func toggleIsMoveable() {
        if isMoveableView == nil {
            let view = UIView(frame: bounds)
            let imageView = UIImageView(image: UIImage(systemName: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left"))
            imageView.contentMode = .scaleAspectFill
            imageView.tintColor = .white
            view.addSubview(imageView)
            imageView.frame = CGRect(x: view.bounds.width / 4, y: view.bounds.height / 4, width: view.bounds.width / 2, height: view.bounds.height / 2)
            view.backgroundColor = .white
            view.alpha = 0.2
            view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(detectPan(_:))))
            isMoveableView = view
            addSubview(isMoveableView!)
            
        } else {
            isMoveableView!.removeFromSuperview()
            isMoveableView = nil
        }
    }
    
    func removeIsMovableView() {
        if isMoveableView != nil {
            isMoveableView!.removeFromSuperview()
            isMoveableView = nil
        }
    }
    
    @objc func detectPan(_ recognizer: UIPanGestureRecognizer) {
        print("Pan detected")
        
        let translation = recognizer.translation(in: superview)
        delegate?.panDetected(center: CGPoint(x: lastLocation.x + translation.x, y: lastLocation.y + translation.y))
        print("Pan valid. Center = \(CGPoint(x: lastLocation.x + translation.x, y: lastLocation.y + translation.y))")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("Touches began")
        print("Center: \(center)")
        setLastLocation()
    }
    
    func setLastLocation() {
        lastLocation = center
    }
    
    func getPoint(touchPoint: CGPoint) -> CGPoint {
        CGPoint(x: lastLocation.x + (touchPoint.x - lastPointLocation.x), y: lastLocation.y + (touchPoint.y - lastPointLocation.y))
    }
}
