//
//  InviteHeaderView.swift
//  MeshMan
//
//  Created by Russell Pecka on 1/5/20.
//  Copyright © 2020 Russell Pecka. All rights reserved.
//

import UIKit

class InviteHeaderView: UICollectionReusableView {
    
    static let reuseIndetifier = "inviteHeader"
        
    @IBOutlet private weak var titleLabel: UILabel!
    
    func configure(withTitle title: String) {
        titleLabel.text = title
    }
    
}
