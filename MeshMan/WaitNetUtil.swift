//
//  WaitNetUtil.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/27/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class WaitNetUtil: NSObject, NetUtil {
    
    // MARK: - Types
    
    private enum MessageType {
        case waitMessage(WaitMessage)
        case startGame(StartMessage)
    }
    
    // MARK: - Events
    
    let peerConnectionStateChanged = Event<PeerConnectionState>()
    
    let waitMessageRecieved = Event<WaitMessage>()
    
    let startMessageRecieved = Event<StartMessage>()
    
    // MARK: - Internal Members
    
    let session: MCSession
    
    // MARK: - Initialization
    
    init(session: MCSession = MCManager.shared.session) {
        self.session = session
        super.init()
        self.session.delegate = self
    }
    
    // MARK: - MCSessionDelegate
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        peerConnectionStateChanged.raise(sender: self, arguments: (peer: peerID, state: state))
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let waitMessage = try? JSONDecoder().decode(WaitMessage.self, from: data) {
            waitMessageRecieved.raise(sender: self, arguments: waitMessage)
        } else if let startMessage = try? JSONDecoder().decode(StartMessage.self, from: data) {
            startMessageRecieved.raise(sender: self, arguments: startMessage)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) { }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) { }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) { }
    
}
