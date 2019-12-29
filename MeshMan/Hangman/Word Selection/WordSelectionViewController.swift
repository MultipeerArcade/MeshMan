//
//  WordSelectionViewController.swift
//  MeshMan
//
//  Created by Russell Pecka on 1/16/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import UIKit

class WordSelectionViewController: UIViewController, UITextFieldDelegate {
    
    enum Result {
        case choseWord(String)
        case cancelled
    }
	
	// MARK: - Outlets

	@IBOutlet private weak var scrollView: UIScrollView!
	@IBOutlet private weak var wordField: UITextField!
	@IBOutlet private weak var doneButton: UIButton!
	@IBOutlet private weak var rulesLabel: UILabel!
	
	// MARK: - Properties
	
    private var completion: ((Result) -> Void)!
	
	// MARK: - New Instance
	
    internal static func newInstance(completion: @escaping (Result) -> Void) -> WordSelectionViewController {
		guard let wordSelectionVC = Storyboards.wordSelection.instantiateInitialViewController() as? WordSelectionViewController else { fatalError("Could not cast the resulting storyboard correctly") }
        wordSelectionVC.completion = completion
		return wordSelectionVC
	}
	
	// MARK: - ViewController Lifecycle
	
	override func viewDidLoad() {
        super.viewDidLoad()
		self.doneButton.titleLabel?.text = VisibleStrings.Generic.done
		self.subscribeToKeyboardEvents()
		self.wordField.delegate = self
		self.rulesLabel.text = String(format: Hangman.Rules.wordSelectionBlurb, Hangman.Rules.minCharacters, Hangman.Rules.maxCharacters)
		self.wordField.becomeFirstResponder()
    }
	
	@IBAction func doneButtonPressed() {
		guard let text = self.wordField.text else { return }
		self.processText(input: text)
	}
	
	private func processText(input: String) {
		switch Hangman.checkValidChoice(input) {
		case .tooLong:
			self.showTooLongAlert()
		case .tooShort:
			self.showTooShortAlert()
		case .good:
            dismiss(animated: true) {
                self.completion(.choseWord(input))
            }
		}
	}
	
	private func showTooLongAlert() {
		// show alert and then become first responder
	}
	
	private func showTooShortAlert() {
		// show alert and then become first responder
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
