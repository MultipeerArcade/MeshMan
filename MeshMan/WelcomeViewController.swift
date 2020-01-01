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
	
	enum Constants {
		static let displayNameKey = "displayName"
        static let peerIDKey = "peerID"
	}
	
	// MARK: - Outlets
	
	@IBOutlet weak var displayNameField: UITextField!
    
    static func newInstance() -> WelcomeViewController {
        let welcomeVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "welcome") as! WelcomeViewController
        return welcomeVC
    }
	
	// MARK: - ViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        RootManager.shared.navigationController = navigationController
		if let savedName = UserDefaults.standard.string(forKey: Constants.displayNameKey) {
			self.displayNameField.text = savedName
		}
    }
	
	// MARK: -
	
	private var gameType: GameType!
	
	// MARK: - Create/Join
	
	@IBAction func createButtonPressed() {
        validateName {
            self.showBrowser()
        }
	}
	
	@IBAction func joinButtonPressed() {
        validateName {
            RootManager.shared.startWaitingForInvite()
        }
	}
    
    func showGameSelection() {
        let actionSheet = UIAlertController(title: "Choose a game", message: nil, preferredStyle: .actionSheet)
        let hangmanAction = UIAlertAction(title: "Hangman", style: .default) { _ in
            self.gameType = .hangman
            self.showBrowser()
        }
        let questionsAction = UIAlertAction(title: "20 Questions", style: .default) { _ in
            self.gameType = .questions
            self.showBrowser()
        }
        actionSheet.addAction(hangmanAction)
        actionSheet.addAction(questionsAction)
        present(actionSheet, animated: true)
    }
    
    private func validateName(success: () -> Void) {
        guard let name = self.displayName else { self.showInvlaidNameError(); return }
        if let oldName = UserDefaults.standard.string(forKey: Constants.displayNameKey), let oldPeerIDData = UserDefaults.standard.data(forKey: Constants.peerIDKey) {
            if oldName == name {
                MCManager.setUp(with: MCPeerID.from(data: oldPeerIDData))
            } else {
                save(name: name)
            }
        } else {
            save(name: name)
        }
        success()
    }
    
    private func save(name: String) {
        UserDefaults.standard.set(name, forKey: Constants.displayNameKey)
        let peerID = MCPeerID(displayName: name)
        UserDefaults.standard.set(peerID.dataRepresentation, forKey: Constants.peerIDKey)
        MCManager.setUp(with: peerID)
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
        let waitVC = WaitInviteViewController.newInstance()
		self.navigationController?.pushViewController(waitVC, animated: true)
	}
	
	private func showBrowser() {
        let browserVC = MCManager.shared.makeBrowserVC()
		browserVC.delegate = self
		self.present(browserVC, animated: true)
	}
	
	// MARK: MCBrowserViewControllerDelegate
	
	internal func browserViewController(_ browserViewController: MCBrowserViewController, shouldPresentNearbyPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) -> Bool {
		return true
	}
	
	internal func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
		self.dismiss(animated: true) {
            RootManager.shared.goToLobby()
        }
	}
	
	internal func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
		self.dismiss(animated: true)
	}
	
}
