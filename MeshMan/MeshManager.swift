//
//  MeshManager.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/24/17.
//  Copyright © 2017 Russell Pecka. All rights reserved.
//

import Foundation
import MultipeerConnectivity

internal class MeshManager: NSObject, MCSessionDelegate {
	
	private enum Constants {
		static let serviceType = "hangman-mesh"
	}
	
	internal private(set) static var shared: MeshManager!
	
	internal let session: MCSession
	
	internal let displayName: String
	
	private let peer: MCPeerID
	
	internal let browser: MCNearbyServiceBrowser
	
	private let advertiser: MCNearbyServiceAdvertiser
	
	internal var sessionStateChangeHandler: ((_ newState: MCSessionState) -> Void)?
	
	// MARK: - Initialization
	
	internal init(displayName: String) {
		self.displayName = displayName
		self.peer = MCPeerID(displayName: UIDevice.current.name)
		self.session = MCSession(peer: self.peer)
		self.browser = MCNearbyServiceBrowser(peer: self.peer, serviceType: Constants.serviceType)
		let discoveryInfo = DiscoveryInfo(name: displayName)
		self.advertiser = MCNearbyServiceAdvertiser(peer: self.peer, discoveryInfo: discoveryInfo.dictionaryRepresentation, serviceType: Constants.serviceType)
		super.init()
		self.session.delegate = self
	}
	
	// MARK: - Setup
	
	private static var isSetUp = false
	
	internal static func setUp(withName name: String) {
		guard !self.isSetUp else { print("The mesh manager was set up already!"); return }
		MeshManager.shared = MeshManager.init(displayName: name)
		self.isSetUp = true
	}
	
	// MARK: - MCSessionDelegate
	
	internal func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
		
	}
	
	internal func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
		
	}
	
	internal func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
		
	}
	
	internal func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
		
	}
	
	internal func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
		self.sessionStateChangeHandler?(state)
	}
	
	// MARK: - Discovery Info
	
	internal struct DiscoveryInfo {
		
		private enum Keys {
			static let nameKey = "name"
		}
		
		internal let name: String
		
		init(name: String) {
			self.name = name
		}
		
		init?(from dict: [String:Any]) {
			guard let name = dict[Keys.nameKey] as? String else { return nil }
			self.name = name
		}
		
		internal var dictionaryRepresentation: [String:String] {
			return [Keys.nameKey: self.name]
		}
		
	}
	
	// MARK: -
	
	internal class AdvertiserAmbassador: NSObject, MCNearbyServiceAdvertiserDelegate {
		
		private let didNotStartEvent: ((_ advertiser: MCNearbyServiceAdvertiser, _ error: Error) -> Void)?
		
		private let didRecieveInvitationEvent: (_ advertiser: MCNearbyServiceAdvertiser, _ peerID: MCPeerID, _ context: Data?, _ invitationHandler: @escaping (Bool, MCSession?) -> Void) -> Void
		
		init(didRecieveInvitationEvent: @escaping (_ advertiser: MCNearbyServiceAdvertiser, _ peerID: MCPeerID, _ context: Data?, _ invitationHandler: @escaping (Bool, MCSession?) -> Void) -> Void, didNotStartEvent: ((_ advertiser: MCNearbyServiceAdvertiser, _ error: Error) -> Void)? = nil) {
			self.didRecieveInvitationEvent = didRecieveInvitationEvent
			self.didNotStartEvent = didNotStartEvent
		}
		
		// MARK: - MCNearbyServiceAdvertiserDelegate
		
		internal func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
			self.didNotStartEvent?(advertiser, error)
		}
		
		internal func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
			self.didRecieveInvitationEvent(advertiser, peerID, context, invitationHandler)
		}
		
	}
	
	internal func startAdvertising(with ambassador: AdvertiserAmbassador) {
		self.advertiser.delegate = ambassador
		self.advertiser.startAdvertisingPeer()
	}
	
	internal func stopAdvertising() {
		self.advertiser.delegate = nil
		self.advertiser.stopAdvertisingPeer()
	}
	
}
