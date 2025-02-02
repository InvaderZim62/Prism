//
//  BoardView.swift
//  Prism
//
//  Created by Phil Stern on 2/1/25.
//

import UIKit

class BoardView: UIView {

    let prism = UIBezierPath()
    let light = UIBezierPath()
    
    var prismPeak = CGPoint(x: 200, y: 200)
    var prismSideLength = 200.0
    var lightAngle = 0.rads  // radians (0 right, positive clockwise)
    var lightSource = CGPoint(x: 50, y: 250)
    
//    var lightAngle = -45.0.rads  // radians (0 right, positive clockwise)
//    var lightSource = CGPoint(x: 50, y: 400)

    override func draw(_ rect: CGRect) {
        drawPrism()
        drawLight()
    }
    
    private func drawPrism() {
        prism.move(to: prismPeak)
        prism.addLine(to: prismPeak + CGPoint(x: prismSideLength * cos(60.rads), y: prismSideLength * sin(60.rads)))
        prism.addLine(to: prismPeak + CGPoint(x: -prismSideLength * cos(60.rads), y: prismSideLength * sin(60.rads)))
        prism.close()
        UIColor.white.setStroke()
        prism.stroke()
    }
    
    private func drawLight() {
        let step = 2.0
        var point = lightSource
        light.move(to: point)
        repeat {
            print(".", terminator: "")
            point += CGPoint(x: step * cos(lightAngle), y: step * sin(lightAngle))
            light.addLine(to: point)
        } while !prism.contains(point) && frame.contains(point)
        UIColor.white.setStroke()
        light.stroke()
    }
}
