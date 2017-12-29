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
		static let numberOfGuesses = 9
	}
	
	private let word: String
	
	internal private(set) var obfuscatedWord: String
	
	private var guessedLetters = [Character]()
	
	internal private(set) var incorrectLetters = [Character]()
	
	init(word: String) {
		self.word = Hangman.sanitize(word: word)
		self.obfuscatedWord = Hangman.obfuscate(word: self.word).displayString
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
			self.guessedLetters.append(char)
			let (displayString, comparisonString) = Hangman.obfuscate(word: self.word, excluding: guessedLetters)
			self.obfuscatedWord = displayString
			if self.word == comparisonString {
				return .win(comparisonString)
			} else {
				return .correct(displayString)
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
	
	// MARK: - Util
	
	internal static func sanitize(word: String) -> String {
		return word.uppercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
	}
	
	internal static func obfuscate(word: String, excluding excludedCharacters: [Character] = []) -> (displayString: String, comparisonString: String) {
		var displayString = ""
		var comparisonString = ""
		let lastIndex = word.count - 1
		for (index, char) in word.enumerated() {
			var toAppend = index == 0 ? "" : " "
			if excludedCharacters.contains(char) {
				comparisonString.append(char)
				toAppend.append(char)
			} else if self.characterIsValid(char) {
				comparisonString.append("_")
				toAppend.append("_")
			} else {
				comparisonString.append(char)
				toAppend.append(char)
			}
			if lastIndex == index {
				toAppend.append(" ")
			}
			displayString.append(toAppend)
		}
		return (displayString, comparisonString)
	}
	
	internal static func characterIsValid(_ character: Character) -> Bool {
		guard let scalar = UnicodeScalar("\(character)") else { return false }
		return CharacterSet.uppercaseLetters.contains(scalar)
	}
	
}
