//
//  BoardView.swift
//  Prism
//
//  Created by Phil Stern on 2/1/25.
//

import UIKit

struct Constant {
    static let prismSideLength = 200.0
}

class BoardView: UIView {

    let prismView = PrismView()
    
    var lightAngle = 0.rads  // radians (0 right, positive clockwise)
    var lightSourcePoint = CGPoint(x: 50, y: 280)

    required init?(coder: NSCoder) {  // called for views added through Interface Builder
        super.init(coder: coder)
        prismView.frame = CGRect(x: 100, y: 200, width: Constant.prismSideLength, height: Constant.prismSideLength * sin(60.rads))
        prismView.backgroundColor = .clear
        addSubview(prismView)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        prismView.addGestureRecognizer(pan)
        
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation))
        prismView.addGestureRecognizer(rotation)
    }
    
    override func draw(_ rect: CGRect) {
        drawLight()
    }
    
    private func drawLight() {
        let step = 2.0
        var point = lightSourcePoint
        let light = UIBezierPath()
        light.move(to: point)
        while !prismView.path.contains(convert(point, to: prismView)) && frame.contains(point) {
            point += CGPoint(x: step * cos(lightAngle), y: step * sin(lightAngle))
            light.addLine(to: point)
        }
        UIColor.white.setStroke()
        light.lineWidth = 2
        light.stroke()
    }
    
    @objc func handlePan(recognizer: UIPanGestureRecognizer) {
        if let pannedView = recognizer.view {
            let translation = recognizer.translation(in: self)
            pannedView.center += translation
            recognizer.setTranslation(.zero, in: self)
            setNeedsDisplay()
        }
    }
    
    // to allow simultaneous rotate and pan gestures,
    // see Color app, which uses simultaneous pinch and pan gestures
    @objc func handleRotation(recognizer: UIRotationGestureRecognizer) {
        if let rotatedView = recognizer.view {
            let rotation = recognizer.rotation
            rotatedView.transform = rotatedView.transform.rotated(by: rotation)
            recognizer.rotation = 0  // reset, to use incremental rotations
            setNeedsDisplay()
        }
    }
}
