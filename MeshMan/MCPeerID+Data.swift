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
        return try! NSKeyedArchiver.archivedData(withRootObject: self, requiringSecureCoding: false)
    }
    
    static func from(data: Data) -> MCPeerID {
        return try! NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: data)!
    }
    
}
