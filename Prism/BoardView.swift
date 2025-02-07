//
//  BoardView.swift
//  Prism
//
//  Created by Phil Stern on 2/1/25.
//

import UIKit

struct Constant {
    static let wavelengths = stride(from: 400.0, through: 680.0, by: 10.0)
//    static let wavelengths = [500.0]  // green light
    static let lightSourceSideLength = 140.0  // view size (bigger than drawing, to help rotating)
    static let triangleSideLength = 140.0
    static let rectangleSize = 120.0
    static let refractiveIndexOfAir = 1.0
    static let refractiveIndexOfGlass = 1.53  // (eventually make it a function of light wavelength)
    static let lightPropagationStepSize = 1.0
}

protocol PathProvider: UIView {
    var path: UIBezierPath { get }
}

class BoardView: UIView {

    var prismViews = [PathProvider]()
    let lightSourceView = LightSourceView()

    required init?(coder: NSCoder) {  // called for views added through Interface Builder
        super.init(coder: coder)
        addTriangleView(center: CGPoint(x: 193, y: 102), rotation: 0)
        addTriangleView(center: CGPoint(x: 330, y: 184), rotation: 180.rads)
        addRectangleView(center: CGPoint(x: 424, y: 261), rotation: 0)
        addLightSourceView(center: CGPoint(x: 69, y: 124), rotation: -20.rads)  // setup last, so it's on top
    }
    
