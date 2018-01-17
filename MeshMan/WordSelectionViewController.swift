//
//  WordSelectionViewController.swift
//  MeshMan
//
//  Created by Russell Pecka on 1/16/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import UIKit

class WordSelectionViewController: UIViewController, UITextFieldDelegate {
	
	// MARK: - Outlets

	@IBOutlet private weak var wordField: UITextField!
	@IBOutlet private weak var rulesLabel: UILabel!
	
	// MARK: - Properties
	
	internal var netUtil: HangmanNetUtil!
	
	// MARK: - New Instance
	
	internal static func newInstance(netUtil: HangmanNetUtil) -> WordSelectionViewController {
		guard let wordSelectionVC = Storyboards.wordSelection.instantiateInitialViewController() as? WordSelectionViewController else { fatalError("Could not cast the resulting storyboard correctly") }
		wordSelectionVC.netUtil = netUtil
		return wordSelectionVC
	}
	
	// MARK: - ViewController Lifecycle
	
	override func viewDidLoad() {
        super.viewDidLoad()
		self.wordField.delegate = self
		self.rulesLabel.text = String(format: Hangman.Rules.wordSelectionBlurb, Hangman.Rules.minCharacters, Hangman.Rules.maxCharacters)
		self.wordField.becomeFirstResponder()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.netUtil.sendChoosingWordMessage(HangmanNetUtil.ChoosingWordMessage(pickerName: MCManager.shared.peerID.displayName))
	}
	
	private func processText(input: String) {
		switch Hangman.checkValidChoice(input) {
		case .tooLong:
			self.showTooLongAlert()
		case .tooShort:
			self.showTooShortAlert()
		case .good:
			self.showGame(word: input)
		}
	}
	
	private func showTooLongAlert() {
		// show alert and then become first responder
	}
	
	private func showTooShortAlert() {
		// show alert and then become first responder
	}
	
	private func showGame(word: String) {
		guard let hangmanVC = Storyboards.hangman.instantiateInitialViewController() as? HangmanViewController else { fatalError("Could not properly cast the given controller") }
		self.netUtil.sendStartGameMessage(HangmanNetUtil.StartGameMessage(word: word, picker: MCManager.shared.peerID))
		let turnManager = HangmanTurnManager(session: MCManager.shared.session, myPeerID: MCManager.shared.peerID, firstPicker: MCManager.shared.peerID)
		hangmanVC.hangmanNetUtil = self.netUtil
		hangmanVC.turnManager = turnManager
		hangmanVC.setUpHangman(with: word)
		self.navigationController?.setViewControllers([hangmanVC], animated: true)
	}
	
	// MARK: - UITextFieldDelegate
	
	internal func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		guard let text = textField.text else { return false }
		self.processText(input: text)
		textField.resignFirstResponder()
		return false
	}

}
