//
//  AdvertiserDummy.swift
//  MeshManUITests
//
//  Created by Russell Pecka on 12/30/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import XCTest

class AdvertiserDummy: NSObject, MCNearbyServiceAdvertiserDelegate {
    
    // MARK: - Internal Members
    
    let acceptFrom: String
    
    let peerID: MCPeerID
    
    let expectation: XCTestExpectation?
    
    let session: MCSession
    
    lazy var advertiser: MCNearbyServiceAdvertiser = {
        let adv = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: MCManager.serviceType)
        adv.delegate = self
        return adv
    }()
    
    // MARK: -
    
    init(displayName: String, acceptFrom: String, expectation: XCTestExpectation?) {
        self.acceptFrom = acceptFrom
        self.peerID = MCPeerID(displayName: displayName)
        self.expectation = expectation
        self.session = MCSession(peer: peerID)
    }
    
    deinit {
        self.advertiser.stopAdvertisingPeer()
    }
    
    // MARK: - MCNearbyServiceAdvertiserDelegate
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(peerID.displayName == acceptFrom, session)
        expectation?.fulfill()
    }
    
}
