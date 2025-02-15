//
//  ViewController.swift
//  Prism
//
//  Created by Phil Stern on 2/1/25.
//

import UIKit

class ViewController: UIViewController {
        
    @IBOutlet weak var boardView: BoardView!
    @IBOutlet weak var safeView: UIView!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        boardView.safeView = safeView  // used to prevent panning objects off screen
        boardView.setNeedsDisplay()
    }
}
