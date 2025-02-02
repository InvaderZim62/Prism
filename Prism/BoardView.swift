//
//  BoardView.swift
//  Prism
//
//  Created by Phil Stern on 2/1/25.
//

import UIKit

class BoardView: UIView {

    let prism = UIBezierPath()

    override func draw(_ rect: CGRect) {
        drawPrism()
    }
    
    private func drawPrism() {
        prism.move(to: CGPoint(x: 200, y: 200))
        prism.addLine(to: CGPoint(x: 300, y: 300))
        prism.addLine(to: CGPoint(x: 100, y: 300))
        prism.close()
        UIColor.red.setStroke()
        prism.stroke()
    }
}
