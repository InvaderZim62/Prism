//
//  PrismView.swift
//  Prism
//
//  Created by Phil Stern on 2/2/25.
//

import UIKit

class PrismView: UIView {

    // create path before drawing, since superview's draw runs before subview's draw,
    // and superview's draw needs path
    lazy var path: UIBezierPath = {
        let prism = UIBezierPath()
        prism.move(to: CGPoint(x: bounds.midX, y: 1))
        prism.addLine(to: CGPoint(x: bounds.width - 1, y: bounds.height - 1))
        prism.addLine(to: CGPoint(x: 1, y:bounds.height - 1))
        prism.close()
        return prism
    }()

    override func draw(_ rect: CGRect) {
        path.lineWidth = 1
        UIColor.cyan.setStroke()
        path.stroke()
    }
}
