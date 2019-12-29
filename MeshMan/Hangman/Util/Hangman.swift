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
    func hangman(_ hangman: Hangman, stateUpdatedFromOldState oldState: HangmanGameState?, toNewState newState: HangmanGameState, obfuscationResult: Hangman.WordObfuscationPayload)
}

final class Hangman: DataHandler {
    
    enum GuessResult {
        case correct
        case wrong
        case wordGuessed
        case noMoreGuesses
    }
    
    enum GuessSanitationResult: Error {
        case success(guess: Character)
        case tooLong
        case tooShort
        case invalidCharacter
        case alreadyGuessed
    }
    
    // MARK: - Internal Members
    
    private(set) var state: HangmanGameState
    
    private weak var networkHandler: NetworkHandler!
    
    weak var delegate: HangmanDelegate?
    
    var currentGuesser: MCPeerID {
        return MCPeerID.from(data: state.guesserData)
    }
    
    var iAmPicker: Bool {
        return MCManager.shared.isThisMe(MCPeerID.from(data: state.pickerData))
    }
    
    var iAmGuesser: Bool {
        return MCManager.shared.isThisMe(currentGuesser)
    }
    
    // MARK: - Initialization
    
    init(state: HangmanGameState, networkHandler: NetworkHandler) {
        self.state = state
        self.networkHandler = networkHandler
    }
    
    func getWordObfuscationPayload() -> WordObfuscationPayload {
        return Hangman.obfuscate(word: state.word, excluding: state.guessedCharacters)
    }
    
    // MARK: - DataHandler
    
    func process(data: Data) {
        let command = try! JSONDecoder().decode(HangmanCommand.self, from: data)
        switch command.commandType {
        case .setState:
            let newState = try! JSONDecoder().decode(HangmanGameState.self, from: command.payload)
            update(from: newState)
        }
    }
    
    private func update(from newState: HangmanGameState) {
        let oldState = state
        state = newState
        let obfuscationResult = Hangman.obfuscate(word: newState.word, excluding: newState.guessedCharacters)
        DispatchQueue.main.async {
            self.delegate?.hangman(self, stateUpdatedFromOldState: oldState, toNewState: newState, obfuscationResult: obfuscationResult)
        }
    }
    
    // MARK: - UI Event Handling
    
    func make(guess letter: String) -> GuessSanitationResult {
        let sanitationResult = sanitize(guess: letter)
        switch sanitationResult {
        case .success(guess: let guess):
            let picker = MCPeerID.from(data: state.pickerData)
            let nextGuesserData = networkHandler.turnHelper.getPeerAfterMe(otherThan: picker).dataRepresentation
            let newState = state.make(guess: guess, nextGuesserData: nextGuesserData)
            send(newState: newState)
            update(from: newState)
        default:
            break
        }
        return sanitationResult
    }
    
    func send(newState: HangmanGameState) {
        let stateData = try! JSONEncoder().encode(newState)
        let hangmanCommand = HangmanCommand(commandType: .setState, payload: stateData)
        let hangmanCommandData = try! JSONEncoder().encode(hangmanCommand)
        let gameDataCommand = GameDataCommand(payload: hangmanCommandData)
        networkHandler.sendGameCommand(command: gameDataCommand)
    }
    
    func sanitize(guess: String) -> GuessSanitationResult {
        let trimmed = guess.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard trimmed.count > 0 else { return .tooShort }
        guard trimmed.count == 1 else { return .tooLong }
        let char = trimmed[trimmed.startIndex]
        guard HangmanGameModel.characterIsValid(char) else { return .invalidCharacter }
        guard !state.guessedCharacters.contains(char) else { return .alreadyGuessed }
        return .success(guess: char)
    }
    
    func done() {
        
    }
    
    // MARK: -
    
    struct WordObfuscationPayload {
        let obfuscatedWord: String
        let numberOfBlanks: Int
    }
    
    static func obfuscate(word: String, excluding excludedCharacters: Set<Character> = []) -> WordObfuscationPayload {
        var displayString = ""
        var numberOfBlanks = 0
        let lastIndex = word.count - 1
        for (index, char) in word.enumerated() {
            var toAppend = index == 0 ? "" : " "
            if excludedCharacters.contains(char) {
                toAppend.append(char)
            } else if self.characterIsValid(char) {
                toAppend.append("_")
                numberOfBlanks += 1
            } else {
                toAppend.append(char)
            }
            if lastIndex == index {
                toAppend.append(" ")
            }
            displayString.append(toAppend)
        }
        return WordObfuscationPayload(obfuscatedWord: displayString, numberOfBlanks: numberOfBlanks)
    }
    
    static func characterIsValid(_ character: Character) -> Bool {
        guard let scalar = UnicodeScalar("\(character)") else { return false }
        return CharacterSet.uppercaseLetters.contains(scalar)
    }
	
}
