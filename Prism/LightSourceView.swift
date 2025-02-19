//
//  LightSourceView.swift
//  Prism
//
//  Created by Phil Stern on 2/4/25.
//

import UIKit

struct LightConst {
    static let lengthPercent = 0.5  // percent bounds.width
    static let widthPercent = 0.12  // percent bounds.height
}

class LightSourceView: UIView, Selectable {
    
    let id = UUID()
    var isSelected = false { didSet { setNeedsDisplay() } }

    lazy var width = LightConst.lengthPercent * bounds.width
    lazy var height = LightConst.widthPercent * bounds.height

    var outputPoint: CGPoint {
        // superview (boardView) coordinates
        center + CGPoint(x: (width / 2) * cos(direction), y: (width / 2) * sin(direction))
    }
    
    var direction: Double {
        atan2(self.transform.b, self.transform.a)
    }

    override func draw(_ rect: CGRect) {
        let rectangle = UIBezierPath(roundedRect: CGRect(x: (1 - LightConst.lengthPercent) / 2 * bounds.width,
                                                         y: (1 - LightConst.widthPercent) / 2 * bounds.height,
                                                         width: width,
                                                         height: height),
                                     cornerRadius: 0.01)
        UIColor.black.setFill()
        rectangle.fill()
        isSelected ? Constant.selectedObjectColor.setStroke() : UIColor.lightGray.setStroke()
        rectangle.lineWidth = 2
        rectangle.stroke()
    }
}
