//
//  Hangman.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/28/17.
//  Copyright © 2017 Russell Pecka. All rights reserved.
//

import Foundation

// MARK: - HangmanDelegate

internal class Hangman {
	
	internal enum Rules {
		static let numberOfGuesses = 10
	}
	
	private let word: String
	
	internal private(set) var obfuscatedWord: String
	
	private var guessedLetters = [Character]()
	
	internal private(set) var incorrectLetters = [Character]()
	
	init(word: String) {
		self.word = word.uppercased()
		self.obfuscatedWord = Hangman.obfuscate(word: self.word)
	}
	
	internal enum GuessResult {
		case correct(String), alreadyGuessed(String), wrong(Character), invalid(String), win(String), lose(String)
	}
	
	internal func guess(letter: Character) -> GuessResult {
		let char = Character("\(letter)".uppercased())
		guard Hangman.characterIsValid(char) else { return .invalid("\(char)") }
		if guessedLetters.contains(char) {
			return .alreadyGuessed("\(char)")
		} else if word.contains(char) {
			let newObfuscatedWord = self.updateObfuscation(with: char)
			if self.word == newObfuscatedWord {
				return .win(newObfuscatedWord)
			} else {
				return .correct(newObfuscatedWord)
			}
		} else if self.incorrectLetters.count >= Rules.numberOfGuesses {
			self.guessedLetters.append(char)
			self.incorrectLetters.append(char)
			return .lose(self.word)
		} else {
			self.guessedLetters.append(char)
			self.incorrectLetters.append(char)
			return .wrong(char)
		}
	}
	
	internal func updateObfuscation(with letter: Character) -> String {
		self.guessedLetters.append(letter)
		self.obfuscatedWord = Hangman.obfuscate(word: self.word, excluding: guessedLetters)
		return self.obfuscatedWord
	}
	
	// MARK: - Util
	
	internal static func obfuscate(word: String, excluding excludedCharacters: [Character] = []) -> String {
		var newString = ""
		for char in word {
			if excludedCharacters.contains(char) {
				newString.append(char)
			} else if self.characterIsValid(char) {
				newString.append("_")
			} else {
				newString.append(char)
			}
		}
		return newString
	}
	
	internal static func characterIsValid(_ character: Character) -> Bool {
		guard let scalar = UnicodeScalar("\(character)") else { return false }
		return CharacterSet.uppercaseLetters.contains(scalar)
	}
	
}
