//
//  WaitViewController.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/27/17.
//  Copyright © 2017 Russell Pecka. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class WaitViewController: UIViewController {
	
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
		static let okay = NSLocalizedString("Okay", comment: "The button title for when the user is acting in the affirmative")
	}
	
	// MARK: - ViewController Lifecycle

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.configureSessionStateListeners()
		self.startAdvertising()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.stopAdvertising()
	}
	
	private var advertiserAmbassador: MeshManager.AdvertiserAmbassador?
	
	private func startAdvertising() {
		let ambassador = MeshManager.AdvertiserAmbassador.init(didRecieveInvitationEvent: { [weak self] in self?.advertiser($0, didReceiveInvitationFromPeer: $1, withContext: $2, invitationHandler: $3) }, didNotStartEvent: { [weak self] in self?.advertiser($0, didNotStartAdvertisingPeer: $1) })
		self.advertiserAmbassador = ambassador
		MeshManager.shared.startAdvertising(with: ambassador)
	}
	
	private func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
		print("Did not start andvertising")
	}
	
	private func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
		let displayName: String
		if let context = context, let serializedData = try? JSONSerialization.jsonObject(with: context, options: []), let json = serializedData as? [String:Any], let discoveryInfo = MeshManager.DiscoveryInfo(from: json) {
			displayName = discoveryInfo.name
		} else {
			displayName = peerID.displayName
		}
		self.showInvite(from: displayName, callback: { accepted in
			invitationHandler(accepted, MeshManager.shared.session)
		})
	}
	
	private func stopAdvertising() {
		self.advertiserAmbassador = nil
		MeshManager.shared.stopAdvertising()
	}
	
	private func showInvite(from senderName: String, callback: @escaping (_ accepted: Bool) -> Void) {
		let alertView = UIAlertController(title: Strings.invitationTitle, message: String(format: Strings.invitationBody, senderName), preferredStyle: .alert)
		let joinAction = UIAlertAction(title: Strings.join, style: .default) { (_) in callback(true) }
		let ignoreAction = UIAlertAction(title: Strings.ignore, style: .default) { (_) in callback(false) }
		alertView.addAction(ignoreAction)
		alertView.addAction(joinAction)
		self.present(alertView, animated: true)
	}
	
	private func configureSessionStateListeners() {
		MeshManager.shared.sessionStateChangeHandler = { [weak self] newState in self?.sessionStateDidChange(to: newState) }
	}
	
	private func sessionStateDidChange(to newState: MCSessionState) {
		DispatchQueue.main.async {
			switch newState {
			case .connecting:
				self.statusLabel.text = Strings.connecting
			case .notConnected:
				self.showConnectionFailureMessage()
			case .connected:
				self.showGame()
			}
		}
	}
	
	private func showConnectionFailureMessage() {
		let alertView = UIAlertController(title: Strings.connectionErrorTitle, message: Strings.connectionErrorBody, preferredStyle: .alert)
		alertView.addAction(UIAlertAction(title: Strings.okay, style: .default, handler: { [weak self] (_) in self?.navigationController?.popViewController(animated: true) }))
		self.present(alertView, animated: true)
	}
	
	private func showGame() {
		print("yay")
	}
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
