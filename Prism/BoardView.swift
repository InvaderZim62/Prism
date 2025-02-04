//
//  BoardView.swift
//  Prism
//
//  Created by Phil Stern on 2/1/25.
//

import UIKit

struct Constant {
    static let prismSideLength = 180.0
    static let lightSourceSideLength = 140.0  // view size (bigger than drawing)
    static let refractiveIndexOfAir = 1.0
    static let refractiveIndexOfGlass = 1.53  // (eventually make it a function of light wavelength)
    static let lightSourceStartingCenter = CGPoint(x: 50, y: 320)
    static let lightSourceStartingDirection = -20.rads  // +/-.pi radians (0 right, positive clockwise)
}

class BoardView: UIView {

    let lightSourceView = LightSourceView()
    let prismView = PrismView()

    required init?(coder: NSCoder) {  // called for views added through Interface Builder
        super.init(coder: coder)
        setupLightSource()
        setupPrismView()
    }
    
    private func setupLightSource() {
        lightSourceView.bounds.size = CGSize(width: Constant.lightSourceSideLength, height: Constant.lightSourceSideLength)
        lightSourceView.center = Constant.lightSourceStartingCenter
        lightSourceView.transform = prismView.transform.rotated(by: Constant.lightSourceStartingDirection)
        lightSourceView.backgroundColor = .clear
        addSubview(lightSourceView)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        lightSourceView.addGestureRecognizer(pan)
        
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation))
        lightSourceView.addGestureRecognizer(rotation)
    }
    
    private func setupPrismView() {
        prismView.frame = CGRect(x: 100, y: 200, width: Constant.prismSideLength, height: Constant.prismSideLength * sin(60.rads))
        prismView.backgroundColor = .clear
        addSubview(prismView)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        prismView.addGestureRecognizer(pan)
        
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation))
        prismView.addGestureRecognizer(rotation)
    }
    
    // MARK: - Draw
    
    override func draw(_ rect: CGRect) {
        drawLight()
    }
    
    private func drawLight() {
        var point = lightSourceView.outputPoint
        guard !isInside(prismView, point: point) else { return }  // might want to allow starting inside prism (skip to propagate light through prism)
        var mediumsTraversed = 0
        var lightDirections = [lightSourceView.direction]
        let step = 2.0
        let light = UIBezierPath()
        light.move(to: point)
        
        // propagate light through air, until contacting prism (or off screen)
        while !isInside(prismView, point: point) && isOnScreen(point) {
            let lightDirection = lightDirections[mediumsTraversed]
            point += CGPoint(x: step * cos(lightDirection), y: step * sin(lightDirection))
            light.addLine(to: point)
        }
        guard isOnScreen(point) else { finishDrawingLight(light); return }
        
        // determine light direction through prism
        let lightDirectionPrism = lightDirectionOut(lightDirectionIn: lightDirections[mediumsTraversed], point: point, isEnteringPrism: true)
        lightDirections.append(lightDirectionPrism)
        mediumsTraversed += 1
        
        // propagate light through prism, until contacting air (or off screen)
        while isInside(prismView, point: point) && isOnScreen(point) {
            let lightDirection = lightDirections[mediumsTraversed]
            point += CGPoint(x: step * cos(lightDirection), y: step * sin(lightDirection))
            light.addLine(to: point)
        }
        guard isOnScreen(point) else { finishDrawingLight(light); return }
        
        // determine light direction through air
        let lightDirectionAir = lightDirectionOut(lightDirectionIn: lightDirections[mediumsTraversed], point: point, isEnteringPrism: false)
        lightDirections.append(lightDirectionAir)
        mediumsTraversed += 1

        // propagate light through air, until off screen
        while isOnScreen(point) {
            let lightDirection = lightDirections[mediumsTraversed]
            point += CGPoint(x: step * cos(lightDirection), y: step * sin(lightDirection))
            light.addLine(to: point)
        }
        finishDrawingLight(light)
    }
    
    private func finishDrawingLight(_ light: UIBezierPath) {
        UIColor.white.setStroke()
        light.lineWidth = 2
        light.stroke()
    }
    
    // MARK: - Utilities
    
    private func isInside(_ prismView: PrismView, point: CGPoint) -> Bool {
        prismView.path.contains(convert(point, to: prismView))
    }

    private func isOnScreen(_ point: CGPoint) -> Bool {
        frame.contains(point)
    }
    
    // light direction after crossing surface boundary
    private func lightDirectionOut(lightDirectionIn: Double, point: CGPoint, isEnteringPrism: Bool) -> Double {
        let surfaceNormalAngle = surfaceNormalAngleAtPoint(point)! + (isEnteringPrism ? 0 : .pi)
//        drawVectorAt(point, inDirection: surfaceNormalAngle, color: .cyan)
        let angleOfIncidence = surfaceNormalAngle - lightDirectionIn
        var refractionRatio = Constant.refractiveIndexOfAir / Constant.refractiveIndexOfGlass
        if !isEnteringPrism { refractionRatio = 1 / refractionRatio }
        var sinTheta2 = (refractionRatio * sin(angleOfIncidence))
        let angleOfRefraction = asin(sinTheta2.limitedBetween(-1, and: 1))
        let lightDirectionOut = surfaceNormalAngle - angleOfRefraction
        return lightDirectionOut
    }

    // direction of surface normal pointing toward inside of prismView
    // +/-.pi radians (0 right, positive clockwise)
    private func surfaceNormalAngleAtPoint(_ point: CGPoint) -> Double? {
        let radius = 3.0
        let numPoints = 180  // every 2 degrees
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

    private func drawVectorAt(_ point: CGPoint, inDirection direction: Double, color: UIColor) {
        let normal = UIBezierPath()
        normal.move(to: point)
        normal.addLine(to: point + CGPoint(x: 30 * cos(direction), y: 30 * sin(direction)))
        color.setStroke()
        normal.setLineDash([5, 5], count: 2, phase: 0)
        normal.stroke()
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
