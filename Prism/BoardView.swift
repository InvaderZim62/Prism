//
//  BoardView.swift
//  Prism
//
//  Created by Phil Stern on 2/1/25.
//

import UIKit

struct Constant {
    static let lightWaveLengths = stride(from: 400.0, through: 680.0, by: 40.0)
    static let prismSideLength = 180.0
    static let lightSourceSideLength = 140.0  // view size (bigger than drawing)
    static let refractiveIndexOfAir = 1.0
    static let refractiveIndexOfGlass = 1.53  // (eventually make it a function of light wavelength)
    static let prismStartingCenter = CGPoint(x: 200, y: 150)
    static let lightSourceStartingCenter = CGPoint(x: 50, y: 180)
    static let lightSourceStartingDirection = -20.rads  // +/-.pi radians (0 right, positive clockwise)
    static let lightPropagationStepSize = 2.0
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
        prismView.center = Constant.prismStartingCenter
        prismView.bounds.size = CGSize(width: Constant.prismSideLength, height: Constant.prismSideLength * sin(60.rads))
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
        let lightDirection = lightSourceView.direction
        let light = UIBezierPath()
        light.move(to: point)
        
        // propagate light through air, until contacting prism (or off screen)
        while !isInside(prismView, point: point) && isOnScreen(point) {
            point += CGPoint(x: Constant.lightPropagationStepSize * cos(lightDirection),
                             y: Constant.lightPropagationStepSize * sin(lightDirection))
            light.addLine(to: point)
        }
        finishDrawingLight(light, color: .white)
        guard isOnScreen(point) else { return }
        
