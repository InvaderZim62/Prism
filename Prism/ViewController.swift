//
//  ViewController.swift
//  Prism
//
//  Created by Phil Stern on 2/1/25.
//

import UIKit

struct Constant {
    static let insidePoint = CGPoint(x: 100, y: 150)  // inside boardView.prism
    static let outsidePoint = CGPoint(x: 100, y: 100)  // outside boardView.prism
}

class ViewController: UIViewController {
        
    @IBOutlet weak var boardView: BoardView!
    
    override func viewDidLoad() {
        print("viewDidLoad")
        super.viewDidLoad()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [unowned self] in
            testIsInside()
            testIsInside2()
            testIsInside3()
        }
    }
    
    private func testIsInside() {
        let circle = UIBezierPath(arcCenter: Constant.insidePoint, radius: 10, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        if circle.containsInside(Constant.insidePoint, toleranceWidth: 3.0) {
            print("point is inside circle (not shown)")
        } else {
            print("point is outside circle")
        }
    }
    
    private func testIsInside2() {
        if boardView.prism.containsInsideBorder(Constant.insidePoint, toleranceWidth: 3.0) {
            print("point touches prism")
        } else {
            print("point doesn't touch prism")
        }
    }
    
//    private func testIsInside3() {
//        boardView.rectangle = UIBezierPath(roundedRect: CGRect(x: 50, y: 150, width: 300, height: 200), cornerRadius: 0)
//        boardView.setNeedsDisplay()
//        if boardView.rectangle.containsInsideBorder(Constant.insidePoint, toleranceWidth: 3.0) {
//            print("point is inside rectangle")
//        } else {
//            print("point is outside rectangle")
//        }
//    }
    
    private func testIsInside3() {
        let rect = UIBezierPath(roundedRect: CGRect(x: 50, y: 150, width: 300, height: 200), cornerRadius: 0)
        let rectPath = rect.cgPath.copy(strokingWithWidth: 10, lineCap: CGLineCap.butt, lineJoin: CGLineJoin.round, miterLimit: 0)
        boardView.rectangle = UIBezierPath(cgPath: rectPath)
        boardView.setNeedsDisplay()
        if rect.containsInsideBorder(Constant.insidePoint, toleranceWidth: 3.0) {
            print("point touches rectangle")
        } else {
            print("point doesn't touch rectangle")
        }
    }
    
//    private func testIsInside3() {
//        // actually a circle, but wanted to piggy-back on boardView.rectangle
//        let rect = UIBezierPath(arcCenter: Constant.insidePoint, radius: 100, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
////        let rectPath = rect.cgPath.copy(strokingWithWidth: 10, lineCap: CGLineCap.butt, lineJoin: CGLineJoin.round, miterLimit: 0)
//        boardView.rectangle = UIBezierPath(cgPath: rect.cgPath)
//        boardView.setNeedsDisplay()
//        if boardView.rectangle.containsInsideBorder(Constant.insidePoint, toleranceWidth: 3.0) {  // should always be true (is false!!!)
//            print("point is inside circle")
//        } else {
//            print("point is outside circle")
//        }
//    }
}

// from: https://stackoverflow.com/a/71279467/2526464
extension UIBezierPath {
    // at first I thought this tests if point is inside path;
    // it actually tests if point is on the path itself (with some tolerance)
    func containsInsideBorder(_ pos: CGPoint, toleranceWidth: CGFloat = 2.0) -> Bool {
        let pathRef = cgPath.copy(strokingWithWidth: toleranceWidth, lineCap: CGLineCap.butt, lineJoin: CGLineJoin.round, miterLimit: 0)
        let pathRefMutable = pathRef.mutableCopy()
        if let p = pathRefMutable {
            p.closeSubpath()
            return p.contains(pos)
        }
        return false
    }
    
    // this tests if point is inside  path
    func containsInside(_ pos: CGPoint, toleranceWidth: CGFloat = 2.0) -> Bool {
        return contains(pos)
    }
}
