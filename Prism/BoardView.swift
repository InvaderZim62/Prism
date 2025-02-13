//
//  BoardView.swift
//  Prism
//
//  Created by Phil Stern on 2/1/25.
//
//  To allow simultaneous pan and rotate gestures:
//  - add UIGestureRecognizerDelegate to class definition
//  - set gesture delegates to self
//  - add func gestureRecognizer(shouldRecognizeSimultaneouslyWith:)
//

import UIKit

struct Constant {
    static let wavelengths = stride(from: 400.0, through: 680.0, by: 7.0)  // 41 wavelengths
//    static let wavelengths = [580.0]  // yellow light
    static let lightSourceSideLength = 140.0  // view size (bigger than drawing, to help rotating)
    static let triangleBaseLength = 140.0
    static let rectangleSize = 120.0  // also used for mirror
    static let refractiveIndexOfAir = 1.0
    static let refractiveIndexOfGlass = 1.53  // (eventually make it a function of light wavelength)
    static let lightPropagationStepSize = 1.0
    static let rectangleWidthPercent = 1.0  // percent bounds.width (set lower for narrower prism)
    static let mirrorWidthPercent = 0.1
}

class BoardView: UIView, UIGestureRecognizerDelegate {  // UIGestureRecognizerDelegate for simultaneous gestures

    var prismViews = [PrismView]()  // including mirror
    let lightSourceView = LightSourceView()

    required init?(coder: NSCoder) {  // init(coder:) called for views added through Interface Builder
        super.init(coder: coder)
        addPrismView(prismType: .triangle,
                     center: CGPoint(x: 193, y: 102),
                     width: Constant.triangleBaseLength,
                     height: Constant.triangleBaseLength * sin(60.rads),
                     rotation: 0)
        addPrismView(prismType: .triangle,
                     center: CGPoint(x: 221, y: 297),
                     width: Constant.triangleBaseLength,
                     height: Constant.triangleBaseLength * sin(60.rads),
                     rotation: 180.rads)
        addPrismView(prismType: .rectangle,
                     center: CGPoint(x: 393, y: 261),
                     width: Constant.rectangleSize,
                     height: Constant.rectangleSize,
                     rotation: 0)
        addPrismView(prismType: .mirror,
                     center: CGPoint(x: 562, y: 209),
                     width: Constant.rectangleSize,
                     height: Constant.rectangleSize,
                     rotation: 0)
        addLightSourceView(center: CGPoint(x: 69, y: 124), rotation: -20.rads)  // setup last, so it's on top
    }
    
    private func addPrismView(prismType: PrismType, center: CGPoint, width: Double, height: Double, rotation: Double) {
        let prismView = PrismView()
        prismView.type = prismType
        prismView.center = center
        prismView.bounds.size = CGSize(width: width, height: height)
        prismView.transform = prismView.transform.rotated(by: rotation)
        prismView.backgroundColor = .clear
        addPanAndRotateGesturesTo(prismView)
        prismViews.append(prismView)
        addSubview(prismView)
    }

    private func addLightSourceView(center: CGPoint, rotation: Double) {
        lightSourceView.bounds.size = CGSize(width: Constant.lightSourceSideLength, height: Constant.lightSourceSideLength)
        lightSourceView.center = center
        lightSourceView.transform = lightSourceView.transform.rotated(by: rotation)
        lightSourceView.backgroundColor = .clear
        addPanAndRotateGesturesTo(lightSourceView)
        addSubview(lightSourceView)
    }
    
