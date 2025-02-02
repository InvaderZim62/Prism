//
//  ViewController.swift
//  Prism
//
//  Created by Phil Stern on 2/1/25.
//

import UIKit

class ViewController: UIViewController {
        
    @IBOutlet weak var boardView: BoardView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
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
