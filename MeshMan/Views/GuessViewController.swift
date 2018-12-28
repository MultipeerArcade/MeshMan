//
//  GuessViewController.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/24/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import UIKit

class GuessViewController: UIViewController {

    // MARK: - Outlets
    
    @IBOutlet private weak var questionField: UITextField!
    @IBOutlet private weak var askButton: UIButton!
    
    // MARK: - New Instance

    static func newInstance(subject: String, netUtil: QuestionNetUtil, turnManager: QuestionsTurnManager) -> GuessViewController {
        let vc = Storyboards.questions.instantiateViewController(withIdentifier: "questions") as! GuessViewController
        vc.questions = Questions(subject: subject)
        vc.netUtil = netUtil
        vc.turnManager = turnManager
        return vc
    }
    
    // MARK: - Private Members
    
    private var netUtil: QuestionNetUtil! {
        didSet {
            if let netUtil = self.netUtil { self.setUp(netUtil: netUtil) }
        }
    }
    
    private var questions: Questions!
    
    private var guessing = false
    
    private var turnManager: QuestionsTurnManager!
    
    private var questionListController: QuestionListViewController!
    
    private var waitingAlert: UIAlertController!
    
    // MARK: - Event Handles
    
    private var questionRecievedHandle: Event<QuestionNetUtil.QuestionMessage>.Handle?
    
    private var answerRecievedHandle: Event<QuestionNetUtil.AnswerMessage>.Handle?
    
    private var guessRecievedHandle: Event<QuestionNetUtil.GuessMessage>.Handle?
    
    private var guessConfirmationRecievedHandle: Event<QuestionNetUtil.GuessConfirmationMessage>.Handle?
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setControls(enabled: false)
    }
    
    // MARK: - UI Control
    
    private func setControls(enabled: Bool) {
        _ = enabled ? questionField.becomeFirstResponder() : questionField.resignFirstResponder()
        questionField.isEnabled = enabled
        askButton.isEnabled = enabled
    }
    
    private func changeToGuess() {
        if turnManager.iAmAsker {
            questionField.placeholder = "Guess"
            askButton.setTitle("Guess", for: .normal)
            guessing = true
        } else {
            setControls(enabled: false)
            let alert = UIAlertController(title: "Oh boy!", message: "\(turnManager.currentAsker) is deciding on a final guess.", preferredStyle: .alert)
            waitingAlert = alert
            present(alert, animated: true)
        }
    }
    
    // MARK: -
    
    private func addQuestion(number: Int, question: String) {
        let result = questions.addQuestion(number, question: question)
        process(result: result)
        setControls(enabled: false)
    }
    
    private func answerQuestion(number: Int, with answer: Questions.Answer) {
        let result = questions.answerQuestion(number, with: answer)
        process(result: result)
        turnManager.pickNextAsker()
        if turnManager.iAmAsker {
            setControls(enabled: true)
        }
    }
    
    private func process(result: Questions.Result) {
        switch result {
        case .insert(let row):
            questionListController.insert(at: row)
        case .update(let row, done: let done):
            questionListController.update(at: row)
            if done {
                changeToGuess()
            }
        }
    }
    
    // MARK: - Input Processing
    
    @IBAction private func askButtonPressed() {
        guard let text = questionField.text else { return }
        if !guessing {
            addQuestion(number: questions.currentQuestion, question: text)
            broadcast(question: text)
            questionField.text = ""
        } else {
            confirmAndMake(guess: text)
        }
        
    }
    
    private func confirmAndMake(guess: String) {
        let alert = UIAlertController(title: "Is \"\(guess)\" your final answer?", message: "Your guess will be sent to the leader.", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .default) { _ in
            self.make(guess: guess)
            self.questionField.text = ""
        }
        let noAction = UIAlertAction(title: "No", style: .cancel) { _ in
            self.setControls(enabled: true)
        }
        alert.addAction(yesAction)
        alert.addAction(noAction)
        present(alert, animated: true)
    }
    
    private func make(guess: String) {
        broadcast(guess: guess)
        showWaitingMessage(guess: guess)
    }
    
    private func showWaitingMessage(guess: String) {
        waitingAlert?.dismiss(animated: true)
        setControls(enabled: false)
        let alert = UIAlertController(title: "Drumroll, please!", message: "Waiting for \(turnManager.currentPicker.displayName) to decide on \(guess).", preferredStyle: .alert)
        waitingAlert = alert
        present(alert, animated: true)
    }
    
    private func showResultMessage(correct: Bool) {
        waitingAlert.dismiss(animated: true)
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
        turnManager.gameOver()
        if turnManager.iAmPicker {
            let subjectSelection = SubjectViewController.newInstance(netUtil: netUtil)
            navigationController?.setViewControllers([subjectSelection], animated: true)
        } else {
            let wait = WaitViewController.newInstance(purpose: .waiting, utilType: .questions(netUtil))
            navigationController?.setViewControllers([wait], animated: true)
        }
    }
    
    private func broadcast(question: String) {
        let message = QuestionNetUtil.QuestionMessage(number: questions.currentQuestion, question: question)
        netUtil.send(message: message)
    }
    
    private func broadcast(guess: String) {
        let message = QuestionNetUtil.GuessMessage(guess: guess)
        netUtil.send(message: message)
    }
    
    // MARK: - Message Processing
    
    private func setUp(netUtil: QuestionNetUtil) {
        questionRecievedHandle = netUtil.questionMessageRecieved.subscribe({ [weak self] in
            self?.handleQuestionRecieved($1)
        })
        answerRecievedHandle = netUtil.answerMessageRecieved.subscribe({ [weak self] in
            self?.handleAnswerRecieved($1)
        })
        guessRecievedHandle = netUtil.guessMessageRecieved.subscribe({ [weak self] in
            self?.handleGuessRecieved($1)
        })
        guessConfirmationRecievedHandle = netUtil.guessConfirmationRecieved.subscribe({ [weak self] in
            self?.showResultMessage(correct: $1.guessWasCorrect)
        })
    }
    
    private func handleQuestionRecieved(_ message: QuestionNetUtil.QuestionMessage) {
        addQuestion(number: message.number, question: message.question)
    }
    
    private func handleAnswerRecieved(_ message: QuestionNetUtil.AnswerMessage) {
        answerQuestion(number: message.number, with: message.answer)
    }
    
    private func handleGuessRecieved(_ message: QuestionNetUtil.GuessMessage) {
        showWaitingMessage(guess: message.guess)
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

}
