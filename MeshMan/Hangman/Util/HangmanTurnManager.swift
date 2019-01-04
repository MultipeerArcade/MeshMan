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
	
	private var currentPicker: MCPeerID!
	
	internal var currentPickerName: String {
		return self.currentPicker.displayName
	}
	
	private var currentGuesser: MCPeerID!
	
	internal var currentGuesserName: String {
		return self.currentGuesser.displayName
	}
	
	internal func set(picker newPicker: MCPeerID) {
		self.currentPicker = newPicker
	}
	
	internal var iAmPicker: Bool {
		return MCManager.shared.isThisMe(self.currentPicker)
	}
    
    var iAmGuesser: Bool {
        return MCManager.shared.isThisMe(currentGuesser)
    }
	
	private func pickFirstGuesser() {
		self.currentGuesser = self.getFirstPeer(otherThan: [self.currentPicker])
	}
	
	func pickNextGuesser() {
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
	
}
