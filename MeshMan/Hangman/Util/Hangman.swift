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
    func hangman(_ hangman: Hangman, didRecieveGuess result: HangmanGameModel.GuessResult)
    func hangman(_ hangman: Hangman, didSetGuesser iAmGuesser: Bool)
}

final class Hangman {
    
    // MARK: - Internal Members
    
    let netUtil: HangmanNetUtil
    
    let turnManager: HangmanTurnManager
    
    let gameModel: HangmanGameModel
    
    weak var delegate: HangmanDelegate?
    
    // MARK: Event Handles
    
    private var newGuessRecievedHandle: Event<HangmanNetUtil.NewGuessMessage>.Handle?
    
    // MARK: - Initialization
	
    init(word: String, netUtil: HangmanNetUtil, firstPicker: MCPeerID) {
        gameModel = HangmanGameModel(word: word)
		
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
        let result = gameModel.guess(letter: message.guess)
        switch result {
        case .correct, .wrong:
            turnComplete()
        default: break
        }
        delegate?.hangman(self, didRecieveGuess: result)
    }
    
    // MARK: - UI Event Handling
    
    func make(guess letter: Character) -> HangmanGameModel.GuessResult {
        let guessMessage = HangmanNetUtil.NewGuessMessage(guess: letter, sender: MCManager.shared.peerID)
        netUtil.send(message: guessMessage)
        let result = gameModel.guess(letter: letter)
        return result
    }
    
    private func turnComplete() {
        turnManager.pickNextGuesser()
        delegate?.hangman(self, didSetGuesser: turnManager.iAmGuesser)
    }
	
}
