//
//  HangmanViewController.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/28/17.
//  Copyright © 2017 Russell Pecka. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class HangmanViewController: UIViewController, HangmanDelegate, UICollectionViewDataSource, UITextFieldDelegate {
    
	// MARK: -
	
	private enum Strings {
		static let inputNotOneCharErrorMessage = NSLocalizedString("Your guess can only be one character.", comment: "Format string to form the message that shows when the user makes a hangman guess that is too long or too short")
		static let alreadyGuessedErrorTitle = NSLocalizedString("Already guessed", comment: "The title of the error that shows when the user makes a hangman guess that they have previously made")
		static let alreadyGuessedErrorMessage = NSLocalizedString("You have already guessed: %@. Guess something else.", comment: "The message that shows when the user makes a hangman guess that they have already made.")
		static let invalidLetterErrorTitle = NSLocalizedString("Invalid Guess", comment: "Error message title to show when the user guesses an invalid character")
		static let invalidLetterErrorMessage = NSLocalizedString("%@ is not a valid guess. Please guess something else.", comment: "Message that shows when the user makes an incorrect hangman guess")
		static let loseAlertTitle = NSLocalizedString("You Lose", comment: "Title of the alert that tells the user they lost")
		static let guesserLoseAlertMessage = NSLocalizedString("You did not guess the word within the maximum number of guesses. The word was %@.", comment: "Message to show when the user loses a game of hangman")
		static let pickerLoseAlertMessage = NSLocalizedString("Your opponents successfully guessed the word: %@.", comment: "The message to show when the user's opponents guess the word")
		static let winAlertTitle = NSLocalizedString("You Win", comment: "Title of the alert that tells the user that they won")
		static let guesserWinAlertMessage = NSLocalizedString("You guessed the word! It was %@.", comment: "The body of the message that shows when the user wins the game.")
		static let pickerWinAlertMessage = NSLocalizedString("Your opponents failed to guess your word: %@.", comment: "The message to show when the user's opponents fail to guess the word")
		static let numberOfLetters = NSLocalizedString("%d Letters", comment: "Format string for the label that shows underneath the word progress label in hangman")
		static let yourTurn = NSLocalizedString("Your Turn", comment: "Message that indicates that it is the current users' turn")
		static let personsTurn = NSLocalizedString("%@'s Turn", comment: "Message that indicates that it is %@s turn")
	}
	
	// MARK: - Outlets
	
	@IBOutlet private weak var container: UIView!
	@IBOutlet private weak var scrollView: UIScrollView!
	@IBOutlet private weak var wordProgressLabel: UILabel!
	@IBOutlet private weak var incorrectLetterCollection: UICollectionView!
	@IBOutlet private weak var guessField: UITextField!
	@IBOutlet private weak var numberOfLettersLabel: UILabel!
    
    // MARK: - Private Members
    
    private var hangman: Hangman!
    
    private var incorrectGuesses = [Character]()
	
	// MARK: Controllers
	
	private weak var gallowsController: GallowsController!
    
    // MARK: - New Instance
    
    static func newInstance(hangman: Hangman) -> HangmanViewController {
        let vc = Storyboards.hangman.instantiateInitialViewController() as! HangmanViewController
        vc.hangman = hangman
        vc.hangman.delegate = vc
        return vc
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
	
	// MARK: - ViewController Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.guessField.delegate = self
		self.incorrectLetterCollection.dataSource = self
		self.subscribeToKeyboardEvents()
        setUp(asGuesser: hangman.iAmGuesser)
        let obfuscationResult = hangman.getWordObfuscationPayload()
        updateWordProgress(with: obfuscationResult.obfuscatedWord)
        numberOfLettersLabel.text = String(format: Strings.numberOfLetters, obfuscationResult.numberOfBlanks)
    }
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		self.scrollView.contentSize = self.container.frame.size
	}
	
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let identifier = segue.identifier else { return }
		switch identifier {
		case "gallows":
			self.gallowsController = segue.destination as? GallowsController
		default:
			break
		}
    }
	
    private func setUp(asGuesser iAmGuesser: Bool) {
		if iAmGuesser {
			self.navigationItem.title = Strings.yourTurn
			self.guessField.isHidden = false
			self.guessField.isEnabled = true
			self.guessField.becomeFirstResponder()
		} else {
            self.navigationItem.title = String(format: Strings.personsTurn, hangman.currentGuesser.displayName)
			self.guessField.isHidden = true
			self.guessField.isEnabled = false
			self.guessField.resignFirstResponder()
		}
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
		self.scrollView.contentInset = UIEdgeInsets(top: existingInsets.top, left: existingInsets.left, bottom: size.height, right: existingInsets.right)
		
		var frame = self.view.frame
		frame.size.height -= size.height
		if !frame.contains(self.guessField.frame.origin) {
			self.scrollView.scrollRectToVisible(frame, animated: true)
		}
	}
	
	private func keyboardWillHide(_ notification: Notification) {
		let existingInsets = self.scrollView.contentInset
		self.scrollView.contentInset = UIEdgeInsets(top: existingInsets.top, left: existingInsets.left, bottom: 0, right: existingInsets.right)
	}
	
	// MARK: - Input Processing
    
    private func process(guess: String) {
        let sanitationResult = hangman.make(guess: guess)
        switch sanitationResult {
        case .alreadyGuessed:
            showAlreadyGuessedMessage(guess: guess)
        case .invalidCharacter, .tooLong, .tooShort:
            showInvalidLetterMessage(guess: guess)
        case .success:
            break
        }
    }
	
	private func showInputNotOneCharMessage() {
		let alertView = UIAlertController(title: Strings.invalidLetterErrorTitle, message: Strings.inputNotOneCharErrorMessage, preferredStyle: .alert)
		let okay = UIAlertAction(title: VisibleStrings.Generic.okay, style: .default, handler: nil)
		alertView.addAction(okay)
		self.present(alertView, animated: true, completion: nil)
	}
	
	private func showAlreadyGuessedMessage(guess: String) {
		let alertView = UIAlertController(title: Strings.alreadyGuessedErrorTitle, message: String(format: Strings.alreadyGuessedErrorMessage, guess), preferredStyle: .alert)
		let okay = UIAlertAction(title: VisibleStrings.Generic.okay, style: .default, handler: nil)
		alertView.addAction(okay)
		self.present(alertView, animated: true, completion: nil)
	}
	
	private func updateWordProgress(with updatedWord: String) {
		self.wordProgressLabel.text = updatedWord
	}
	
	private func showInvalidLetterMessage(guess: String) {
		let alertView = UIAlertController(title: Strings.invalidLetterErrorTitle, message: String(format: Strings.invalidLetterErrorMessage, guess), preferredStyle: .alert)
		let okay = UIAlertAction(title: VisibleStrings.Generic.okay, style: .default, handler: nil)
		alertView.addAction(okay)
		self.present(alertView, animated: true, completion: nil)
	}
	
	private func showNoMoreGuessesMessage(with word: String) {
		let alertView: UIAlertController
        switch hangman.iAmPicker {
		case false:
			alertView = UIAlertController(title: Strings.loseAlertTitle, message: String(format: Strings.guesserLoseAlertMessage, word), preferredStyle: .alert)
		case true:
			alertView = UIAlertController(title: Strings.winAlertTitle, message: String(format: Strings.pickerWinAlertMessage, word), preferredStyle: .alert)
		}
        let okay = UIAlertAction(title: VisibleStrings.Generic.okay, style: .default) { (_) in self.hangman.done() }
		alertView.addAction(okay)
		self.present(alertView, animated: true)
	}
	
	private func showWordGuessedMessage(with word: String) {
		let alertView: UIAlertController
        switch hangman.iAmPicker {
		case false:
			alertView = UIAlertController(title: Strings.winAlertTitle, message: String(format: Strings.guesserWinAlertMessage, word), preferredStyle: .alert)
		case true:
			alertView = UIAlertController(title: Strings.loseAlertTitle, message: String(format: Strings.pickerLoseAlertMessage, word), preferredStyle: .alert)
		}
        let okay = UIAlertAction(title: VisibleStrings.Generic.okay, style: .default) { (_) in self.hangman.done() }
		alertView.addAction(okay)
		self.present(alertView, animated: true)
	}
	
	private func updateFor(newIncorrectCharacters: Set<Character>) {
        guard newIncorrectCharacters.count > 0 else { return }
        let newChars = newIncorrectCharacters.filter { !incorrectGuesses.contains($0)}
        let insertionIndicies = newChars.map { (newChar) -> IndexPath in
            incorrectGuesses.append(newChar)
            self.gallowsController.next()
            return IndexPath(row: incorrectGuesses.count - 1, section: 0)
        }
		let lastIndex = IndexPath(row: self.incorrectGuesses.count - 1, section: 0)
		self.incorrectLetterCollection.insertItems(at: insertionIndicies)
		self.incorrectLetterCollection.scrollToItem(at: lastIndex, at: .left, animated: true)
	}
    
    // MARK: - HangmanDelegate
    
    func hangman(_ hangman: Hangman, stateUpdatedFromOldState oldState: HangmanGameState?, toNewState newState: HangmanGameState, obfuscationResult: Hangman.WordObfuscationPayload) {
        updateFor(newIncorrectCharacters: newState.incorrectCharacters)
        setUp(asGuesser: hangman.iAmGuesser)
        updateWordProgress(with: obfuscationResult.obfuscatedWord)
    }
	
	// MARK: - UICollectionViewDataSource
	
	internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return incorrectGuesses.count
	}
	
	internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LetterCell.reuseIdentifier, for: indexPath)
		if let letterCell = cell as? LetterCell {
            letterCell.letterLabel.text = String(incorrectGuesses[indexPath.row])
		}
		return cell
	}
	
	// MARK: - UITextFieldDelegate
	
	internal func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		guard string.count <= 1 else { return false } // If the replacement string has one or fewer characters, need this to protect against copy/paste
		if let count = textField.text?.count, count > 0 { // If the text field has at least one character in it
			if range.lowerBound == 0, range.upperBound == 1 { // If the single character is the one being edited
				return true
			} else {
				return false
			}
		} else { // If the field has no characters in it
			return true
		}
	}
	
	internal func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		guard let text = self.guessField.text else { return true }
        process(guess: text)
		self.guessField.text = nil
		return true
	}

}
