//
//  MCManager.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/28/17.
//  Copyright © 2017 Russell Pecka. All rights reserved.
//

import Foundation
import MultipeerConnectivity

internal class MCManager {
	
	static let serviceType = "hangman-mesh"
	
	internal private(set) static var shared: MCManager! = nil
	
	internal private(set) var session: MCSession
	
	internal var peerID: MCPeerID
	
	private var discoveryInfo: DiscoveryInfo
	
	private static var isSetUp = false
	
	internal static func setUpIfNeeded(with displayName: String) {
		guard !isSetUp else { print("MCManager was already set up"); return }
		self.shared = MCManager(with: displayName)
		isSetUp = true
	}
	
	init(with displayName: String) {
		self.peerID = MCPeerID(displayName: displayName)
		self.session = MCSession(peer: self.peerID)
		self.discoveryInfo = DiscoveryInfo(name: displayName)
	}
	
	internal func makeBrowser() -> MCNearbyServiceBrowser {
		return MCNearbyServiceBrowser(peer: self.peerID, serviceType: MCManager.serviceType)
	}
	
	internal func makeAdvertiser() -> MCNearbyServiceAdvertiser {
		return MCNearbyServiceAdvertiser(peer: self.peerID, discoveryInfo: nil /* self.discoveryInfo.dictionaryRepresentation */, serviceType: MCManager.serviceType)
	}
	
	internal func isThisMe(_ peer: MCPeerID) -> Bool {
		return peer == self.peerID
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
	
}
