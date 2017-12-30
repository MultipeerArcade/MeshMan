//
//  HangmanViewController.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/28/17.
//  Copyright © 2017 Russell Pecka. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class HangmanViewController: UIViewController, MCSessionDelegate, UICollectionViewDataSource, UITextFieldDelegate {
	
	// MARK: -
	
	private enum Strings {
		static let inputNotOneCharErrorMessage = NSLocalizedString("Your guess can only be one character.", comment: "Format string to form the message that shows when the user makes a hangman guess that is too long or too short")
		static let alreadyGuessedErrorTitle = NSLocalizedString("Already guessed", comment: "The title of the error that shows when the user makes a hangman guess that they have previously made")
		static let alreadyGuessedErrorMessage = NSLocalizedString("You have already guessed: %@. Guess something else.", comment: "The message that shows when the user makes a hangman guess that they have already made.")
		static let invalidLetterErrorTitle = NSLocalizedString("Invalid Guess", comment: "Error message title to show when the user guesses an invalid character")
		static let invalidLetterErrorMessage = NSLocalizedString("%@ is not a valid guess. Please guess something else.", comment: "Message that shows when the user makes an incorrect hangman guess")
		static let loseAlertTitle = NSLocalizedString("You Lose", comment: "Title of the alert that tells the user they lost")
		static let loseAlertMessage = NSLocalizedString("You did not guess the word within the maximum number of guesses. The word was %@.", comment: "Message to show when the user loses a game of hangman")
		static let leaderLoseAlertMessage = NSLocalizedString("Your opponents successfully guessed the word.", comment: "The message to show when the user's opponents guess the word")
		static let winAlertTitle = NSLocalizedString("You Win", comment: "Title of the alert that tells the user that they won")
		static let winAlertMessage = NSLocalizedString("You guessed the word! It was %@.", comment: "The body of the message that shows when the user wins the game.")
		static let leaderWinAlertMessage = NSLocalizedString("Your opponents failed to guess your word.", comment: "The message to show when the user's opponents fail to guess the word")
		static let numberOfLetters = NSLocalizedString("%d Letters", comment: "Format string for the label that shows underneath the word progress label in hangman")
	}
	
	// MARK: - Outlets
	
	@IBOutlet private weak var container: UIView!
	@IBOutlet private weak var scrollView: UIScrollView!
	@IBOutlet private weak var wordProgressLabel: UILabel!
	@IBOutlet private weak var incorrectLetterCollection: UICollectionView!
	@IBOutlet private weak var guessField: UITextField!
	@IBOutlet private weak var numberOfLettersLabel: UILabel!
	
	// MARK: - Controllers
	
	private weak var gallowsController: GallowsController!
	
	// MARK: - ViewController Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.guessField.delegate = self
		self.incorrectLetterCollection.dataSource = self
		MCManager.shared.session.delegate = self
		self.subscribeToKeyboardEvents()
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
	
	private var iAmLeader: Bool = false
	
	private var incorrectGuesses = [Character]()
	
	internal func setUpHangman(with word: String, leader: MCPeerID) {
		self.loadViewIfNeeded()
		self.hangman = Hangman(word: word)
		self.updateWordProgress(with: self.hangman.obfuscatedWord)
		self.numberOfLettersLabel.text = String(format: Strings.numberOfLetters, self.hangman.numberOfBlanks)
		if MCManager.shared.isThisMe(leader) {
			self.iAmLeader = true
			self.guessField.isHidden = true
		} else {
			self.iAmLeader = false
			self.guessField.isHidden = false
		}
	}
	
	// MARK: - Input Processing
	
	private func processText(input: String, fromPeer: Bool = false) {
		let trimmedInput = input.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
		guard trimmedInput.count == 1 else { self.showInputNotOneCharMessage(); return }
		let char = trimmedInput[trimmedInput.startIndex]
		let result = self.hangman.guess(letter: char)
		switch result {
		case .alreadyGuessed(let guess):
			if !self.iAmLeader {
				self.showAlreadyGuessedMessage(guess: guess)
			}
		case .correct(let updatedWord):
			self.updateWordProgress(with: updatedWord)
			if !fromPeer { self.broadcast(guess: char) }
		case .invalid(let guess):
			if !self.iAmLeader {
				self.showInvalidLetterMessage(guess: guess)
			}
		case .lose(let word):
			if self.iAmLeader {
				self.showLeaderWinMessage()
			} else {
				self.showLoseMessage(with: word)
			}
			if !fromPeer { self.broadcast(guess: char) }
		case .win(let word):
			if self.iAmLeader {
				self.showLeaderLoseMessage()
			} else {
				self.showWinMessage(with: word)
			}
			if !fromPeer { self.broadcast(guess: char) }
		case .wrong(let incorrectGuess):
			self.updateFor(incorrectCharacter: incorrectGuess)
			if !fromPeer { self.broadcast(guess: char) }
		}
	}
	
	private func broadcast(guess: Character) {
		let message = NewGuessMessage(guess: String(guess))
		guard let encodedData = try? JSONEncoder().encode(message) else { return }
		try? MCManager.shared.session.send(encodedData, toPeers: MCManager.shared.session.connectedPeers, with: .reliable)
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
	
	private func showLoseMessage(with revealedWord: String) {
		let alertView = UIAlertController(title: Strings.loseAlertTitle, message: String(format: Strings.loseAlertMessage, revealedWord), preferredStyle: .alert)
		let okay = UIAlertAction(title: VisibleStrings.Generic.okay, style: .default) { (_) in fatalError() }
		alertView.addAction(okay)
		self.present(alertView, animated: true)
	}
	
	private func showLeaderLoseMessage() {
		let alertView = UIAlertController(title: Strings.loseAlertTitle, message: Strings.leaderLoseAlertMessage, preferredStyle: .alert)
		let okay = UIAlertAction(title: VisibleStrings.Generic.okay, style: .default) { (_) in fatalError() }
		alertView.addAction(okay)
		self.present(alertView, animated: true)
	}
	
	private func showWinMessage(with revealedWord: String) {
		let alertView = UIAlertController(title: Strings.winAlertTitle, message: String(format: Strings.winAlertMessage, revealedWord), preferredStyle: .alert)
		let okay = UIAlertAction(title: VisibleStrings.Generic.okay, style: .default) { (_) in fatalError() }
		alertView.addAction(okay)
		self.present(alertView, animated: true)
	}
	
	private func showLeaderWinMessage() {
		let alertView = UIAlertController(title: Strings.winAlertTitle, message: Strings.leaderWinAlertMessage, preferredStyle: .alert)
		let okay = UIAlertAction(title: VisibleStrings.Generic.okay, style: .default) { (_) in fatalError() }
		alertView.addAction(okay)
		self.present(alertView, animated: true)
	}
	
	private func updateFor(incorrectCharacter: Character) {
		self.incorrectGuesses.append(incorrectCharacter)
		let lastIndex = IndexPath(row: self.incorrectGuesses.count - 1, section: 0)
		self.incorrectLetterCollection.insertItems(at: [lastIndex])
		self.incorrectLetterCollection.scrollToItem(at: lastIndex, at: .left, animated: true)
		self.gallowsController.next()
	}
	
	struct NewGuessMessage: Codable {
		
		let guess: String
		
		init(guess: String) {
			self.guess = guess
		}
		
	}
	
	// MARK: - MCSessionDelegate
	
	internal func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
		guard let message = try? JSONDecoder().decode(NewGuessMessage.self, from: data) else { return }
		DispatchQueue.main.async {
			self.processText(input: message.guess, fromPeer: true)
		}
	}
	
	internal func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
		
	}
	
	internal func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
		
	}
	
	internal func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
		
	}
	
	internal func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
		
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
		if let count = textField.text?.count, count > 1 {
			return false
		} else {
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
