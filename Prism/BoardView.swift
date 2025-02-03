//
//  BoardView.swift
//  Prism
//
//  Created by Phil Stern on 2/1/25.
//

import UIKit

struct Constant {
    static let prismSideLength = 200.0
    static let refractiveIndexOfAir = 1.0
    static let refractiveIndexOfGlass = 1.53  // (eventually make it a function of light wavelength)
}

class BoardView: UIView {

    let prismView = PrismView()
    
    let lightDirectionInAir = 0.rads  // +/-.pi radians (0 right, positive clockwise)
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
        // propagate light through air, until contacting prism (or off screen)
        while !prismView.path.contains(convert(point, to: prismView)) && frame.contains(point) {
            point += CGPoint(x: step * cos(lightDirectionInAir), y: step * sin(lightDirectionInAir))
            light.addLine(to: point)
        }
        // light contacted prism - find surface normal direction
        if let surfaceNormalAngle = surfaceNormalAngleAtPoint(point) {
            // draw small vector in normal direction, for now
            drawVectorAt(point, inDirection: surfaceNormalAngle, color: .cyan)
            // compute new direction through prism
            let angleOfIncidence = surfaceNormalAngle - lightDirectionInAir
            let angleOfRefraction = asin(Constant.refractiveIndexOfAir / Constant.refractiveIndexOfGlass * sin(angleOfIncidence))
            let lightDirectionInGlass = surfaceNormalAngle - angleOfRefraction
            // propagate light through prism, until contacting air (or off screen)
            while prismView.path.contains(convert(point, to: prismView)) && frame.contains(point) {
                point += CGPoint(x: step * cos(lightDirectionInGlass), y: step * sin(lightDirectionInGlass))
                light.addLine(to: point)
            }
        }
        UIColor.white.setStroke()
        light.lineWidth = 2
        light.stroke()
    }
    
    // MARK: - Utilities
    
    private func drawVectorAt(_ point: CGPoint, inDirection direction: Double, color: UIColor) {
        let normal = UIBezierPath()
        normal.move(to: point)
        normal.addLine(to: point + CGPoint(x: 30 * cos(direction), y: 30 * sin(direction)))
        color.setStroke()
        normal.setLineDash([5, 5], count: 2, phase: 0)
        normal.stroke()
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
        // of all directions pointing into shape, return middle one (should be normal to surface)
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
