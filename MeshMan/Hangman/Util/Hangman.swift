//
//  Hangman.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/28/17.
//  Copyright © 2017 Russell Pecka. All rights reserved.
//

import Foundation
import MultipeerConnectivity

// MARK: - HangmanDelegate

protocol HangmanDelegate: class {
    func hangman(_ hangman: Hangman, didRecieveGuess result: Hangman.GuessResult)
    func hangman(_ hangman: Hangman, didSetGuesser iAmGuesser: Bool)
}

final class Hangman {
    
    // MARK: - Types
	
	enum Rules {
		static let numberOfGuesses = 9
		static let maxCharacters = 100
		static let minCharacters = 3
		static let wordSelectionBlurb = NSLocalizedString("The word you choose must be no shorter than %d characters and no longer than %d characters. Any characters other than numbers and letters will be shown to your opponents.\n\nFor Example:\n\nTHE CAT'S MEOW\nwill become\n_ _ _   _ _ _ ' _   _ _ _ _", comment: "Writeup of the rules around choosing a word in hangman")
	}
    
    enum ChoiceValidity {
        case tooShort, tooLong, good
    }
    
    enum GuessSanitationResult {
        case sanitized(Character)
        case tooLong
        case tooShort
        case invalidCharacter
        case alreadyGuessed
    }
    
    enum GuessResult {
        case correct(String)
        case wrong(Character)
        case wordGuessed(String)
        case noMoreGuesses(Character, String)
    }
    
    // MARK: - Internal Members
	
	private(set) var obfuscatedWord: String
    
    private(set) var incorrectLetters = [Character]()
    
    internal let numberOfBlanks: Int
    
    let netUtil: HangmanNetUtil
    
    let turnManager: HangmanTurnManager
    
    weak var delegate: HangmanDelegate?
    
    // MARK: - Private Members
    
    private let word: String
	
	private var guessedLetters = [Character]()
    
    // MARK: Event Handles
    
    private var newGuessRecievedHandle: Event<HangmanNetUtil.NewGuessMessage>.Handle?
    
    // MARK: - Initialization
	
    init(word: String, netUtil: HangmanNetUtil, firstPicker: MCPeerID) {
		self.word = Hangman.sanitize(word: word)
		let (displayString, _, numberOfBlanks) = Hangman.obfuscate(word: self.word)
		self.obfuscatedWord = displayString
		self.numberOfBlanks = numberOfBlanks
        self.netUtil = netUtil
        self.turnManager = HangmanTurnManager(session: netUtil.session, myPeerID: MCManager.shared.peerID, firstPicker: firstPicker)
        configure(netUtil: netUtil)
	}
    
    private func configure(netUtil: HangmanNetUtil) {
        newGuessRecievedHandle = netUtil.newGuessRecieved.subscribe({ (_, message) in
            self.newGuessRecieved(message)
        })
    }
    
    // MARK: - Network Event Handling
    
    private func newGuessRecieved(_ message: HangmanNetUtil.NewGuessMessage) {
        let result = guess(letter: message.guess)
        delegate?.hangman(self, didRecieveGuess: result)
    }
    
    // MARK: - UI Event Handling
    
    func make(guess letter: Character) -> GuessResult {
        let guessMessage = HangmanNetUtil.NewGuessMessage(guess: letter, sender: MCManager.shared.peerID)
        netUtil.send(message: guessMessage)
        let result = guess(letter: letter)
        return result
    }
    
    // MARK: - Gameplay
	
	private func guess(letter: Character) -> GuessResult {
        if word.contains(letter) {
            guessedLetters.append(letter)
            let (displayString, comparisonString, _) = Hangman.obfuscate(word: word, excluding: guessedLetters)
            obfuscatedWord = displayString
            if word == comparisonString {
                return .wordGuessed(comparisonString)
            } else {
                turnComplete()
                return .correct(displayString)
            }
        } else {
            guessedLetters.append(letter)
            incorrectLetters.append(letter)
            if incorrectLetters.count >= Rules.numberOfGuesses {
                return .noMoreGuesses(letter, word)
            } else {
                turnComplete()
                return .wrong(letter)
            }
        }
	}
    
    private func turnComplete() {
        turnManager.pickNextGuesser()
        delegate?.hangman(self, didSetGuesser: turnManager.iAmGuesser)
    }
	
	// MARK: - Util
	
	internal static func checkValidChoice(_ text: String) -> ChoiceValidity {
		var count = 0
		for character in text.uppercased() {
			if self.characterIsValid(character) { count += 1 }
		}
		guard count >= Rules.minCharacters else { return .tooShort }
		guard count <= Rules.maxCharacters else { return .tooLong }
		return .good
	}
	
	internal static func sanitize(word: String) -> String {
		return word.uppercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
	}
	
	internal static func obfuscate(word: String, excluding excludedCharacters: [Character] = []) -> (displayString: String, comparisonString: String, numberOfBlanks: Int) {
		var displayString = ""
		var comparisonString = ""
		var numberOfBlanks = 0
		let lastIndex = word.count - 1
		for (index, char) in word.enumerated() {
			var toAppend = index == 0 ? "" : " "
			if excludedCharacters.contains(char) {
				comparisonString.append(char)
				toAppend.append(char)
			} else if self.characterIsValid(char) {
				comparisonString.append("_")
				toAppend.append("_")
				numberOfBlanks += 1
			} else {
				comparisonString.append(char)
				toAppend.append(char)
			}
			if lastIndex == index {
				toAppend.append(" ")
			}
			displayString.append(toAppend)
		}
		return (displayString, comparisonString, numberOfBlanks)
	}
    
    func sanitize(guess: String) -> GuessSanitationResult {
        let trimmed = guess.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard trimmed.count > 0 else { return .tooShort }
        guard trimmed.count == 1 else { return .tooLong }
        let char = trimmed[trimmed.startIndex]
        guard Hangman.characterIsValid(char) else { return .invalidCharacter }
        guard !guessedLetters.contains(char) else { return .alreadyGuessed }
        return .sanitized(char)
    }
	
	internal static func characterIsValid(_ character: Character) -> Bool {
		guard let scalar = UnicodeScalar("\(character)") else { return false }
		return CharacterSet.uppercaseLetters.contains(scalar)
	}
	
}
