//
//  TurnManager.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/27/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class TurnManager {
    
    // MARK: - Internal Members
    
    let session: MCSession
    
    let myID: MCPeerID
    
    // MARK: - Private Members
    
    private var sortedAllPeers: [MCPeerID] {
        var peers = self.session.connectedPeers
        peers.append(self.myID)
        return peers.sorted(by: { $0.hashValue <= $1.hashValue })
    }
    
    // MARK: - Initialization
    
    init(session: MCSession, myPeerID: MCPeerID) {
        self.session = session
        self.myID = myPeerID
    }
    
    // MARK: - Picking Peers
    
    func getFirstPeer(otherThan unwanted: [MCPeerID]) -> MCPeerID {
        for peer in self.sortedAllPeers {
            for unwantedPeer in unwanted {
                if peer != unwantedPeer {
                    return peer
                }
            }
        }
        fatalError()
    }
    
    func getPeer(after afterPeer: MCPeerID) -> MCPeerID {
        let sortedPeers = self.sortedAllPeers
        guard sortedPeers.count > 1 else { fatalError() }
        guard let index = sortedPeers.index(of: afterPeer) else { fatalError() }
        let nextIndex = sortedPeers.index(after: index)
        if nextIndex < sortedPeers.endIndex {
            return sortedPeers[nextIndex]
        } else {
            return sortedPeers[0]
        }
    }
    
    func getPeer(after afterPeer: MCPeerID, otherThan unwanted: MCPeerID) -> MCPeerID {
        var currentPeer = afterPeer
        repeat {
            currentPeer = self.getPeer(after: currentPeer)
        } while currentPeer == unwanted
        return currentPeer
    }
    
    func getPeerAfterMe(otherThan unwanted: MCPeerID) -> MCPeerID {
        return getPeer(after: myID, otherThan: unwanted)
    }
    
}
