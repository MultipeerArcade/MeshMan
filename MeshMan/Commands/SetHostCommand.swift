//
//  SetHostCommand.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/29/19.
//  Copyright © 2019 Russell Pecka. All rights reserved.
//

import Foundation

struct SetHostCommand: CommandDescribable, Codable {
    
    let command: CommandType = .setHost
    
    let hostPeerIDData: Data
    
    init(hostData: Data) {
        hostPeerIDData = hostData
    }
    
}