    private func addTriangleView(center: CGPoint, rotation: Double) {
        let triangleView = TriangleView()
        triangleView.center = center
        triangleView.bounds.size = CGSize(width: Constant.triangleSideLength, height: Constant.triangleSideLength * sin(60.rads))
        triangleView.transform = triangleView.transform.rotated(by: rotation)
        triangleView.backgroundColor = .clear
        prismViews.append(triangleView)
        addSubview(triangleView)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        triangleView.addGestureRecognizer(pan)
        
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation))
        triangleView.addGestureRecognizer(rotation)
    }
    
    private func addRectangleView(center: CGPoint, rotation: Double) {
        let rectangleView = RectangleView()
        rectangleView.center = center
        rectangleView.bounds.size = CGSize(width: Constant.rectangleSize, height: Constant.rectangleSize)
        rectangleView.transform = rectangleView.transform.rotated(by: rotation)
        rectangleView.backgroundColor = .clear
        prismViews.append(rectangleView)
        addSubview(rectangleView)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        rectangleView.addGestureRecognizer(pan)
        
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation))
        rectangleView.addGestureRecognizer(rotation)
    }

    private func addLightSourceView(center: CGPoint, rotation: Double) {
        lightSourceView.bounds.size = CGSize(width: Constant.lightSourceSideLength, height: Constant.lightSourceSideLength)
        lightSourceView.center = center
        lightSourceView.transform = lightSourceView.transform.rotated(by: rotation)
        lightSourceView.backgroundColor = .clear
        addSubview(lightSourceView)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        lightSourceView.addGestureRecognizer(pan)
        
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation))
        lightSourceView.addGestureRecognizer(rotation)
    }

    // MARK: - Draw
    
    override func draw(_ rect: CGRect) {
        drawLight()
    }
    
    private func drawLight() {
        let startingPoint = lightSourceView.outputPoint
        let startingDirection = lightSourceView.direction
        guard prismContainingPoint(startingPoint) == nil else { return }  // can't start inside a prism
        
        // propagate separate light wavelengths/colors
        for wavelength in Constant.wavelengths {
            propagateLightWith(wavelength: wavelength, startingPoint: startingPoint, startingDirection: startingDirection)
        }
    }
    
    private func propagateLightWith(wavelength: Double, startingPoint: CGPoint, startingDirection: Double) {
        let color = colorForWavelength(wavelength)
        let refractiveIndexOfGlass = refractiveIndexOfGlassWithWavelength(wavelength)
        var point = startingPoint
        var lightDirections = [startingDirection]  // keep separate directions for each medium
        var mediumsTraversed = 0
        
        let light = UIBezierPath()
        light.move(to: point)
        
        for _ in 0..<prismViews.count + 1 {
            
            // propagate light through air, until contacting prism (or off screen)
            repeat {
                point += CGPoint(x: Constant.lightPropagationStepSize * cos(lightDirections[mediumsTraversed]),
                                 y: Constant.lightPropagationStepSize * sin(lightDirections[mediumsTraversed]))
                light.addLine(to: point)
                if isOffScreen(point) {
                    finishDrawingLight(light, color: color)
                    return
                }
            } while prismContainingPoint(point) == nil
            
            // bend light at prism interface
            let prismView = prismContainingPoint(point)!
            let lightDirectionPrism = lightDirectionOut(lightDirectionIn: lightDirections[mediumsTraversed],
                                                        point: point,
                                                        refractiveIndexOfGlass: refractiveIndexOfGlass,
                                                        prismView: prismView,
                                                        isEnteringPrism: true)
            lightDirections.append(lightDirectionPrism)
            mediumsTraversed += 1
            
            // propagate light through prism, until contacting air (or off screen)
            repeat {
                let lightDirection = lightDirections[mediumsTraversed]
                point += CGPoint(x: Constant.lightPropagationStepSize * cos(lightDirection),
                                 y: Constant.lightPropagationStepSize * sin(lightDirection))
                light.addLine(to: point)
                if isOffScreen(point) {
                    finishDrawingLight(light, color: color)
                    return
                }
            } while isInside(prismView, point: point)
            
            // bend light at air interface
            let lightDirectionAir = lightDirectionOut(lightDirectionIn: lightDirections[mediumsTraversed],
                                                      point: point,
                                                      refractiveIndexOfGlass: refractiveIndexOfGlass,
                                                      prismView: prismView,
                                                      isEnteringPrism: false)
            lightDirections.append(lightDirectionAir)
            mediumsTraversed += 1
        }
        finishDrawingLight(light, color: color)
    }
    
    private func finishDrawingLight(_ light: UIBezierPath, color: UIColor) {
        color.setStroke()
        light.lineWidth = 1
        light.stroke()
    }
    
    // MARK: - Utilities
    
    private func prismContainingPoint(_ point: CGPoint) -> PathProvider? {
        for prismView in prismViews {
            if prismView.path.contains(convert(point, to: prismView)) {
                return prismView
            }
        }
        return nil
    }

    private func isInside(_ shapeView: PathProvider, point: CGPoint) -> Bool {
        shapeView.path.contains(convert(point, to: shapeView))
    }

    private func isOffScreen(_ point: CGPoint) -> Bool {
        !frame.contains(point)
    }
    
    // light direction after crossing surface boundary
    private func lightDirectionOut(lightDirectionIn: Double,
                                   point: CGPoint,
                                   refractiveIndexOfGlass: Double,
                                   prismView: PathProvider,
                                   isEnteringPrism: Bool) -> Double {
        let surfaceNormalAngle = surfaceNormalAngleAtPoint(point, on: prismView)! + (isEnteringPrism ? 0 : .pi)  // normal to surface on incoming side
//        drawVectorAt(point, inDirection: surfaceNormalAngle, color: .cyan)  // used for debugging
        let angleOfIncidence = surfaceNormalAngle - lightDirectionIn
        let refractionRatio = isEnteringPrism ? Constant.refractiveIndexOfAir / refractiveIndexOfGlass : refractiveIndexOfGlass / Constant.refractiveIndexOfAir
        let angleOfRefraction = asin((refractionRatio * sin(angleOfIncidence)).limitedBetween(-1, and: 1))
        let lightDirectionOut = surfaceNormalAngle - angleOfRefraction
//        print(String(format: "light dir: %.1f, surface norm: %.1f, incidence: %.1f, refract: %.1f, light dir: %.1f",
//                     lightDirectionIn.degs, surfaceNormalAngle.degs, angleOfIncidence.degs, angleOfRefraction.degs, lightDirectionOut.degs))
        return lightDirectionOut
    }

    // direction of surface normal pointing toward inside of prism;
    // +/-.pi radians (0 right, positive clockwise)
    // found by checking a ring of points around input point, for points inside prism;
    // return the middle of all points inside (easier then averaging across any discontinuity in angles);
    private func surfaceNormalAngleAtPoint(_ point: CGPoint, on prismView: PathProvider) -> Double? {
        let radius = 4.0
        let numPoints = 360  // every degrees around circle
        let deltaAngle = 2 * .pi / Double(numPoints)
        var isDirectionInsideTriangle = [Bool]()
        for i in 0..<numPoints {
            let angle = Double(i) * deltaAngle - .pi
            let testPoint = point + CGPoint(x: radius * cos(angle), y: radius * sin(angle))
            let isInside = isInside(prismView, point: testPoint)
            isDirectionInsideTriangle.append(isInside)
        }
        // of all directions pointing into shape, return middle one (should be normal to surface)
        if let middleIndex = isDirectionInsideTriangle.indexOfMiddleTrue {
            return Double(middleIndex) * deltaAngle - .pi
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
