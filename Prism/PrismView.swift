//
//  PrismView.swift
//  Prism
//
//  Created by Phil Stern on 2/13/25.
//
//  Precompute the angles to the vertices and surface normal directions. Return surface normal
//  direction for a position around the prism, based on which which vertices a line to the
//  position falls between.
//

import UIKit

enum PrismType {
    case triangle, rectangle, mirror
}

class PrismView: UIView {
    
    var type = PrismType.triangle  // default
    
    var rotation: Double {
        atan2(self.transform.b, self.transform.a)
    }
    
    private let id = UUID()

    static func ==(lhs: PrismView, rhs: PrismView) -> Bool {
        lhs.id == rhs.id
    }

    //--------------------------------------------------------//
    // specify points clockwise starting from right of center //
    //--------------------------------------------------------//
    private lazy var vertices: [CGPoint] = {
        switch type {
        case .triangle:
            return [CGPoint(x: bounds.width - 1, y: bounds.height - 1),
                    CGPoint(x: 1, y: bounds.height - 1),
                    CGPoint(x: bounds.midX, y: 1)]
        case .rectangle:
            return [CGPoint(x: (1 + Constant.rectangleWidthPercent) / 2 * bounds.width - 1, y: bounds.height - 1),
                    CGPoint(x: (1 - Constant.rectangleWidthPercent) / 2 * bounds.width + 1, y: bounds.height - 1),
                    CGPoint(x: (1 - Constant.rectangleWidthPercent) / 2 * bounds.width + 1, y: 1),
                    CGPoint(x: (1 + Constant.rectangleWidthPercent) / 2 * bounds.width - 1, y: 1)]
        case .mirror:
            return [CGPoint(x: (1 + Constant.mirrorWidthPercent) / 2 * bounds.width - 1, y: bounds.height - 1),
                    CGPoint(x: (1 - Constant.mirrorWidthPercent) / 2 * bounds.width + 1, y: bounds.height - 1),
                    CGPoint(x: (1 - Constant.mirrorWidthPercent) / 2 * bounds.width + 1, y: 1),
                    CGPoint(x: (1 + Constant.mirrorWidthPercent) / 2 * bounds.width - 1, y: 1)]
        }
    }()
    
    private lazy var viewCenter = CGPoint(x: bounds.midX, y: bounds.midY)
    
    // from 0 -> 2pi
    private lazy var anglesFromCenterToVertices: [Double] = {
        var angles = [Double]()
        for vertex in vertices {
            let angleFromCenter = atan2(vertex.y - viewCenter.y, vertex.x - viewCenter.x)
            angles.append(angleFromCenter.wrap2Pi)
        }
        return angles
    }()
    
    // direction of surface normals pointing inside (one for each face)
    private lazy var surfaceNormalDirections: [Double] = {
        var directions = [Double]()
        let closedVertices = [vertices.last!] + vertices
        for index in 0..<closedVertices.count - 1 {
            let direction = -atan2(closedVertices[index].x - closedVertices[index + 1].x, closedVertices[index].y - closedVertices[index + 1].y)
            directions.append(direction)
        }
        return directions
    }()
    
    func directionOfSurfaceNormalAt(angle: Double) -> Double {
        for (index, vertexAngle) in anglesFromCenterToVertices.enumerated() {
            let localAngle = (angle - rotation).wrap2Pi
            if localAngle < vertexAngle {
                return (surfaceNormalDirections[index] + rotation).wrapPi
            }
        }
        return (surfaceNormalDirections[0] + rotation).wrapPi
    }

    // stand-alone path variable used by superview's draw function to determine which light points are inside the prism;
    // make it a property closure, so it only get computed once (shape doesn't change)
    lazy var path: UIBezierPath = {
        let shape = UIBezierPath()
        for index in vertices.indices {
            if index == 0 {
                shape.move(to: vertices[index])
            } else {
                shape.addLine(to: vertices[index])
            }
        }
        shape.close()
        return shape
    }()
    
    override func draw(_ rect: CGRect) {
        switch type {
        case .mirror:
            path.lineWidth = 2
            UIColor.lightGray.setStroke()
            path.stroke()
            UIColor.black.setFill()
            path.fill()
        default:
            path.lineWidth = 1
            UIColor.cyan.setStroke()
            path.stroke()
        }
    }
}
