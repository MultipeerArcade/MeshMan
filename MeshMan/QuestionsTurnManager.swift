//
//  QuestionsTurnManager.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/26/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import Foundation
import MultipeerConnectivity

final class QuestionsTurnManager {
    
    // MARK: - Private Members
    
    private let session: MCSession
    
    private let myID: MCPeerID
    
    private var currentPicker: MCPeerID
    
    // MARK: - Initialization
    
    init(session: MCSession, myPeerID: MCPeerID, firstPicker: MCPeerID) {
        self.session = session
        self.myID = myPeerID
        currentPicker = firstPicker
    }
    
}
