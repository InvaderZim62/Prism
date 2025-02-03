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
}
