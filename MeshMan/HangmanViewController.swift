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
		static let inputTooLongErrorTitle = NSLocalizedString("Guess too long", comment: "Title of the error that shows when the user guess something that is too long")
		static let inputTooLongErrorMessage = NSLocalizedString("%@ has too many letters!", comment: "Format string to form the message that shows when the user makes a hangman guess that is too long. %@ is the guess they made")
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
	}
	
	// MARK: - Outlets
	
	@IBOutlet private weak var wordProgressLabel: UILabel!
	@IBOutlet private weak var incorrectLetterCollection: UICollectionView!
	@IBOutlet private weak var guessField: UITextField!
	
	// MARK: - Controllers
	
	private weak var gallowsController: GallowsController!
	
	// MARK: - ViewController Lifecycle
	
    override func viewDidLoad() {
        super.viewDidLoad()
		self.guessField.delegate = self
		self.incorrectLetterCollection.dataSource = self
		MCManager.shared.session.delegate = self
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
	
	// MARK: - Hangman
	
	private var hangman: Hangman!
	
	private var iAmLeader: Bool = false
	
	private var incorrectGuesses = [Character]()
	
	internal func setUpHangman(with word: String, leader: MCPeerID) {
		self.loadViewIfNeeded()
		self.hangman = Hangman(word: word)
		self.wordProgressLabel.text = self.hangman.obfuscatedWord
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
		guard input.count == 1 else { self.showInputTooLongMessage(input: input); return }
		let char = input[input.startIndex]
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
	
	private func showInputTooLongMessage(input: String) {
		let alertView = UIAlertController(title: Strings.inputTooLongErrorTitle, message: String(format: Strings.inputTooLongErrorMessage, input), preferredStyle: .alert)
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
	
	internal func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		guard let text = self.guessField.text else { return true }
		self.processText(input: text)
		return true
	}

}
