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

enum GameType: String, Codable {
    case hangman
    case questions
}

struct WaitMessage: Codable {
    let message: String
    
    init(message: String) {
        self.message = message
    }
}

struct StartMessage: Codable {
    let gameType: GameType
    let payload: Data?
    
    init(gameType: GameType, payloadData: Data? = nil) {
        self.gameType = gameType
        self.payload = payloadData
    }
    
    init<PayloadType: Encodable>(gameType: GameType, payload: PayloadType) {
        self.init(gameType: gameType, payloadData: try! JSONEncoder().encode(payload))
    }
}

protocol NetUtil: MCSessionDelegate {
    var peerConnectionStateChanged: Event<PeerConnectionState> { get }
    var waitMessageRecieved: Event<WaitMessage> { get }
    var startMessageRecieved: Event<StartMessage> { get }
    
    var session: MCSession { get }
}

extension NetUtil {
    
    func send<T: Encodable>(message: T) {
        guard let encodedData = try? JSONEncoder().encode(message) else { return }
        try? self.session.send(encodedData, toPeers: self.session.connectedPeers, with: .reliable)
    }
    
}
