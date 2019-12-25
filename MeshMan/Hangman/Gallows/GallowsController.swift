//
//  GallowsController.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/28/17.
//  Copyright © 2017 Russell Pecka. All rights reserved.
//

import UIKit

class GallowsController: UIViewController {
	
	// MARK: - Outlets
	
    @IBOutlet private weak var imageView: UIImageView!
	
	// MARK: -
	
	private var imageNumber = 0
	
	internal func reset() {
		self.imageView.image = nil
		self.imageNumber = 0
	}
	
	internal func next() {
		self.imageNumber += 1
        let image = UIImage(named: "HangMan\(imageNumber)")?.withTintColor(Assets.gallowsColor, renderingMode: .automatic)
		self.imageView.image = image
	}

}
