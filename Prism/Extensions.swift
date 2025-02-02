//
//  Extensions.swift
//  War
//
//  Created by Phil Stern on 7/26/22.
//

import UIKit

extension Double {
    mutating func limitBetween(_ minVal: Double, and maxVal: Double) {
        assert(minVal <= maxVal, "First argument must be less than second argument in call to limitBetween")
        self = min(max(self, minVal), maxVal)
    }
    
    var rads: Double {
        return self * Double.pi / 180.0
    }

    // converts angle from +/-2 pi to +/-pi
    var wrapPi: Double {
        var wrappedAngle = self
        if self > Double.pi {
            wrappedAngle -= 2 * Double.pi
        } else if self < -Double.pi {
            wrappedAngle += 2 * Double.pi
        }
        return wrappedAngle
    }
}

extension CGFloat {
    mutating func limitBetween(_ minVal: CGFloat, and maxVal: CGFloat) {
        assert(minVal <= maxVal, "First argument must be less than second argument in call to limitBetween")
        self = Swift.min(Swift.max(self, minVal), maxVal)
    }
}

extension CGPoint {
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func -(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    static func +=(lhs: inout CGPoint, rhs: CGPoint) {
        lhs = lhs + rhs
    }

    func offsetBy(dx: CGFloat, dy: CGFloat) -> CGPoint {
        return CGPoint(x: x + dx, y: y + dy)
    }
}

extension TimeInterval {
    var second: Int {
        Int(truncatingRemainder(dividingBy: 60))
    }
    
    var millisecond: Int {
        Int((self * 1000).truncatingRemainder(dividingBy: 1000))
    }
}
