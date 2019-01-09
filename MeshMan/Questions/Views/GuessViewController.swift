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

    static func newInstance(subject: String, netUtil: QuestionNetUtil, firstPicker: MCPeerID) -> GuessViewController {
        let vc = Storyboards.questions.instantiateViewController(withIdentifier: "questions") as! GuessViewController
        vc.questions = Questions(subject: subject, netUtil: netUtil, firstPicker: firstPicker)
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
        if questions.turnManager.iAmAsker {
            feedbackGenerator.notificationOccurred(.success)
            navigationItem.title = "Final Guess"
            questionField.placeholder = "Guess"
            askButton.setTitle("Guess", for: .normal)
            guessing = true
            setControls(enabled: true)
        } else {
            setControls(enabled: false)
            let alert = UIAlertController(title: "Oh boy!", message: "\(questions.turnManager.currentAsker) is deciding on a final guess.", preferredStyle: .alert)
            navigationItem.title = "\(questions.turnManager.currentAsker)'s Final Guess"
            waitingAlert = alert
            present(alert, animated: true)
        }
    }
    
    // MARK: -
    
    private func process(result: Questions.Result) {
        switch result {
        case .insert(let row):
            questionListController.insert(at: row)
        case .update(let row):
            questionListController.update(at: row)
        }
    }
    
    // MARK: - Input Processing
    
    @IBAction private func askButtonPressed() {
        guard let text = questionField.text else { return }
        process(textInput: text)
    }
    
    private func process(textInput text: String) {
        if !guessing {
            switch Questions.sanitize(question: text) {
            case .invalid:
                showInvalidQuestionMessage(for: text)
            case .sanitized(question: let question):
                let result = questions.ask(question: question)
                process(result: result)
                questionField.text = nil
            }
        } else {
            switch Questions.sanitize(guess: text) {
            case .invalid:
                showInvalidGuessMessage(for: text)
            case .sanitized(let guess):
                confirmAndMake(guess: guess)
            }
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
        questions.make(guess: guess)
        questionField.text = nil
        showWaitingMessage(guess: guess)
    }
    
    private func showWaitingMessage(guess: String) {
        waitingAlert?.dismiss(animated: true)
        setControls(enabled: false)
        let alert = UIAlertController(title: "Drumroll, please!", message: "Waiting for \(questions.turnManager.currentPicker.displayName) to decide on \(guess).", preferredStyle: .alert)
        waitingAlert = alert
        present(alert, animated: true)
    }
    
    private func showResultMessage(correct: Bool) {
        waitingAlert?.dismiss(animated: true)
        let title = correct ? "You win!" : "You lose."
        let message = "The word was: \(questions.subject)"
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Okay", style: .default) { (_) in
            self.gameOver()
        }
        alert.addAction(okayAction)
        present(alert, animated: true)
    }
    
    private func gameOver() {
        questions.turnManager.gameOver()
        if questions.turnManager.iAmPicker {
            let subjectSelection = SubjectViewController.newInstance(netUtil: questions.netUtil)
            navigationController?.setViewControllers([subjectSelection], animated: true)
        } else {
            let wait = WaitViewController.newInstance(purpose: .waiting, utilType: .questions(questions.netUtil))
            navigationController?.setViewControllers([wait], animated: true)
        }
    }
    
    // MARK: - QuestionsDelegate
    
    func questions(_ questions: Questions, didUpdateQuestion result: Questions.Result) {
        process(result: result)
    }
    
    func questions(_ questions: Questions, didSetGameStage stage: Questions.GameStage) {
        switch stage{
        case .answer:
            navigationItem.title = "\(questions.turnManager.currentPicker.displayName)'s Turn"
            setControls(enabled: false)
        case .question:
            if questions.turnManager.iAmAsker {
                navigationItem.title = "Your Turn"
                feedbackGenerator.notificationOccurred(.success)
                setControls(enabled: true)
            } else {
                navigationItem.title = "\(questions.turnManager.currentAsker)'s Turn"
                setControls(enabled: false)
            }
        case .guess:
            changeToGuess()
        case .confirm(guess: let guess):
            if !questions.turnManager.iAmAsker {
                showWaitingMessage(guess: guess)
            }
        case .gameOver(correct: let correct):
            showResultMessage(correct: correct)
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
