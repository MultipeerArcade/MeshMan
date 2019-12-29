//
//  GuessViewController.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/24/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import MultipeerConnectivity
import UIKit

class GuessViewController: UIViewController, QuestionsDelegate, UITextFieldDelegate {

    // MARK: - Outlets
    
    @IBOutlet private weak var questionField: UITextField!
    @IBOutlet private weak var askButton: UIButton!
    
    // MARK: - New Instance

    static func newInstance(questions: Questions) -> GuessViewController {
        let vc = Storyboards.questions.instantiateViewController(withIdentifier: "questions") as! GuessViewController
        vc.questions = questions
        vc.questions.delegate = vc
        return vc
    }
    
    // MARK: - Private Members
    
    private var questions: Questions!
    
    private var guessing = false
    
    private var questionListController: QuestionListViewController!
    
    private var waitingAlert: UIAlertController!
    
    private let feedbackGenerator = UINotificationFeedbackGenerator()
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setControls(enabled: false)
    }
    
    // MARK: - UI Control
    
    private func setControls(enabled: Bool) {
        questionField.isEnabled = enabled
        askButton.isEnabled = enabled
        _ = enabled ? questionField.becomeFirstResponder() : questionField.resignFirstResponder()
    }
    
    private func changeToGuess() {
        if questions.iAmGuesser {
            feedbackGenerator.notificationOccurred(.success)
            navigationItem.title = "Final Guess"
            questionField.placeholder = "Guess"
            askButton.setTitle("Guess", for: .normal)
            guessing = true
            setControls(enabled: true)
        } else {
            setControls(enabled: false)
            let alert = UIAlertController(title: "Oh boy!", message: "\(questions.currentGuesser) is deciding on a final guess.", preferredStyle: .alert)
            navigationItem.title = "\(questions.currentGuesser)'s Final Guess"
            waitingAlert = alert
            present(alert, animated: true)
        }
    }
    
    // MARK: - Input Processing
    
    @IBAction private func askButtonPressed() {
        guard let text = questionField.text else { return }
        process(textInput: text)
    }
    
    private func process(textInput text: String) {
        if !guessing {
            switch questions.ask(question: text) {
            case .invalid:
                showInvalidQuestionMessage(for: text)
            case .sanitized:
                questionField.text = nil
            }
        } else {
            confirmAndMake(guess: text)
        }
    }
    
    private func showInvalidQuestionMessage(for question: String) {
        let alert = UIAlertController(title: "Invalid Question", message: "\"\(question)\" is not a valid entry.", preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Okay", style: .default)
        alert.addAction(okayAction)
        present(alert, animated: true)
    }
    
    private func showInvalidGuessMessage(for guess: String) {
        let alert = UIAlertController(title: "Invalid Guess", message: "\"\(guess)\" is not a valid entry.", preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Okay", style: .default)
        alert.addAction(okayAction)
        present(alert, animated: true)
    }
    
    private func confirmAndMake(guess: String) {
        let alert = UIAlertController(title: "Is \"\(guess)\" your final answer?", message: "Your guess will be sent to the leader.", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
            self.make(guess: guess)
        }
        let noAction = UIAlertAction(title: "No", style: .cancel) { _ in
            self.setControls(enabled: true)
        }
        alert.addAction(yesAction)
        alert.addAction(noAction)
        present(alert, animated: true)
    }
    
    private func make(guess: String) {
        switch questions.guess(answer: guess) {
        case .invalid:
            showInvalidGuessMessage(for: guess)
        case .sanitized:
            questionField.text = nil
        }
    }
    
    private func showWaitingMessage(guess: String) {
        waitingAlert?.dismiss(animated: true)
        setControls(enabled: false)
        let alert = UIAlertController(title: "Drumroll, please!", message: "Waiting for \(questions.currentPicker.displayName) to decide on \(guess).", preferredStyle: .alert)
        waitingAlert = alert
        present(alert, animated: true)
    }
    
    private func showResultMessage(correct: Bool) {
        waitingAlert?.dismiss(animated: true)
        let title = correct ? "You win!" : "You lose."
        let message = "The word was: \(questions.state.subject)"
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Okay", style: .default) { (_) in
            self.questions.done()
        }
        alert.addAction(okayAction)
        present(alert, animated: true)
    }
    
    // MARK: - QuestionsDelegate
    
    func questions(_ questions: Questions, stateUpdatedFromOldState oldState: QuestionsGameState, toNewState newState: QuestionsGameState) {
        questionListController.updateState(from: oldState, to: newState)
        switch newState.gameProgress {
        case .waitingForAnswer:
            navigationItem.title = "\(questions.currentPicker.displayName)'s Turn"
            setControls(enabled: false)
        case .waitingForQuestion:
            if questions.iAmGuesser {
                navigationItem.title = "Your Turn"
                feedbackGenerator.notificationOccurred(.success)
                setControls(enabled: true)
            } else {
                navigationItem.title = "\(questions.currentGuesser.displayName)'s Turn"
                setControls(enabled: false)
            }
        case .waitingForGuess:
            changeToGuess()
        case .waitingForGuessJudgement:
            showWaitingMessage(guess: questions.state.guess ?? "error")
        case .wordGuessedCorrectly:
            showResultMessage(correct: true)
        case .wordGuessedIncorrectly:
            showResultMessage(correct: false)
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        switch identifier {
        case "questionList":
            questionListController = segue.destination as? QuestionListViewController
            questionListController.questions = questions
        default:
            return
        }
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text else { return true }
        process(textInput: text)
        return true
    }

}
