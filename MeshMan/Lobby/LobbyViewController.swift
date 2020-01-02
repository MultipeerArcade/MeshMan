//
//  LobbyViewController.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/28/19.
//  Copyright © 2019 Russell Pecka. All rights reserved.
//

import MultipeerConnectivity
import UIKit

class LobbyViewController: UIViewController, StatusHandler {
    
    private enum Strings {
        static let waiting = NSLocalizedString("Waiting for %@ to start a game...", comment: "Text that shows when a user is in the lobby waiting for a game to start")
    }
    
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var twentyQuestionsButton: UIButton!
    @IBOutlet private weak var hangmanButton: UIButton!
    
    static func newInstance() -> LobbyViewController {
        let vc = UIStoryboard(name: "Lobby", bundle: nil).instantiateInitialViewController() as! LobbyViewController
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
    }
    
    private func configure() {
        let iAmHost = MCManager.shared.iAmHost
        if !iAmHost {
            statusLabel.text = String(format: Strings.waiting, MCManager.shared.host.displayName)
        }
        hangmanButton.isEnabled = iAmHost
        twentyQuestionsButton.isEnabled = iAmHost
    }
    
    @IBAction func hangmanButtonPressed() {
        let wordSelectionVC = WordSelectionViewController.newInstance { (result) in
            switch result {
            case .cancelled:
                break
            case .choseWord(let word):
                let state = HangmanGameState(word: word, pickerIDData: MCManager.shared.peerID.dataRepresentation, guesserIDData: MCManager.shared.turnHelper.getFirstPeer(otherThan: [MCManager.shared.peerID]).dataRepresentation)
                let hangman = MCManager.shared.makeHangman(state: state)
                let hangmanVC = HangmanViewController.newInstance(hangman: hangman)
                
                RootManager.shared.setGameController(to: hangmanVC)
                let stateData = try! JSONEncoder().encode(state)
                MCManager.shared.setGame(game: .hangman, payloadData: stateData)
            }
        }
        present(wordSelectionVC, animated: true)
    }
    
    @IBAction func twentyQuestionsButtonPressed() {
        let subjectSelectionVC = SubjectViewController.newInstance { (result) in
            switch result {
            case .cancelled:
                break
            case .choseSubject(let subject):
                let state = QuestionsGameState(subject: subject, asking: true, pickerData: MCManager.shared.peerID.dataRepresentation, guesserData: MCManager.shared.turnHelper.getFirstPeer(otherThan: [MCManager.shared.peerID]).dataRepresentation)
                let questions = MCManager.shared.makeQuestions(state: state)
                let answerVC = AnswerViewController.newInstance(questions: questions)
                RootManager.shared.setGameController(to: answerVC)
                let stateData = try! JSONEncoder().encode(state)
                MCManager.shared.setGame(game: .twentyQuestions, payloadData: stateData)
            }
        }
        present(subjectSelectionVC, animated: true)
    }
    
    // MARK: - StatusHandler
    
    func process(status: String) {
        print(status)
    }

}
