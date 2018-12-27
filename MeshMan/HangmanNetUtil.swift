//
//  HangmanNetUtil.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/30/17.
//  Copyright © 2017 Russell Pecka. All rights reserved.
//

import Foundation
import MultipeerConnectivity

internal class HangmanNetUtil: NSObject, NetUtil {
	
	private enum MessageType {
		case choosingWord(WaitMessage)
		case startGame(StartGameMessage)
		case newGuess(NewGuessMessage)
	}
	
	internal struct StartGameMessage: Codable {
		internal let word: String
		internal let pickerData: Data
        
        var picker: MCPeerID { return MCPeerID.from(data: pickerData) }
		
		init(word: String, picker: MCPeerID) {
			self.word = word
			self.pickerData = picker.dataRepresentation
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
	
    let session: MCSession
	
	init(session: MCSession) {
		self.session = session
		super.init()
		self.session.delegate = self
	}
	
	// MARK: - Connection Events
	
	internal let peerConnectionStateChanged = Event<PeerConnectionState>()
	
	// MARK: - Message Events
	
	internal let waitMessageRecieved = Event<WaitMessage>()
	
	internal let startGameMessageRecieved = Event<StartGameMessage>()
	
	internal let newGuessRecieved = Event<NewGuessMessage>()
	
	// MARK: - MCSessionDelegate
	
	internal func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
		let messageType: MessageType?
		if let newGuessMessage = try? JSONDecoder().decode(NewGuessMessage.self, from: data) {
			messageType = .newGuess(newGuessMessage)
		} else if let choosingWordMessage = try? JSONDecoder().decode(WaitMessage.self, from: data)  {
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
                waitMessageRecieved.raise(sender: self, arguments: message)
			case .startGame(let message):
				self.startGameMessageRecieved.raise(sender: self, arguments: message)
			case .newGuess(let message):
				self.newGuessRecieved.raise(sender: self, arguments: message)
			}
		}
	}
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) { }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) { }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) { }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        self.peerConnectionStateChanged.raise(sender: self, arguments: (peerID, state))
    }
	
}
