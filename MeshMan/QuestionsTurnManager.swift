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
    
    var iAmPicker: Bool {
        return currentPicker == myID
    }
    
    private(set) var currentPicker: MCPeerID
    
    private(set) lazy var currentAsker: MCPeerID = getFirstPeer(otherThan: [currentPicker])
    
    // MARK: - Private Members
    
    // MARK: - Initialization
    
    init(session: MCSession, myPeerID: MCPeerID, firstPicker: MCPeerID) {
        currentPicker = firstPicker
        super.init(session: session, myPeerID: myPeerID)
    }
    
    func pickNextAsker() {
        currentAsker = getPeer(after: currentAsker, otherThan: currentPicker)
    }
    
    func gameOver() {
        currentPicker = getPeer(after: currentPicker)
        currentAsker = getPeer(after: currentPicker)
    }
    
}
