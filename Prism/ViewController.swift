//
//  ViewController.swift
//  Prism
//
//  Created by Phil Stern on 2/1/25.
//
//  To allow simultaneous pan and rotate gestures:
//  - add UIGestureRecognizerDelegate to class definition (see extension)
//  - add func gestureRecognizer(shouldRecognizeSimultaneouslyWith:)
//  - set gesture delegates to self
//

import UIKit

protocol Selectable: UIView {  // for PrismView and LightSourceView
    var id: UUID { get }
    var isSelected: Bool { get set }
}

extension Selectable {
    func isEqual(to rhs: some Selectable) -> Bool {
        id == rhs.id
    }
}

class ViewController: UIViewController {
        
    var currentlySelectedObject: Selectable?

    @IBOutlet weak var boardView: BoardView!
    @IBOutlet weak var safeView: UIView!  // use to limit panning of prisms
    
    // MARK: -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addLightSourceAndPrismViews()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tap)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        pan.delegate = self  // needed for gestureRecognizer(_:shouldRecognizeSimultaneouslyWith:)
        view.addGestureRecognizer(pan)
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation))
        rotation.delegate = self
        view.addGestureRecognizer(rotation)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        boardView.setNeedsDisplay()
    }
    
    private func addLightSourceAndPrismViews() {
        addLightSourceView(center: CGPoint(x: 109, y: 124), rotation: -20.rads)  // setup last, so it's on top
        
        addPrismView(prismType: .triangle,
                     center: CGPoint(x: 233, y: 102),
                     width: Constant.triangleBaseLength,
                     height: Constant.triangleBaseLength * sin(60.rads),
                     rotation: 0)
        addPrismView(prismType: .triangle,
                     center: CGPoint(x: 261, y: 297),
                     width: Constant.triangleBaseLength,
                     height: Constant.triangleBaseLength * sin(60.rads),
                     rotation: 180.rads)
        addPrismView(prismType: .rectangle,
                     center: CGPoint(x: 433, y: 261),
                     width: Constant.rectangleSize,
                     height: Constant.rectangleSize,
                     rotation: 0)
        addPrismView(prismType: .mirror,
                     center: CGPoint(x: 602, y: 209),
                     width: Constant.rectangleSize,
                     height: Constant.rectangleSize,
                     rotation: 0)
    }

    private func addLightSourceView(center: CGPoint, rotation: Double) {
        boardView.lightSourceView.bounds.size = CGSize(width: Constant.lightSourceSideLength, height: Constant.lightSourceSideLength)
        boardView.lightSourceView.center = center
        boardView.lightSourceView.transform = boardView.lightSourceView.transform.rotated(by: rotation)
        boardView.lightSourceView.backgroundColor = .clear
        boardView.addSubview(boardView.lightSourceView)
    }

    private func addPrismView(prismType: PrismType, center: CGPoint, width: Double, height: Double, rotation: Double) {
        let prismView = PrismView()
        prismView.type = prismType
        prismView.center = center
        prismView.bounds.size = CGSize(width: width, height: height)
        prismView.transform = prismView.transform.rotated(by: rotation)
        prismView.backgroundColor = .clear
        boardView.prismViews.append(prismView)
        boardView.addSubview(prismView)
    }

    // MARK: - Gestures handlers
    
    // toggle selected object
    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: view)
        if let selectableObject = boardView.hitTest(location, with: nil) as? Selectable {  // nil since not called from touchesBegan(touches:event:)
            // object tapped - toggle selection
            selectableObject.isSelected.toggle()
            if let currentlySelectedObject, !currentlySelectedObject.isEqual(to: selectableObject) {
                // different object selected - deselect previous
                currentlySelectedObject.isSelected = false
            }
            currentlySelectedObject = selectableObject.isSelected ? selectableObject : nil
        } else {
            // open space tapped - deselect any object
            currentlySelectedObject?.isSelected = false
            currentlySelectedObject = nil
        }
    }
    
    // pan selected object
    @objc func handlePan(recognizer: UIPanGestureRecognizer) {
        if let currentlySelectedObject {
            let translation = recognizer.translation(in: view)
            currentlySelectedObject.center = (currentlySelectedObject.center + translation).limitedToView(safeView)
            recognizer.setTranslation(.zero, in: view)
            boardView.setNeedsDisplay()
        } else {
            
        }
    }
    
    // rotate select object
    @objc func handleRotation(recognizer: UIRotationGestureRecognizer) {
        if let currentlySelectedObject {
            let rotation = recognizer.rotation
            currentlySelectedObject.transform = currentlySelectedObject.transform.rotated(by: rotation)
            recognizer.rotation = 0  // reset, to use incremental rotations
            boardView.setNeedsDisplay()
        }
    }
}

extension ViewController: UIGestureRecognizerDelegate {
    // allow simultaneous pan and rotate gestures
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIPanGestureRecognizer || gestureRecognizer is UIRotationGestureRecognizer {
            return true
        } else {
            return false
        }
    }
}
