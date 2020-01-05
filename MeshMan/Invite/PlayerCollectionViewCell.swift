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
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    func configure(with name: String, color: UIColor, stage: InviteStage?) {
        self.layer.cornerRadius = 10
        self.layer.masksToBounds = true
        self.nameLabel.text = name
        self.backgroundColor = color
        if let stage = stage {
            switch stage {
            case .accepted:
                statusLabel.text = "Accepted"
                statusLabel.isHidden = false
                activityIndicator.stopAnimating()
            case .connecting:
                statusLabel.text = "Connecting"
                statusLabel.isHidden = false
                activityIndicator.startAnimating()
            case .declined:
                statusLabel.text = "Declined"
                statusLabel.isHidden = false
                activityIndicator.stopAnimating()
            case .invited:
                statusLabel.text = "Invited"
                statusLabel.isHidden = false
                activityIndicator.startAnimating()
            }
        } else {
            statusLabel.isHidden = true
            activityIndicator.stopAnimating()
        }
    }
    
}
