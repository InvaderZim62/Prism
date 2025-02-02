//
//  BoardView.swift
//  Prism
//
//  Created by Phil Stern on 2/1/25.
//

import UIKit

class BoardView: UIView {

    let prism = UIBezierPath()
    var rectangle = UIBezierPath()

    override func draw(_ rect: CGRect) {
        print("BoardView.draw")
        drawPrism()
        drawRectangle()
        drawPoint()
    }
    
    private func drawPrism() {
        prism.move(to: CGPoint(x: 200, y: 200))
        prism.addLine(to: CGPoint(x: 300, y: 300))
        prism.addLine(to: CGPoint(x: 100, y: 300))
        prism.close()
//        prism.setLineDash([5, 5], count: 2, phase: 0)
        
        let newPath = prism.cgPath.copy(strokingWithWidth: 3, lineCap: CGLineCap.butt, lineJoin: CGLineJoin.round, miterLimit: 0)
        let newBezier = UIBezierPath(cgPath: newPath)
        UIColor.green.setStroke()
        newBezier.stroke()

        UIColor.red.setStroke()
        prism.stroke()
    }
    
    private func drawRectangle() {
        UIColor.blue.setStroke()
        rectangle.stroke()
    }
    
    private func drawPoint() {
        let point = UIBezierPath(arcCenter: Constant.insidePoint, radius: 3, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        UIColor.black.setFill()
        point.fill()
    }
}