        // continue propagating each individual color through prism and beyond
        for wavelength in Constant.lightWaveLengths {
            continuePropagatingLightWith(wavelength: wavelength, startingLightDirection: lightDirection, startingPoint: point)
        }
//        for (index, wavelength) in Constant.lightWaveLengths.enumerated() {
//            // offset slightly, so last color (red) doesn't start out covering everything
//            let offset = CGPoint(x: 0.2 * Double(index), y: 0.2 * Double(index))
//            continuePropagatingLightWith(wavelength: wavelength, startingLightDirection: lightDirection, startingPoint: point + offset)
//        }
    }
    
    private func continuePropagatingLightWith(wavelength: Double, startingLightDirection: Double, startingPoint: CGPoint) {
        let color = colorForWavelength(wavelength)
        let refractiveIndexOfGlass = refractiveIndexOfGlassWithWavelength(wavelength)
        
        var point = startingPoint
        var mediumsTraversed = 0
        var lightDirections = [startingLightDirection]
        let light = UIBezierPath()
        light.move(to: point)

        // bend light at prism interface
        let lightDirectionPrism = lightDirectionOut(lightDirectionIn: lightDirections[mediumsTraversed],
                                                    point: point,
                                                    refractiveIndexOfGlass: refractiveIndexOfGlass,
                                                    isEnteringPrism: true)
        lightDirections.append(lightDirectionPrism)
        mediumsTraversed += 1
        
        // propagate light through prism, until contacting air (or off screen)
        while isInside(prismView, point: point) && isOnScreen(point) {
            let lightDirection = lightDirections[mediumsTraversed]
            point += CGPoint(x: Constant.lightPropagationStepSize * cos(lightDirection),
                             y: Constant.lightPropagationStepSize * sin(lightDirection))
            light.addLine(to: point)
        }
        guard isOnScreen(point) else { finishDrawingLight(light, color: color); return }
        
        // bend light at air interface
        let lightDirectionAir = lightDirectionOut(lightDirectionIn: lightDirections[mediumsTraversed],
                                                  point: point,
                                                  refractiveIndexOfGlass: refractiveIndexOfGlass,
                                                  isEnteringPrism: false)
        lightDirections.append(lightDirectionAir)
        mediumsTraversed += 1
        
        // propagate light through air, until off screen
        while isOnScreen(point) {
            let lightDirection = lightDirections[mediumsTraversed]
            point += CGPoint(x: Constant.lightPropagationStepSize * cos(lightDirection),
                             y: Constant.lightPropagationStepSize * sin(lightDirection))
            light.addLine(to: point)
        }
        finishDrawingLight(light, color: color)
    }
    
    private func finishDrawingLight(_ light: UIBezierPath, color: UIColor) {
        color.setStroke()
        light.lineWidth = 1
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
    private func lightDirectionOut(lightDirectionIn: Double, point: CGPoint, refractiveIndexOfGlass: Double, isEnteringPrism: Bool) -> Double {
        let surfaceNormalAngle = surfaceNormalAngleAtPoint(point)! + (isEnteringPrism ? 0 : .pi)
//        drawVectorAt(point, inDirection: surfaceNormalAngle, color: .cyan)
        let angleOfIncidence = surfaceNormalAngle - lightDirectionIn
        var refractionRatio = Constant.refractiveIndexOfAir / refractiveIndexOfGlass
        if !isEnteringPrism { refractionRatio = 1 / refractionRatio }
        var sinTheta2 = (refractionRatio * sin(angleOfIncidence))
        let angleOfRefraction = asin(sinTheta2.limitedBetween(-1, and: 1))
        let lightDirectionOut = surfaceNormalAngle - angleOfRefraction
        return lightDirectionOut
    }

    // direction of surface normal pointing toward inside of prismView
    // +/-.pi radians (0 right, positive clockwise)
    private func surfaceNormalAngleAtPoint(_ point: CGPoint) -> Double? {
        let radius = 4.0
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
        // pws: consider averaging middle two, if even number of true's
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
    
    // from: https://www.koppglass.com/blog/optical-properties-glass-how-light-and-glass-interact
    private func refractiveIndexOfGlassWithWavelength(_ wavelength: Double) -> Double {
        1.61 - 0.00024121 * wavelength + 0.00000016 * wavelength * wavelength
    }
    
    // from: https://stackoverflow.com/a/14917481/2526464
    private func colorForWavelength(_ wavelength: Double) -> UIColor {
        var factor = 0.0
        var red = 0.0
        var green = 0.0
        var blue = 0.0
        
        if((wavelength >= 380) && (wavelength < 440)) {
            red = -(wavelength - 440) / (440 - 380)
            green = 0.0
            blue = 1.0
        } else if((wavelength >= 440) && (wavelength < 490)) {
            red = 0.0
            green = (wavelength - 440) / (490 - 440)
            blue = 1.0
        } else if((wavelength >= 490) && (wavelength < 510)) {
            red = 0.0
            green = 1.0
            blue = -(wavelength - 510) / (510 - 490)
        } else if((wavelength >= 510) && (wavelength < 580)) {
            red = (wavelength - 510) / (580 - 510)
            green = 1.0
            blue = 0.0
        } else if((wavelength >= 580) && (wavelength < 645)) {
            red = 1.0
            green = -(wavelength - 645) / (645 - 580)
            blue = 0.0
        } else if((wavelength >= 645) && (wavelength < 781)) {
            red = 1.0
            green = 0.0
            blue = 0.0
        } else {
            red = 0.0
            green = 0.0
            blue = 0.0
        }
        
        // Let the intensity fall off near the vision limits
        if((wavelength >= 380) && (wavelength < 420)) {
            factor = 0.3 + 0.7 * (wavelength - 380) / (420 - 380)
        } else if((wavelength >= 420) && (wavelength < 701)) {
            factor = 1.0
        } else if((wavelength >= 701) && (wavelength < 781)) {
            factor = 0.3 + 0.7 * (780 - wavelength) / (780 - 700)
        } else {
            factor = 0.0
        }
        
        let gamma = 0.8
        
        red = pow(red * factor, gamma)
        green = pow(green * factor, gamma)
        blue = pow(blue * factor, gamma)
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
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
