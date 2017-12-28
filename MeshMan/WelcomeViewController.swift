//
//  WelcomeViewController.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/24/17.
//  Copyright © 2017 Russell Pecka. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class WelcomeViewController: UIViewController, MCBrowserViewControllerDelegate {
	
	// MARK: -
	
	private enum Strings {
		static let invalidDisplayNameErrorTitle = NSLocalizedString("Invalid Display Name", comment: "The title of the error that is shown when the user enters an invalid display name")
		static let invalidDisplayNameErrorMessage = NSLocalizedString("The display name field cannot be left blank.", comment: "The message to show when a user leaves the display name field blank")
	}
	
	private enum Constants {
		static let minimumNumberOfPeers = 2
	}
	
	// MARK: - Outlets
	
	@IBOutlet weak var displayNameField: UITextField!
	
	// MARK: - ViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
	
	// MARK: - Create/Join
	
	@IBAction func createButtonPressed() {
		self.validateNameAndStartSession(for: .create)
	}
	
	@IBAction func joinButtonPressed() {
		self.validateNameAndStartSession(for: .join)
	}
	
	private enum SessionType {
		case join, create
	}
	
	private func validateNameAndStartSession(for sessionType: SessionType) {
		guard let name = self.displayName else { self.showInvlaidNameError(); return }
		MCManager.setUpIfNeeded(with: name)
		switch sessionType {
		case .create:
			self.showBrowser()
		case .join:
			self.showWait()
		}
	}
	
	private var displayName: String? {
		guard let text = self.displayNameField.text else { return nil }
		guard text != "" else { return nil }
		return text
	}
	
	private func showInvlaidNameError() {
		let alertView = UIAlertController.init(title: Strings.invalidDisplayNameErrorTitle, message: Strings.invalidDisplayNameErrorMessage, preferredStyle: .alert)
		let okay = UIAlertAction(title: VisibleStrings.Generic.okay, style: .default, handler: nil)
		alertView.addAction(okay)
		self.present(alertView, animated: true)
	}
	
	private func showWait() {
		guard let waitController = Storyboards.wait.instantiateInitialViewController() as? WaitViewController else {
			print("Could not get a wait controller from the storyboard, make sure everything is set up right in the storyboard")
			return
		}
		waitController.advertiser = MCManager.shared.makeAdvertiser()
		self.navigationController?.pushViewController(waitController, animated: true)
	}
	
	private func showBrowser() {
		let browser = MCManager.shared.makeBrowser()
		let browserVC = MCBrowserViewController.init(browser: browser, session: MCManager.shared.session)
		browserVC.minimumNumberOfPeers = Constants.minimumNumberOfPeers
		browserVC.delegate = self
		self.present(browserVC, animated: true)
	}
	
	private func showGame() {
		
	}
	
	// MARK: MCBrowserViewControllerDelegate
	
	internal func browserViewController(_ browserViewController: MCBrowserViewController, shouldPresentNearbyPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) -> Bool {
		return true
	}
	
	internal func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
		self.dismiss(animated: true) { self.showGame() }
	}
	
	internal func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
		self.dismiss(animated: true)
	}
	
}
