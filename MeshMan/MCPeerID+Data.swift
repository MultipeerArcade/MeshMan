//
//  MCPeerID+Data.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/27/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import Foundation
import MultipeerConnectivity

extension MCPeerID {
    
    var dataRepresentation: Data {
        return NSKeyedArchiver.archivedData(withRootObject: self)
    }
    
    static func from(data: Data) -> MCPeerID {
        return NSKeyedUnarchiver.unarchiveObject(with: data) as! MCPeerID
    }
    
}
