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
		static let displayNameKey = "displayName"
	}
	
	// MARK: - Outlets
	
	@IBOutlet weak var displayNameField: UITextField!
	
	// MARK: - ViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
		if let savedName = UserDefaults.standard.string(forKey: Constants.displayNameKey) {
			self.displayNameField.text = savedName
		}
    }
	
	// MARK: -
	
	private var gameType: GameType!
	
	// MARK: - Create/Join
	
	@IBAction func createButtonPressed() {
        validateName {
            showGameSelection()
        }
	}
	
	@IBAction func joinButtonPressed() {
        validateName {
            showWait()
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
        UserDefaults.standard.set(name, forKey: Constants.displayNameKey)
        MCManager.setUpIfNeeded(with: name)
        success()
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
        let waitVC = WaitViewController.newInstance(purpose: .joining(MCManager.shared.makeAdvertiser()), utilType: .wait(WaitNetUtil()))
		self.navigationController?.pushViewController(waitVC, animated: true)
	}
	
	private func showBrowser() {
		let browser = MCManager.shared.makeBrowser()
		let browserVC = MCBrowserViewController.init(browser: browser, session: MCManager.shared.session)
		browserVC.minimumNumberOfPeers = Constants.minimumNumberOfPeers
		browserVC.delegate = self
		self.present(browserVC, animated: true)
	}
	
	private func showWordSelection() {
		let wordSelectionVC = WordSelectionViewController.newInstance(netUtil: HangmanNetUtil(session: MCManager.shared.session))
		self.navigationController?.setViewControllers([wordSelectionVC], animated: true)
	}
    
    private func showSubjectSelection() {
        let subjectVC = SubjectViewController.newInstance(netUtil: QuestionNetUtil(session: MCManager.shared.session))
        self.navigationController?.setViewControllers([subjectVC], animated: true)
    }
	
	// MARK: MCBrowserViewControllerDelegate
	
	internal func browserViewController(_ browserViewController: MCBrowserViewController, shouldPresentNearbyPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) -> Bool {
		return true
	}
	
	internal func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
		self.dismiss(animated: true) {
            switch self.gameType! {
            case .hangman:
                self.showWordSelection()
            case .questions:
                self.showSubjectSelection()
            }
        }
	}
	
	internal func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
		self.dismiss(animated: true)
	}
	
}
