//
//  QuestionsTurnManager.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/26/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import Foundation
import MultipeerConnectivity

final class QuestionsTurnManager: TurnManager {

    // MARK: - Internal Members
    
    var iAmAsker: Bool {
        return currentAsker == myID
    }
    
    // MARK: - Private Members
    
    private var currentPicker: MCPeerID
    
    private lazy var currentAsker: MCPeerID = getFirstPeer(otherThan: [currentPicker])
    
    // MARK: - Initialization
    
    init(session: MCSession, myPeerID: MCPeerID, firstPicker: MCPeerID) {
        currentPicker = firstPicker
        super.init(session: session, myPeerID: myPeerID)
    }
    
    func pickNextAsker() {
        currentAsker = getPeer(after: currentAsker, otherThan: currentPicker)
    }
    
}
