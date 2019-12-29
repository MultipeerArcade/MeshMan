//
//  LobbyViewController.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/28/19.
//  Copyright © 2019 Russell Pecka. All rights reserved.
//

import UIKit

class LobbyViewController: UIViewController, StatusHandler {
    
    private enum Strings {
        static let waiting = NSLocalizedString("Waiting...", comment: "Text that shows when a user is in the lobby waiting for a game to start")
    }
    
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var twentyQuestionsButton: UIButton!
    @IBOutlet private weak var hangmanButton: UIButton!
    
    private var iAmHost: Bool!
    
    static func newInstance(asHost: Bool) -> LobbyViewController {
        let vc = UIStoryboard(name: "Lobby", bundle: nil).instantiateInitialViewController() as! LobbyViewController
        vc.iAmHost = asHost
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configure()
    }
    
    private func configure() {
        if !iAmHost {
            statusLabel.text = Strings.waiting
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
                RootManager.shared.navigationController.setViewControllers([hangmanVC], animated: true)
                MCManager.shared.setGame(game: .hangman, payload: state)
            }
        }
        present(wordSelectionVC, animated: true)
    }
    
    @IBAction func twentyQuestionsButtonPressed() {
        
    }
    
    // MARK: - StatusHandler
    
    func process(status: String) {
        print(status)
    }

}
