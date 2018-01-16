//
//  HangmanNetUtil.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/30/17.
//  Copyright © 2017 Russell Pecka. All rights reserved.
//

import Foundation
import MultipeerConnectivity

internal class HangmanNetUtil: NSObject, MCSessionDelegate {
	
	private enum MessageType {
		case choosingWord(ChoosingWordMessage)
		case startGame(StartGameMessage)
		case newGuess(NewGuessMessage)
	}
	
	internal struct ChoosingWordMessage: Codable {
		
		internal let pickerName: String
		
		init(pickerName: String) {
			self.pickerName = pickerName
		}
		
	}
	
	internal struct StartGameMessage: Codable {
		internal let word: String
		internal let picker: MCPeerID
		
		private enum CodingKeys: String, CodingKey {
			case word
			case picker
		}
		
		init(word: String, picker: MCPeerID) {
			self.word = word
			self.picker = picker
		}
		
		init(from decoder: Decoder) throws {
			let values = try decoder.container(keyedBy: CodingKeys.self)
			let word = try values.decode(String.self, forKey: .word)
			let pickerData = try values.decode(Data.self, forKey: .picker)
			let picker = NSKeyedUnarchiver.unarchiveObject(with: pickerData) as! MCPeerID
			self.init(word: word, picker: picker)
		}
		
		internal func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(self.word, forKey: .word)
			let pickerData = NSKeyedArchiver.archivedData(withRootObject: self.picker)
			try container.encode(pickerData, forKey: .picker)
		}
		
	}
	
	internal struct NewGuessMessage: Codable {
		internal let guess: String
		internal let sender: MCPeerID
		
		init(guess: String, sender: MCPeerID) {
			self.guess = guess
			self.sender = sender
		}
		
		// MARK: - Codable
		
		private enum CodingKeys: CodingKey {
			case guess, sender
		}
		
		internal func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(self.guess, forKey: .guess)
			let peerData = NSKeyedArchiver.archivedData(withRootObject: self.sender)
			try container.encode(peerData, forKey: .sender)
		}
		
		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			self.guess = try container.decode(String.self, forKey: .guess)
			let peerData = try container.decode(Data.self, forKey: .sender)
			guard let sender = NSKeyedUnarchiver.unarchiveObject(with: peerData) as? MCPeerID else {
				throw DecodingError.typeMismatch(MCPeerID.self, DecodingError.Context.init(codingPath: container.codingPath, debugDescription: "Could not get the MCPeerID from the sender field"))
			}
			self.sender = sender
		}
		
	}
	
	private let session: MCSession
	
	init(session: MCSession) {
		self.session = session
		super.init()
		self.session.delegate = self
	}
	
	internal func sendChoosingWordMessage(_ message: ChoosingWordMessage) {
		guard let encodedData = try? JSONEncoder().encode(message) else { return }
		try? self.session.send(encodedData, toPeers: self.session.connectedPeers, with: .reliable)
	}
	
	internal func sendStartGameMessage(_ message: StartGameMessage) {
		guard let encodedData = try? JSONEncoder().encode(message) else { return }
		try? self.session.send(encodedData, toPeers: self.session.connectedPeers, with: .reliable)
	}
	
	internal func sendNewGuessMessage(_ message: NewGuessMessage) {
		guard let encodedData = try? JSONEncoder().encode(message) else { assertionFailure("Could not encode the new guess message"); return }
		try? self.session.send(encodedData, toPeers: self.session.connectedPeers, with: .reliable)
	}
	
	// MARK: - Connection Events
	
	internal typealias PeerConnectionState = (peer: MCPeerID, state: MCSessionState)
	
	internal let peerConnectionStateChanged = Event<PeerConnectionState>()
	
	// MARK: - Message Events
	
	internal let choosingWordMessageRecieved = Event<ChoosingWordMessage>()
	
	internal let startGameMessageRecieved = Event<StartGameMessage>()
	
	internal let newGuessRecieved = Event<NewGuessMessage>()
	
	// MARK: - MCSessionDelegate
	
	internal func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
		let messageType: MessageType?
		if let newGuessMessage = try? JSONDecoder().decode(NewGuessMessage.self, from: data) {
			messageType = .newGuess(newGuessMessage)
		} else if let choosingWordMessage = try? JSONDecoder().decode(ChoosingWordMessage.self, from: data)  {
			messageType = .choosingWord(choosingWordMessage)
		} else if let startGameMessage = try? JSONDecoder().decode(StartGameMessage.self, from: data) {
			messageType = .startGame(startGameMessage)
		} else {
			messageType = nil
		}
		switch messageType {
		case .none:
			return
		case .some(let ambigMessage):
			switch ambigMessage {
			case .choosingWord(let message):
				self.choosingWordMessageRecieved.raise(sender: self, arguments: message)
			case .startGame(let message):
				self.startGameMessageRecieved.raise(sender: self, arguments: message)
			case .newGuess(let message):
				self.newGuessRecieved.raise(sender: self, arguments: message)
			}
		}
	}
	
	internal func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
		
	}
	
	internal func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
		
	}
	
	internal func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
		
	}
	
	internal func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
		self.peerConnectionStateChanged.raise(sender: self, arguments: (peerID, state))
	}
	
}
