//
//  WaitViewController.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/27/17.
//  Copyright © 2017 Russell Pecka. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class WaitViewController: UIViewController, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate {
	
	// MARK: - Outlets
	
	@IBOutlet private weak var statusLabel: UILabel!
	
	// MARK: -
	
	private enum Strings {
		static let invitationTitle = NSLocalizedString("New Invitation", comment: "Title for the alert that shows when someone invites you to join their lobby")
		static let invitationBody = NSLocalizedString("You have recieved an invitation from %@ to join their lobby.", comment: "Body of the message that shows when you recieve a game invite. %@ will be replaced with the name of the person sending the invitation")
		static let join = NSLocalizedString("Join", comment: "The title of the button on an invitation alert that accepts the invitation")
		static let ignore = NSLocalizedString("Ignore", comment: "The title of the button on an invitation alert that ignores the invitation")
		static let connecting = NSLocalizedString("Connecting...", comment: "Message to show on the wait screen when the user has accepted an invite and is connecting to another peer")
		static let connectionErrorTitle = NSLocalizedString("Connection Error", comment: "The title of the alert that shows when the user fails to connect to a peer")
		static let connectionErrorBody = NSLocalizedString("The connection could not be established. Please try again.", comment: "The message to show on the alert that is shown when the user fails to connect to a peer")
		static let waiting = NSLocalizedString("Waiting for the game to start...", comment: "Text to show when the user is waiting for the leader to start the game")
	}
	
	// MARK: - Properties
	
	internal var advertiser: MCNearbyServiceAdvertiser? {
		didSet { self.advertiser?.delegate = self }
	}
	
	// MARK: - ViewController Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		MCManager.shared.session.delegate = self
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.startAdvertising()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.stopAdvertising()
	}
	
	private func startAdvertising() {
		MCManager.shared.session.delegate = self
		self.advertiser?.startAdvertisingPeer()
	}
	
	private func stopAdvertising() {
		self.advertiser?.stopAdvertisingPeer()
	}
	
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
	
	// MARK: - MCSessionDelegate
	
	internal func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
		guard let message = try? JSONDecoder().decode(WelcomeViewController.GameStartMessage.self, from: data) else { return }
		DispatchQueue.main.async {
			guard let hangmanVC = Storyboards.hangman.instantiateInitialViewController() as? HangmanViewController else { return }
			hangmanVC.setUpHangman(with: message.word, leader: peerID)
			self.navigationController?.setViewControllers([hangmanVC], animated: true)
		}
	}
	
	internal func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
		
	}
	
	internal func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
		
	}
	
	internal func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
		
	}
	
	internal func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
		DispatchQueue.main.async {
			switch state {
			case .connecting:
				self.statusLabel.text = Strings.connecting
			case .notConnected:
				self.showConnectionFailureMessage()
			case .connected:
				self.statusLabel.text = Strings.waiting
			}
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
