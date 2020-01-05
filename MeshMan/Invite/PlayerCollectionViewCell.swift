//
//  PlayerCollectionViewCell.swift
//  MeshMan
//
//  Created by Russell Pecka on 1/5/20.
//  Copyright © 2020 Russell Pecka. All rights reserved.
//

import UIKit

class PlayerCollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier = "playerCell"
    
    @IBOutlet private weak var nameLabel: UILabel!
    
    func configure(with name: String, color: UIColor) {
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        self.nameLabel.text = name
        self.backgroundColor = color
    }
    
}
