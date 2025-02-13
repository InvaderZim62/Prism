//
//  Extensions.swift
//  War
//
//  Created by Phil Stern on 7/26/22.
//

import UIKit

extension Double {
    // limit in place
    // usage: someDouble.limitBetween(-1, 1)
    mutating func limitBetween(_ minVal: Double, and maxVal: Double) {
        assert(minVal <= maxVal, "First argument must be less than second argument in call to limitBetween")
        self = min(max(self, minVal), maxVal)
    }
    
    // return limited value
    // usage: newDouble = someDouble.limitedBetween(-1, 1)
    func limitedBetween(_ minVal: Double, and maxVal: Double) -> Double {
        assert(minVal <= maxVal, "First argument must be less than second argument in call to limitedBetween")
        return min(max(self, minVal), maxVal)
    }
    
    var rads: Double {
        self * .pi / 180
    }
    
    var degs: Double {
        self * 180 / .pi
    }

    // converts angle to +/-pi
    var wrapPi: Double {
        var wrappedAngle = self
        if self > .pi {
            wrappedAngle -= 2 * .pi
        } else if self < -.pi {
            wrappedAngle += 2 * .pi
        }
        return wrappedAngle
    }
    
    // converts angle to 0 -> 2pi
    var wrap2Pi: Double {
        var wrappedAngle = self
        if self >= 2 * .pi {
            wrappedAngle -= 2 * .pi
        } else if self < 0 {
            wrappedAngle += 2 * .pi
        }
        return wrappedAngle
    }
}

extension CGFloat {
    mutating func limitBetween(_ minVal: CGFloat, and maxVal: CGFloat) {
        assert(minVal <= maxVal, "First argument must be less than second argument in call to limitBetween")
        self = Swift.min(Swift.max(self, minVal), maxVal)
    }
    
    var rads: CGFloat {
        self * .pi / 180
    }
    
    var degs: CGFloat {
        self * 180 / .pi
    }

    // converts angle to +/-pi
    var wrapPi: CGFloat {
        var wrappedAngle = self
        if self > .pi {
            wrappedAngle -= 2 * .pi
        } else if self < -.pi {
            wrappedAngle += 2 * .pi
        }
        return wrappedAngle
    }
    
    // converts angle to 0 -> 2pi
    var wrap2Pi: CGFloat {
        var wrappedAngle = self
        if self >= 2 * .pi {
            wrappedAngle -= 2 * .pi
        } else if self < 0 {
            wrappedAngle += 2 * .pi
        }
        return wrappedAngle
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

extension Array where Element == Double {
    var average: Double {
        self.reduce(0, +) / Double(self.count)
    }
}

extension Array where Element == Bool {
    var indexOfMiddleTrue: Int? {  // middle assuming array is circular
        let trueCount = self.count(where: { $0 } )
        guard trueCount > 0 else { return nil }
        if var index = self.firstIndex(where: { !$0 } ) {  // start at first false
            var numTrue = 0
            repeat {
                index = (index + 1) % self.count  // wrap around
                if self[index] { numTrue += 1 }
            } while numTrue < trueCount / 2
            return index
        } else {
            return nil
        }
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
