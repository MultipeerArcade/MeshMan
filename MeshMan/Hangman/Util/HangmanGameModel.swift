//
//  HangmanGameModel.swift
//  MeshMan
//
//  Created by Russell Pecka on 1/8/19.
//  Copyright © 2019 Russell Pecka. All rights reserved.
//

import Foundation

final class HangmanGameModel {
    
    // MARK: - Types
    
    enum Rules {
        static let numberOfGuesses = 9
        static let maxCharacters = 100
        static let minCharacters = 3
        static let wordSelectionBlurb = NSLocalizedString("The word you choose must be no shorter than %d characters and no longer than %d characters. Any characters other than numbers and letters will be shown to your opponents.\n\nFor Example:\n\nTHE CAT'S MEOW\nwill become\n_ _ _   _ _ _ ' _   _ _ _ _", comment: "Writeup of the rules around choosing a word in hangman")
    }
    
    enum GuessResult {
        case correct(String)
        case wrong(Character)
        case wordGuessed(String)
        case noMoreGuesses(Character, String)
    }
    
    enum GuessSanitationResult {
        case sanitized(Character)
        case tooLong
        case tooShort
        case invalidCharacter
        case alreadyGuessed
    }
    
    enum ChoiceValidity {
        case tooShort, tooLong, good
    }
    
    // MARK: - Internal Members
    
    private(set) var obfuscatedWord: String
    
    let numberOfBlanks: Int
    
    private(set) var incorrectLetters = [Character]()
    
    // MARK: - Private Members
    
    private let word: String
    
    private var guessedLetters = [Character]()
    
    // MARK: - Initialization
    
    init(word: String) {
        self.word = HangmanGameModel.sanitize(word: word)
        let (displayString, _, numberOfBlanks) = HangmanGameModel.obfuscate(word: word)
        self.obfuscatedWord = displayString
        self.numberOfBlanks = numberOfBlanks
    }
    
    func guess(letter: Character) -> GuessResult {
        if word.contains(letter) {
            guessedLetters.append(letter)
            let (displayString, comparisonString, _) = HangmanGameModel.obfuscate(word: word, excluding: guessedLetters)
            obfuscatedWord = displayString
            if word == comparisonString {
                return .wordGuessed(comparisonString)
            } else {
                return .correct(displayString)
            }
        } else {
            guessedLetters.append(letter)
            incorrectLetters.append(letter)
            if incorrectLetters.count >= Rules.numberOfGuesses {
                return .noMoreGuesses(letter, word)
            } else {
                return .wrong(letter)
            }
        }
    }
    
    func sanitize(guess: String) -> GuessSanitationResult {
        let trimmed = guess.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard trimmed.count > 0 else { return .tooShort }
        guard trimmed.count == 1 else { return .tooLong }
        let char = trimmed[trimmed.startIndex]
        guard HangmanGameModel.characterIsValid(char) else { return .invalidCharacter }
        guard !guessedLetters.contains(char) else { return .alreadyGuessed }
        return .sanitized(char)
    }
    
    // MARK: -
    
    private static func sanitize(word: String) -> String {
        return word.uppercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    static func obfuscate(word: String, excluding excludedCharacters: [Character] = []) -> (displayString: String, comparisonString: String, numberOfBlanks: Int) {
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
    
    static func checkValidChoice(_ text: String) -> ChoiceValidity {
        var count = 0
        for character in text.uppercased() {
            if self.characterIsValid(character) { count += 1 }
        }
        guard count >= HangmanGameModel.Rules.minCharacters else { return .tooShort }
        guard count <= HangmanGameModel.Rules.maxCharacters else { return .tooLong }
        return .good
    }
    
    static func characterIsValid(_ character: Character) -> Bool {
        guard let scalar = UnicodeScalar("\(character)") else { return false }
        return CharacterSet.uppercaseLetters.contains(scalar)
    }
    
}
