//
//  TriangleView.swift
//  Prism
//
//  Created by Phil Stern on 2/2/25.
//

import UIKit

class TriangleView: UIView, PathProvider {
    
    let id = UUID()

    // create path before drawing, since superview's draw runs before subview's draw,
    // and superview's draw uses path to determine which light points are inside shape
    lazy var path: UIBezierPath = {
        let triangle = UIBezierPath()
        triangle.move(to: CGPoint(x: bounds.midX, y: 1))
        triangle.addLine(to: CGPoint(x: bounds.width - 1, y: bounds.height - 1))
        triangle.addLine(to: CGPoint(x: 1, y:bounds.height - 1))
        triangle.close()
        return triangle
    }()

    override func draw(_ rect: CGRect) {
        path.lineWidth = 1
        UIColor.cyan.setStroke()
        path.stroke()
    }
}
