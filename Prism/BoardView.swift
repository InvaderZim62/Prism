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
    
    var lightAngle = 0.rads  // +/-.pi radians (0 right, positive clockwise)
    var lightSourceStartingPoint = CGPoint(x: 50, y: 280)

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
        var point = lightSourceStartingPoint
        let light = UIBezierPath()
        light.move(to: point)
        while !prismView.path.contains(convert(point, to: prismView)) && frame.contains(point) {
            point += CGPoint(x: step * cos(lightAngle), y: step * sin(lightAngle))
            light.addLine(to: point)
        }
        UIColor.white.setStroke()
        light.lineWidth = 2
        light.stroke()
        
        if let normalAngle = surfaceNormalAngleAtPoint(point) {
            let normal = UIBezierPath()
            normal.move(to: point)
            normal.addLine(to: point + CGPoint(x: 20 * cos(normalAngle), y: 20 * sin(normalAngle)))
            UIColor.red.setStroke()
            normal.stroke()
        }
    }
    
    // direction of surface normal pointing toward the inside of the shape
    // +/-.pi radians (0 right, positive clockwise)
    private func surfaceNormalAngleAtPoint(_ point: CGPoint) -> Double? {
        let radius = 3.0
        let numPoints = 90  // every 4 degrees
        let deltaAngle = 2 * .pi / Double(numPoints)
        var isContainedArray = [Bool]()
        for i in 0..<numPoints {
            let angle = Double(i) * deltaAngle - .pi
            let testPoint = point + CGPoint(x: radius * cos(angle), y: radius * sin(angle))
            let isContained = prismView.path.contains(convert(testPoint, to: prismView))
            isContainedArray.append(isContained)
        }
        // of all direction pointing into shape, return middle one
        if let middleTrueIndex = isContainedArray.indexOfMiddleTrue {
            return Double(middleTrueIndex) * deltaAngle - .pi
        } else {
            return nil
        }
    }
        
    // MARK: - Gestures handlers
    
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
