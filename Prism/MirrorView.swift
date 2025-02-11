//
//  MirrorView.swift
//  Prism
//
//  Created by Phil Stern on 2/10/25.
//

import UIKit

struct MirrorConst {
    static let widthPercent = 0.1  // percent bounds.width
}

class MirrorView: UIView, PathProvider {

    let id = UUID()
    
    lazy var width = MirrorConst.widthPercent * bounds.width
    lazy var height = bounds.height
    
    var direction: Double {
        atan2(self.transform.b, self.transform.a)
    }

    // create path before drawing, since superview's draw runs before subview's draw,
    // and superview's draw uses path to determine which light points are inside shape
    lazy var path: UIBezierPath = {
        let rectangle = UIBezierPath(roundedRect: CGRect(x: (1 - MirrorConst.widthPercent) / 2 * bounds.width + 1.0,
                                                         y: 1,
                                                         width: width - 2,
                                                         height: height - 2),
                                     cornerRadius: 0.01)
        return rectangle
    }()
    
    override func draw(_ rect: CGRect) {
        path.lineWidth = 2
        UIColor.lightGray.setStroke()
        path.stroke()
        UIColor.black.setFill()
        path.fill()
    }
}
