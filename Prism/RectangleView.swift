//
//  RectangleView.swift
//  Prism
//
//  Created by Phil Stern on 2/6/25.
//

import UIKit

struct RectangleConst {
    static let widthPercent = 0.5//0.2  // percent bounds.width
}

class RectangleView: UIView, PathProvider {

    lazy var width = RectangleConst.widthPercent * bounds.width
    lazy var height = bounds.height

    // create path before drawing, since superview's draw runs before subview's draw,
    // and superview's draw uses path to determine which light points are inside shape
    lazy var path: UIBezierPath = {
        let rectangle = UIBezierPath(roundedRect: CGRect(x: (1 - RectangleConst.widthPercent) / 2 * bounds.width,
                                                         y: 1,
                                                         width: width,
                                                         height: height - 2),
                                     cornerRadius: 0.01)
        return rectangle
    }()
    
    override func draw(_ rect: CGRect) {
        path.lineWidth = 1
        UIColor.cyan.setStroke()
        path.stroke()
    }
}
