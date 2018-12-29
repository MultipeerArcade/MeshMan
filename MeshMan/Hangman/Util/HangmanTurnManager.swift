//
//  HangmanTurnManager.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/31/17.
//  Copyright © 2017 Russell Pecka. All rights reserved.
//

import Foundation
import MultipeerConnectivity

final class HangmanTurnManager: TurnManager {
	
	init(session: MCSession, myPeerID: MCPeerID, firstPicker: MCPeerID) {
		super.init(session: session, myPeerID: myPeerID)
		self.currentPicker = firstPicker
		self.pickFirstGuesser()
	}
	
	// MARK: - Turn Management
	
	private var currentPicker: MCPeerID! {
		didSet { self.currentPickerChanged.raise(sender: self, arguments: (self.currentPicker == self.myID, self.currentPicker.displayName)) }
	}
	
	internal var currentPickerName: String {
		return self.currentPicker.displayName
	}
	
	private var currentGuesser: MCPeerID! {
		didSet { self.currentGuesserChanged.raise(sender: self, arguments: (self.currentGuesser == self.myID, self.currentGuesser.displayName)) }
	}
	
	internal var currentGuesserName: String {
		return self.currentGuesser.displayName
	}
	
	internal typealias RoleChangePayload = (isMe: Bool, name: String)
	
	internal let currentPickerChanged = Event<RoleChangePayload>()
	
	internal let currentGuesserChanged = Event<RoleChangePayload>()
	
	internal func set(picker newPicker: MCPeerID) {
		self.currentPicker = newPicker
	}
	
	internal var iAmPicker: Bool {
		return MCManager.shared.isThisMe(self.currentPicker)
	}
	
	private func pickFirstGuesser() {
		self.currentGuesser = self.getFirstPeer(otherThan: [self.currentPicker])
	}
	
	private func pickNextGuesser() {
		self.currentGuesser = self.getPeer(after: self.currentGuesser, otherThan: self.currentPicker)
	}
	
	internal enum Role {
		case picker, guesser, waiting
	}
	
	internal var myRole: Role {
		if self.myID == self.currentPicker {
			return .picker
		} else if self.myID == self.currentGuesser {
			return .guesser
		} else {
			return .waiting
		}
	}
	
	internal func pingEvents() {
		self.currentPickerChanged.raise(sender: self, arguments: (self.currentPicker == self.myID, self.currentPicker.displayName))
		self.currentGuesserChanged.raise(sender: self, arguments: (self.currentGuesser == self.myID, self.currentGuesser.displayName))
	}
	
	internal func turnCompleted() {
		self.pickNextGuesser()
	}
	
}