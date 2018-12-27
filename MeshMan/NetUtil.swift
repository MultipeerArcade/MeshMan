//
//  NetUtil.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/27/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import Foundation
import MultipeerConnectivity

typealias PeerConnectionState = (peer: MCPeerID, state: MCSessionState)

struct WaitMessage: Codable {
    let message: String
    
    init(message: String) {
        self.message = message
    }
}

protocol NetUtil: MCSessionDelegate {
    var peerConnectionStateChanged: Event<PeerConnectionState> { get }
    var waitMessageRecieved: Event<WaitMessage> { get }
    
    var session: MCSession { get }
}

extension NetUtil {
    
    func send<T: Encodable>(message: T) {
        guard let encodedData = try? JSONEncoder().encode(message) else { return }
        try? self.session.send(encodedData, toPeers: self.session.connectedPeers, with: .reliable)
    }
    
}
