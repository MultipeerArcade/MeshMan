//
//  HangmanViewController.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/28/17.
//  Copyright © 2017 Russell Pecka. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class HangmanViewController: UIViewController, UICollectionViewDataSource, UITextFieldDelegate {
	
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
	
	// MARK: - Deinitialization
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	// MARK: - Controllers
	
	private weak var gallowsController: GallowsController!
	
	// MARK: - ViewController Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.guessField.delegate = self
		self.incorrectLetterCollection.dataSource = self
		self.subscribeToKeyboardEvents()
		self.turnManager.pingEvents()
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
	
	// MARK: - Message Processing
	
	internal var hangmanNetUtil: HangmanNetUtil! {
		didSet {
			if let netUtil = self.hangmanNetUtil { self.setUp(netUtil: netUtil) }
		}
	}
	
	private var newMessageRecievedHandle: Event<HangmanNetUtil.NewGuessMessage>.Handle?
	
	private func setUp(netUtil: HangmanNetUtil) {
		self.newMessageRecievedHandle = netUtil.newGuessRecieved.subscribe({ [weak self] in self?.handleNewGuessRecieved($1) })
	}
	
	private func handleNewGuessRecieved(_ message: HangmanNetUtil.NewGuessMessage) {
		self.processText(input: message.guess, sender: message.sender)
	}
	
	// MARK: - Turn Management
	
	internal var turnManager: HangmanTurnManager! {
		didSet {
			if let turnManager = self.turnManager { self.setUp(turnManager: turnManager) }
		}
	}
	
	private var currentGuesserChangedHandle: Event<HangmanTurnManager.RoleChangePayload>.Handle?
	
	private func setUp(turnManager: HangmanTurnManager) {
		self.currentGuesserChangedHandle = turnManager.currentGuesserChanged.subscribe({ [weak self] in self?.setUp(newGuesser: $1) })
	}
	
	private func setUp(newGuesser: HangmanTurnManager.RoleChangePayload) {
		if newGuesser.isMe {
			self.navigationItem.prompt = Strings.yourTurn
			self.guessField.isHidden = false
			self.guessField.isEnabled = true
			self.guessField.becomeFirstResponder()
		} else {
			self.navigationItem.prompt = String(format: Strings.personsTurn, newGuesser.name)
			self.guessField.isHidden = true
			self.guessField.isEnabled = false
			self.guessField.resignFirstResponder()
		}
	}
	
	// MARK: - Keyboard
	
	private func subscribeToKeyboardEvents() {
		NotificationCenter.default.addObserver(forName: Notification.Name.UIKeyboardDidShow, object: nil, queue: OperationQueue.main) { [weak self] in self?.keyboardDidShow($0) }
		NotificationCenter.default.addObserver(forName: Notification.Name.UIKeyboardWillHide, object: nil, queue: OperationQueue.main) { [weak self] in self?.keyboardWillHide($0) }
	}
	
	private func keyboardDidShow(_ notification: Notification) {
		guard let userInfo = notification.userInfo else { return }
		guard let size = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
		let existingInsets = self.scrollView.contentInset
		self.scrollView.contentInset = UIEdgeInsetsMake(existingInsets.top, existingInsets.left, size.height, existingInsets.right)
		
		var frame = self.view.frame
		frame.size.height -= size.height
		if !frame.contains(self.guessField.frame.origin) {
			self.scrollView.scrollRectToVisible(frame, animated: true)
		}
	}
	
	private func keyboardWillHide(_ notification: Notification) {
		let existingInsets = self.scrollView.contentInset
		self.scrollView.contentInset = UIEdgeInsetsMake(existingInsets.top, existingInsets.left, 0, existingInsets.right)
	}
	
	// MARK: - Hangman
	
	private var hangman: Hangman!
	
	private var incorrectGuesses = [Character]()
	
	internal func setUpHangman(with word: String) {
		self.loadViewIfNeeded()
		self.hangman = Hangman(word: word)
		self.updateWordProgress(with: self.hangman.obfuscatedWord)
		self.numberOfLettersLabel.text = String(format: Strings.numberOfLetters, self.hangman.numberOfBlanks)
	}
	
	// MARK: - Input Processing
	
	private func processText(input: String, sender: MCPeerID = MCManager.shared.peerID) {
		let trimmedInput = input.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
		let local = MCManager.shared.isThisMe(sender) // Sender won't be populated if the word was guessed locally
		guard trimmedInput.count == 1 else { self.showInputNotOneCharMessage(); return }
		let char = trimmedInput[trimmedInput.startIndex]
		let validTurnMade: Bool
		let result = self.hangman.guess(letter: char)
		switch result {
		case .alreadyGuessed(let guess):
			if local {
				self.showAlreadyGuessedMessage(guess: guess)
			}
			validTurnMade = false
		case .correct(let updatedWord):
			self.updateWordProgress(with: updatedWord)
			validTurnMade = true
		case .invalid(let guess):
			if local {
				self.showInvalidLetterMessage(guess: guess)
			}
			validTurnMade = false
		case .noMoreGuesses(let incorrectGuess, let word):
			self.updateFor(incorrectCharacter: incorrectGuess)
			self.showNoMoreGuessesMessage(with: word)
			self.turnManager.set(picker: sender)
			validTurnMade = true
		case .wordGuessed(let word):
			self.updateWordProgress(with: word)
			self.showWordGuessedMessage(with: word)
			self.turnManager.set(picker: sender)
			validTurnMade = true
		case .wrong(let incorrectGuess):
			self.updateFor(incorrectCharacter: incorrectGuess)
			validTurnMade = true
		}
		if local { self.broadcast(guess: char) }
		if validTurnMade { self.turnManager.turnCompleted() }
	}
	
	private func broadcast(guess: Character) {
		let message = HangmanNetUtil.NewGuessMessage(guess: String(guess), sender: MCManager.shared.peerID)
		self.hangmanNetUtil.sendNewGuessMessage(message)
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
		switch self.turnManager.myRole {
		case .guesser, .waiting:
			alertView = UIAlertController(title: Strings.loseAlertTitle, message: String(format: Strings.guesserLoseAlertMessage, word), preferredStyle: .alert)
		case .picker:
			alertView = UIAlertController(title: Strings.winAlertTitle, message: String(format: Strings.pickerWinAlertMessage, word), preferredStyle: .alert)
		}
		let okay = UIAlertAction(title: VisibleStrings.Generic.okay, style: .default) { (_) in self.prepareForNextGame() }
		alertView.addAction(okay)
		self.present(alertView, animated: true)
	}
	
	private func showWordGuessedMessage(with word: String) {
		let alertView: UIAlertController
		switch self.turnManager.myRole {
		case .guesser, .waiting:
			alertView = UIAlertController(title: Strings.winAlertTitle, message: String(format: Strings.guesserWinAlertMessage, word), preferredStyle: .alert)
		case .picker:
			alertView = UIAlertController(title: Strings.loseAlertTitle, message: String(format: Strings.pickerLoseAlertMessage, word), preferredStyle: .alert)
		}
		let okay = UIAlertAction(title: VisibleStrings.Generic.okay, style: .default) { (_) in self.prepareForNextGame() }
		alertView.addAction(okay)
		self.present(alertView, animated: true)
	}
	
	private func prepareForNextGame() {
		if self.turnManager.iAmPicker {
			self.showWordSelection()
		} else {
			self.showWait()
		}
	}
	
	private func showWordSelection() {
		let alertView = WordSelectionDialog.make(withOkayAction: { [weak self] (_, word) in self?.showGame(with: word) }) { (_) in fatalError() }
		self.present(alertView, animated: true, completion: nil)
	}
	
	private func showGame(with word: String) {
		guard let hangmanVC = Storyboards.hangman.instantiateInitialViewController() as? HangmanViewController else { fatalError() }
		self.hangmanNetUtil.sendStartGameMessage(HangmanNetUtil.StartGameMessage(word: word, picker: MCManager.shared.peerID))
		hangmanVC.hangmanNetUtil = self.hangmanNetUtil
		hangmanVC.turnManager = HangmanTurnManager(session: MCManager.shared.session, myPeerID: MCManager.shared.peerID, firstPicker: MCManager.shared.peerID)
		hangmanVC.setUpHangman(with: word)
		self.navigationController?.setViewControllers([hangmanVC], animated: true)
	}
	
	private func showWait() {
		guard let waitController = Storyboards.wait.instantiateInitialViewController() as? WaitViewController else {
			print("Could not get a wait controller from the storyboard, make sure everything is set up right in the storyboard")
			fatalError()
		}
		waitController.hangmanNetUtil = self.hangmanNetUtil
		self.navigationController?.setViewControllers([waitController], animated: true)
	}
	
	private func updateFor(incorrectCharacter: Character) {
		self.incorrectGuesses.append(incorrectCharacter)
		let lastIndex = IndexPath(row: self.incorrectGuesses.count - 1, section: 0)
		self.incorrectLetterCollection.insertItems(at: [lastIndex])
		self.incorrectLetterCollection.scrollToItem(at: lastIndex, at: .left, animated: true)
		self.gallowsController.next()
	}
	
	// MARK: - UICollectionViewDataSource
	
	internal func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.incorrectGuesses.count
	}
	
	internal func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LetterCell.reuseIdentifier, for: indexPath)
		if let letterCell = cell as? LetterCell {
			letterCell.letterLabel.text = String(self.incorrectGuesses[indexPath.row])
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
		self.processText(input: text)
		self.guessField.text = nil
		return true
	}

}
