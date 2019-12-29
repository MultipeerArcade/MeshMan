//
//  MCManager.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/28/17.
//  Copyright © 2017 Russell Pecka. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol DataHandler: class {
    func process(data: Data)
}

protocol StatusHandler: class {
    func process(status: String)
}

protocol NetworkHandler: class {
    var turnHelper: TurnManager { get }
    func sendGameCommand(command: GameDataCommand)
}

class MCManager: NSObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, NetworkHandler {
    
    private enum Strings {
        static let waitingForInvite = NSLocalizedString("Waiting for a game invite...", comment: "Message that shows on the invite screen when the user is waiting to be invited to a game")
        static let invitationTitle = NSLocalizedString("New Invitation", comment: "Title for the alert that shows when someone invites you to join their lobby")
        static let invitationBody = NSLocalizedString("You have recieved an invitation from %@ to join their lobby.", comment: "Body of the message that shows when you recieve a game invite. %@ will be replaced with the name of the person sending the invitation")
        static let join = NSLocalizedString("Join", comment: "The title of the button on an invitation alert that accepts the invitation")
        static let ignore = NSLocalizedString("Ignore", comment: "The title of the button on an invitation alert that ignores the invitation")
        static let connecting = NSLocalizedString("Connecting...", comment: "Message to show on the wait screen when the user has accepted an invite and is connecting to another peer")
        static let connectionErrorTitle = NSLocalizedString("Connection Error", comment: "The title of the alert that shows when the user fails to connect to a peer")
        static let connectionErrorBody = NSLocalizedString("The connection could not be established. Please try again.", comment: "The message to show on the alert that is shown when the user fails to connect to a peer")
        static let waiting = NSLocalizedString("Waiting for the game to start...", comment: "Text to show when the user is waiting for the leader to start the game")
    }
	
	static let serviceType = "hangman-mesh"
	
	private(set) static var shared: MCManager! = nil
	
    let session: MCSession
	
    let peerID: MCPeerID
    
    let turnHelper: TurnManager
    
    private weak var dataHandler: DataHandler? = nil
    
    weak var statusHandler: StatusHandler? = nil
    
    private var advertiser: MCNearbyServiceAdvertiser!
    
    private var iAmAdvertising: Bool {
        return advertiser != nil
    }
	
	static func setUp(with peerID: MCPeerID) {
		self.shared = MCManager(with: peerID)
	}
	
	init(with peerID: MCPeerID) {
		self.peerID = peerID
        let session = MCSession(peer: self.peerID)
		self.session = session
        self.turnHelper = TurnManager(session: session, myPeerID: peerID)
        super.init()
        session.delegate = self
	}
	
	func makeBrowser() -> MCNearbyServiceBrowser {
		return MCNearbyServiceBrowser(peer: self.peerID, serviceType: MCManager.serviceType)
	}
	
	private func makeAdvertiser() -> MCNearbyServiceAdvertiser {
		return MCNearbyServiceAdvertiser(peer: self.peerID, discoveryInfo: nil, serviceType: MCManager.serviceType)
	}
	
	func isThisMe(_ peer: MCPeerID) -> Bool {
		return peer == self.peerID
	}
    
    func startAdvertising() {
        advertiser = makeAdvertiser()
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
    }
    
    func stopAdvertising() {
        advertiser.stopAdvertisingPeer()
        advertiser = nil
    }
    
    // MARK: - MCSessionDelegate
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        if iAmAdvertising {
            stopAdvertising()
            DispatchQueue.main.async {
                RootManager.shared.goToLobby(asHost: false)
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let commandMessage = try! JSONDecoder().decode(BaseCommand.self, from: data)
        switch commandMessage.command {
        case .setGame:
            let setGameCommand = try! JSONDecoder().decode(SetGameCommand.self, from: data)
            process(setGameCommand: setGameCommand)
        case .gameData:
            let gameDataCommand = try! JSONDecoder().decode(GameDataCommand.self, from: data)
            dataHandler?.process(data: gameDataCommand.payload)
        case .status:
            let statusCommand = try! JSONDecoder().decode(SetStatusCommand.self, from: data)
            statusHandler?.process(status: statusCommand.message)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    // MARK: - MCNearbyServiceAdvertiserDelegate
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Did not start andvertising")
    }
    
    internal func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        let displayName: String
        displayName = peerID.displayName
        self.showInvite(from: displayName, callback: { accepted in
            invitationHandler(accepted, MCManager.shared.session)
        })
    }
    
    // MARK: -
    
    private func process(setGameCommand: SetGameCommand) {
        switch setGameCommand.game {
        case .hangman:
            let gameState = try! JSONDecoder().decode(HangmanGameState.self, from: setGameCommand.payload)
            let hangman = makeHangman(state: gameState)
            DispatchQueue.main.async {
                let hangmanVC = HangmanViewController.newInstance(hangman: hangman)
                RootManager.shared.navigationController.setViewControllers([hangmanVC], animated: true)
            }
        case .twentyQuestions:
            let gameState = try! JSONDecoder().decode(QuestionsGameState.self, from: setGameCommand.payload)
            let questions = makeQuestions(state: gameState)
            DispatchQueue.main.async {
                if questions.iAmPicker {
                    let answerVC = AnswerViewController.newInstance(questions: questions)
                    RootManager.shared.navigationController.setViewControllers([answerVC], animated: true)
                } else {
                    let questionsVC = GuessViewController.newInstance(questions: questions)
                    RootManager.shared.navigationController.setViewControllers([questionsVC], animated: true)
                }
            }
        }
    }
    
    func setGame<PayloadType: Encodable>(game: Game, payload: PayloadType) {
        let payloadData = try! JSONEncoder().encode(payload)
        let command = SetGameCommand.init(game: game, payload: payloadData)
        let commandData = try! JSONEncoder().encode(command)
        try! session.send(commandData, toPeers: session.connectedPeers, with: .reliable)
    }
    
    // MARK: -
    
    func makeHangman(state: HangmanGameState) -> Hangman {
        let hangman = Hangman(state: state, networkHandler: self)
        dataHandler = hangman
        return hangman
    }
    
    func makeQuestions(state: QuestionsGameState) -> Questions {
        let questions = Questions(state: state, networkHandler: self)
        dataHandler = questions
        return questions
    }
    
    // MARK: -
    
    private func showInvite(from senderName: String, callback: @escaping (_ accepted: Bool) -> Void) {
        let alertView = UIAlertController(title: Strings.invitationTitle, message: String(format: Strings.invitationBody, senderName), preferredStyle: .alert)
        let joinAction = UIAlertAction(title: Strings.join, style: .default) { (_) in callback(true) }
        let ignoreAction = UIAlertAction(title: Strings.ignore, style: .default) { (_) in callback(false) }
        alertView.addAction(ignoreAction)
        alertView.addAction(joinAction)
        RootManager.shared.navigationController.present(alertView, animated: true)
    }
    
    // MARK: - NetworkHandler
    
    func sendGameCommand(command: GameDataCommand) {
        let gameDataCommandData = try! JSONEncoder().encode(command)
        try! session.send(gameDataCommandData, toPeers: session.connectedPeers, with: .reliable)
    }
	
}