    private func addPanAndRotateGesturesTo(_ view: UIView) {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        pan.delegate = self  // needed for gestureRecognizer, below
        view.addGestureRecognizer(pan)
        
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation))
        rotation.delegate = self  // needed for gestureRecognizer, below
        view.addGestureRecognizer(rotation)
    }

    // MARK: - Draw
    
    override func draw(_ rect: CGRect) {
        drawLight()
    }
    
    private func drawLight() {
        let startingPoint = lightSourceView.outputPoint
        let startingDirection = lightSourceView.direction
        guard prismContainingPoint(startingPoint) == nil else { return }  // don't start inside a prism
        
        // propagate separate light wavelengths/colors
        for wavelength in Constant.wavelengths {
            propagateLightWith(wavelength: wavelength, startingPoint: startingPoint, startingDirection: startingDirection)
        }
        // add white line next to yellow, on top (otherwise light source looks red)
        propagateLightWith(wavelength: 585, startingPoint: startingPoint, startingDirection: startingDirection)
    }
    
    private func propagateLightWith(wavelength: Double, startingPoint: CGPoint, startingDirection: Double) {
        var color = colorForWavelength(wavelength)
        if wavelength == 585 { color = .white }  // magic number, close to yellow
        let refractiveIndexOfGlass = refractiveIndexOfGlassWithWavelength(wavelength)
        var point = startingPoint
        var directions = [startingDirection]  // keep separate directions for each medium
        var mediumsTraversed = 0
        
        let light = UIBezierPath()
        light.move(to: point)
        
        for _ in 0..<2 * prismViews.count {  // allow for light to traverse through all prisms twice
            
            // propagate light through air, until contacting next prism (or off screen)
            guard propagateLightThroughAir(light: light,
                                           direction: directions[mediumsTraversed],
                                           point: &point,
                                           color: color) else { return }
            
            guard let prismView = prismContainingPoint(point) else { return }
            
            if prismView.type == .mirror {
                // reflect light off mirror
                let reflectedDirection = .pi - directions[mediumsTraversed] + 2 * prismView.rotation
                directions.append(reflectedDirection)
                mediumsTraversed += 1
            } else {
                // bend light at prism interface
                if let lightDirectionInPrism = lightDirectionOut(lightDirectionIn: directions[mediumsTraversed],
                                                                 point: point,
                                                                 refractiveIndexOfGlass: refractiveIndexOfGlass,
                                                                 prismView: prismView,
                                                                 isEnteringPrism: true) {
                    directions.append(lightDirectionInPrism)
                    mediumsTraversed += 1
                } else {
                    // overlapping prisms
                    finishDrawingLight(light, color: color)
                    return
                }
                
                // propagate light through prism, until contacting air (or off screen)
                guard propagateLightThroughPrism(prismView,
                                                 light: light,
                                                 direction: directions[mediumsTraversed],
                                                 point: &point,
                                                 color: color) else { return }
                
                // bend light at air interface
                if let lightDirectionInAir = lightDirectionOut(lightDirectionIn: directions[mediumsTraversed],
                                                               point: point,
                                                               refractiveIndexOfGlass: refractiveIndexOfGlass,
                                                               prismView: prismView,
                                                               isEnteringPrism: false) {
                    directions.append(lightDirectionInAir)
                    mediumsTraversed += 1
                } else {
                    // overlapping prisms
                    finishDrawingLight(light, color: color)
                    return
                }
            }
        }
        finishDrawingLight(light, color: color)
    }
    
    private func propagateLightThroughAir(light: UIBezierPath, direction: Double, point: inout CGPoint, color: UIColor) -> Bool {
        repeat {
            point += CGPoint(x: Constant.lightPropagationStepSize * cos(direction),
                             y: Constant.lightPropagationStepSize * sin(direction))
            light.addLine(to: point)
            if isOffScreen(point) {
                finishDrawingLight(light, color: color)
                return false
            }
        } while prismContainingPoint(point) == nil
        return true
    }

    private func propagateLightThroughPrism(_ prismView: PrismView, light: UIBezierPath, direction: Double, point: inout CGPoint, color: UIColor) -> Bool {
        repeat {
            let lightDirection = direction
            point += CGPoint(x: Constant.lightPropagationStepSize * cos(lightDirection),
                             y: Constant.lightPropagationStepSize * sin(lightDirection))
            light.addLine(to: point)
            if isOffScreen(point) {
                finishDrawingLight(light, color: color)
                return false
            }
        } while isInside(prismView, point: point)
        return true
    }
    
    private func finishDrawingLight(_ light: UIBezierPath, color: UIColor) {
        color.setStroke()
        light.lineWidth = 1
        light.stroke()
    }
    
    // MARK: - Utilities
    
    private func prismContainingPoint(_ point: CGPoint) -> PrismView? {
        for prismView in prismViews {
            if prismView.path.contains(convert(point, to: prismView)) {
                return prismView
            }
        }
        return nil
    }

    private func isInside(_ prismView: PrismView, point: CGPoint) -> Bool {
        prismView.path.contains(convert(point, to: prismView))
    }

    private func isOffScreen(_ point: CGPoint) -> Bool {
        !frame.contains(point)
    }
    
    // light direction after crossing surface boundary, based on Snell's law;
    // at point where light exiting prism is parallel to surface, it reflects inward;
    // it then follows a straight line out of prism in calling function (refraction
    // when finally exiting prism not currently modeled)
    private func lightDirectionOut(lightDirectionIn: Double,
                                   point: CGPoint,
                                   refractiveIndexOfGlass: Double,
                                   prismView: PrismView,
                                   isEnteringPrism: Bool) -> Double? {
        if var surfaceNormalAngle = surfaceNormalAngleAtPoint(point, on: prismView) {
            surfaceNormalAngle = (surfaceNormalAngle + (isEnteringPrism ? 0 : .pi)).wrapPi
//            drawVectorAt(point, inDirection: surfaceNormalAngle, color: .cyan)  // used for debugging
            let angleOfIncidence = (surfaceNormalAngle - lightDirectionIn).wrapPi
            let refractionRatio = isEnteringPrism ? Constant.refractiveIndexOfAir / refractiveIndexOfGlass : refractiveIndexOfGlass / Constant.refractiveIndexOfAir
            let sinAngleOfRefraction = refractionRatio * sin(angleOfIncidence)
            let lightDirectionOut: Double
            if isEnteringPrism {
                let angleOfRefraction = asin(sinAngleOfRefraction)
                lightDirectionOut = (surfaceNormalAngle - angleOfRefraction).wrapPi
            } else {
                if sinAngleOfRefraction >= -1 && sinAngleOfRefraction <= 1 {
                    // refraction through surface (exiting prism)
                    let angleOfRefraction = asin(sinAngleOfRefraction)
                    lightDirectionOut = (surfaceNormalAngle - angleOfRefraction).wrapPi
//                    print(String(format: "%@, light dir: %.1f, surface norm: %.1f, incidence: %.1f, refract: %.1f, light dir: %.1f", isEnteringPrism ? "Entering" : "Exiting", lightDirectionIn.degs, surfaceNormalAngle.degs, angleOfIncidence.degs, angleOfRefraction.degs, lightDirectionOut.degs))
                } else {
                    // reflection at surface (staying in prism)
                    lightDirectionOut = .pi - lightDirectionIn + 2 * surfaceNormalAngle
                }
            }
            return lightDirectionOut
        } else {
            return nil
        }
    }
    
    // direction of surface normal pointing toward inside of prism;
    // +/-.pi radians (0 right, positive clockwise)
    private func surfaceNormalAngleAtPoint(_ surfacePoint: CGPoint, on prismView: PrismView) -> Double? {
        let angleFromCenterToPoint = atan2(surfacePoint.y - prismView.center.y, surfacePoint.x - prismView.center.x)
        return prismView.directionOfSurfaceNormalAt(angle: angleFromCenterToPoint)
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
        
        if wavelength >= 380 && wavelength < 440 {
            red = -(wavelength - 440) / (440 - 380)
            green = 0.0
            blue = 1.0
        } else if wavelength >= 440 && wavelength < 490 {
            red = 0.0
            green = (wavelength - 440) / (490 - 440)
            blue = 1.0
        } else if wavelength >= 490 && wavelength < 510 {
            red = 0.0
            green = 1.0
            blue = -(wavelength - 510) / (510 - 490)
        } else if wavelength >= 510 && wavelength < 580 {
            red = (wavelength - 510) / (580 - 510)
            green = 1.0
            blue = 0.0
        } else if wavelength >= 580 && wavelength < 645 {
            red = 1.0
            green = -(wavelength - 645) / (645 - 580)
            blue = 0.0
        } else if wavelength >= 645 && wavelength < 781 {
            red = 1.0
            green = 0.0
            blue = 0.0
        } else {
            red = 0.0
            green = 0.0
            blue = 0.0
        }
        
        // make intensity fall off near vision limits
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
    // see Colors app, which uses simultaneous pinch and pan gestures
    @objc func handleRotation(recognizer: UIRotationGestureRecognizer) {
        if let rotatedView = recognizer.view {
            let rotation = recognizer.rotation
            rotatedView.transform = rotatedView.transform.rotated(by: rotation)
            recognizer.rotation = 0  // reset, to use incremental rotations
            setNeedsDisplay()
        }
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    // allow simultaneous pan and rotate gestures
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIPanGestureRecognizer || gestureRecognizer is UIRotationGestureRecognizer {
            return true
        } else {
            return false
        }
    }
}
