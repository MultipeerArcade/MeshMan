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

	@IBOutlet private weak var scrollView: UIScrollView!
	@IBOutlet private weak var wordField: UITextField!
	@IBOutlet private weak var doneButton: UIButton!
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
		self.doneButton.titleLabel?.text = VisibleStrings.Generic.done
		self.subscribeToKeyboardEvents()
		self.wordField.delegate = self
		self.rulesLabel.text = String(format: HangmanGameModel.Rules.wordSelectionBlurb, HangmanGameModel.Rules.minCharacters, HangmanGameModel.Rules.maxCharacters)
		self.wordField.becomeFirstResponder()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
        netUtil.send(message: WaitMessage(message: "Waiting for \(MCManager.shared.peerID.displayName) to choose a word..."))
	}
	
	@IBAction func doneButtonPressed() {
		guard let text = self.wordField.text else { return }
		self.processText(input: text)
	}
	
	private func processText(input: String) {
		switch HangmanGameModel.checkValidChoice(input) {
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
        let hangmanVC = HangmanViewController.newInstance(word: word, netUtil: netUtil, firstPicker: MCManager.shared.peerID)
        netUtil.send(message: StartMessage(gameType: .hangman, payload: HangmanNetUtil.StartGamePayload(word: word, picker: MCManager.shared.peerID)))
		self.navigationController?.setViewControllers([hangmanVC], animated: true)
	}
	
	// MARK: - Keyboard
	
	private func subscribeToKeyboardEvents() {
		NotificationCenter.default.addObserver(forName: UIResponder.keyboardDidShowNotification, object: nil, queue: OperationQueue.main) { [weak self] in self?.keyboardDidShow($0) }
		NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: OperationQueue.main) { [weak self] in self?.keyboardWillHide($0) }
	}
	
	private func keyboardDidShow(_ notification: Notification) {
		guard let userInfo = notification.userInfo else { return }
		guard let size = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
		let existingInsets = self.scrollView.contentInset
		let newInsets = UIEdgeInsets(top: existingInsets.top, left: existingInsets.left, bottom: size.height, right: existingInsets.right)
		self.scrollView.contentInset = newInsets
		self.scrollView.scrollIndicatorInsets = newInsets
		
		var frame = self.view.frame
		frame.size.height -= size.height
		if !frame.contains(self.wordField.frame.origin) {
			self.scrollView.scrollRectToVisible(frame, animated: true)
		}
	}
	
	private func keyboardWillHide(_ notification: Notification) {
		let existingInsets = self.scrollView.contentInset
		let newInsets = UIEdgeInsets(top: existingInsets.top, left: existingInsets.left, bottom: 0, right: existingInsets.right)
		self.scrollView.contentInset = newInsets
		self.scrollView.scrollIndicatorInsets = newInsets
	}
	
	// MARK: - UITextFieldDelegate
	
	internal func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		guard let text = textField.text else { return false }
		self.processText(input: text)
		textField.resignFirstResponder()
		return false
	}

}
