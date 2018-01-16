//
//  WaitViewController.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/27/17.
//  Copyright © 2017 Russell Pecka. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class WaitViewController: UIViewController, MCNearbyServiceAdvertiserDelegate {
	
	// MARK: - Outlets
	
	@IBOutlet private weak var statusLabel: UILabel!
	
	// MARK: -
	
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
		static let leaderChoosingWord = NSLocalizedString("Waiting for %@ to choose a word...", comment: "Status label message for when the leader is choosing the word in hangman")
	}
	
	// MARK: - Properties
	
	internal enum WaitPurpose {
		case joining(MCNearbyServiceAdvertiser), awaitingNewWord(pickerName: String)
	}
	
	internal var purpose: WaitPurpose!
	
	// MARK: - ViewController Lifecycle

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.setUp(for: self.purpose)
	}
	
	private func setUp(for purpose: WaitPurpose) {
		switch purpose {
		case .joining(let advertiser):
			self.statusLabel.text = Strings.waitingForInvite
			advertiser.delegate = self
			advertiser.startAdvertisingPeer()
		case .awaitingNewWord(pickerName: let pickerName):
			self.statusLabel.text = String(format: Strings.leaderChoosingWord, pickerName)
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.tearDown(for: self.purpose)
	}
	
	private func tearDown(for purpose: WaitPurpose) {
		switch purpose {
		case .joining(let advertiser):
			advertiser.stopAdvertisingPeer()
		case .awaitingNewWord:
			break
		}
	}
	
	// MARK: -
	
	private func showInvite(from senderName: String, callback: @escaping (_ accepted: Bool) -> Void) {
		let alertView = UIAlertController(title: Strings.invitationTitle, message: String(format: Strings.invitationBody, senderName), preferredStyle: .alert)
		let joinAction = UIAlertAction(title: Strings.join, style: .default) { (_) in callback(true) }
		let ignoreAction = UIAlertAction(title: Strings.ignore, style: .default) { (_) in callback(false) }
		alertView.addAction(ignoreAction)
		alertView.addAction(joinAction)
		self.present(alertView, animated: true)
	}
	
	private func showConnectionFailureMessage() {
		let alertView = UIAlertController(title: Strings.connectionErrorTitle, message: Strings.connectionErrorBody, preferredStyle: .alert)
		alertView.addAction(UIAlertAction(title: VisibleStrings.Generic.okay, style: .default, handler: { [weak self] (_) in self?.navigationController?.popViewController(animated: true) }))
		self.present(alertView, animated: true)
	}
	
	private func showGame(with word: String, firstPicker: MCPeerID) {
		guard let hangmanVC = Storyboards.hangman.instantiateInitialViewController() as? HangmanViewController else { return }
		let turnManager = HangmanTurnManager(session: MCManager.shared.session, myPeerID: MCManager.shared.peerID, firstPicker: firstPicker)
		hangmanVC.turnManager = turnManager
		hangmanVC.setUpHangman(with: word)
		hangmanVC.hangmanNetUtil = self.hangmanNetUtil
		self.navigationController?.setViewControllers([hangmanVC], animated: true)
	}
	
	// MARK: -
	
	internal var hangmanNetUtil: HangmanNetUtil! {
		didSet {
			if let netUtil = self.hangmanNetUtil { self.setUp(netUtil: netUtil) }
		}
	}
	
	private var peerConnectionStateChangedHandle: Event<HangmanNetUtil.PeerConnectionState>.Handle?
	
	private var choosingWordMessageRecievedHandle: Event<HangmanNetUtil.ChoosingWordMessage>.Handle?
	
	private var startGameMessageRecievedHandle: Event<HangmanNetUtil.StartGameMessage>.Handle?
	
	private func setUp(netUtil: HangmanNetUtil) {
		self.peerConnectionStateChangedHandle = self.hangmanNetUtil.peerConnectionStateChanged.subscribe({ [weak self] (_, payload) in self?.handle(peer: payload.peer, changedStateTo: payload.state) })
		self.choosingWordMessageRecievedHandle = self.hangmanNetUtil.choosingWordMessageRecieved.subscribe({ [weak self] (_, message) in self?.statusLabel.text = String(format: Strings.leaderChoosingWord, message.pickerName) })
		self.startGameMessageRecievedHandle = self.hangmanNetUtil.startGameMessageRecieved.subscribe({ [weak self] (_, message) in
			self?.showGame(with: message.word, firstPicker: message.picker)
		})
	}
	
	private func handle(peer: MCPeerID, changedStateTo state: MCSessionState) {
		switch state {
		case .connecting:
			self.statusLabel.text = Strings.connecting
		case .notConnected:
			self.showConnectionFailureMessage()
		case .connected:
			self.statusLabel.text = Strings.waiting
		}
	}
	
	// MARK: - MCNearbyServiceAdvertiserDelegate
	
	internal func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
		print("Did not start andvertising")
	}
	
	internal func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
		let displayName: String
		//		if let context = context, let serializedData = try? JSONSerialization.jsonObject(with: context, options: []), let json = serializedData as? [String:Any], let discoveryInfo = MCManager.DiscoveryInfo(from: json) {
		//			displayName = discoveryInfo.name
		//		} else {
		displayName = peerID.displayName
		//		}
		self.showInvite(from: displayName, callback: { accepted in
			invitationHandler(accepted, MCManager.shared.session)
		})
	}

}
