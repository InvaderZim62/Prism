//
//  RectangleView.swift
//  Prism
//
//  Created by Phil Stern on 2/6/25.
//

import UIKit

struct RectangleConst {
    static let widthPercent = 1.0  // percent bounds.width (set lower for narrower prism)
}

class RectangleView: UIView, PathProvider {

    let id = UUID()

    lazy var width = RectangleConst.widthPercent * bounds.width
    lazy var height = bounds.height

    // create path before drawing, since superview's draw runs before subview's draw,
    // and superview's draw uses path to determine which light points are inside shape
    lazy var path: UIBezierPath = {
        let rectangle = UIBezierPath(roundedRect: CGRect(x: (1 - RectangleConst.widthPercent) / 2 * bounds.width + 1.0,
                                                         y: 1,
                                                         width: width - 2,
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
