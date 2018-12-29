//
//  AnswerViewController.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/24/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import UIKit

class AnswerViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet private weak var subjectLabel: UILabel!
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var sometimesButton: UIButton!
    @IBOutlet private weak var unknownButton: UIButton!
    
    // MARL: - Private Members
    
    private var netUtil: QuestionNetUtil! {
        didSet {
            if let netUtil = self.netUtil { self.setUp(netUtil: netUtil) }
        }
    }
    
    private var questions: Questions!
    
    private var turnManager: QuestionsTurnManager!
    
    private var questionListController: QuestionListViewController!
    
    private var waitAlert: UIAlertController!
    
    private let feedbackGenerator = UINotificationFeedbackGenerator()
    
    // MARK: - Event Handles
    
    private var questionRecievedHandle: Event<QuestionNetUtil.QuestionMessage>.Handle?
    
    private var answerRecievedHandle: Event<QuestionNetUtil.AnswerMessage>.Handle?
    
    private var guessRecievedHandle: Event<QuestionNetUtil.GuessMessage>.Handle?
    
    // MARK: - New Instance
    
    static func newInstance(subject: String, netUtil: QuestionNetUtil, turnManager: QuestionsTurnManager) -> AnswerViewController {
        let answerVC = Storyboards.questions.instantiateViewController(withIdentifier: "answer") as! AnswerViewController
        answerVC.questions = Questions(subject: subject)
        answerVC.netUtil = netUtil
        answerVC.turnManager = turnManager
        return answerVC
    }
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        subjectLabel.text = questions.subject
        setControls(enabled: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            self.showFirstQuestion(subject: self.questions.subject)
        }
    }
    
    // MARK: - UI Control
    
    private func setControls(enabled: Bool) {
        yesButton.isEnabled = enabled
        noButton.isEnabled = enabled
        sometimesButton.isEnabled = enabled
        unknownButton.isEnabled = enabled
    }
    
    // MARK: -
    
    private func addQuestion(number: Int, question: String) {
        let result = questions.addQuestion(number, question: question)
        process(result: result)
        navigationItem.title = "Your Turn"
        feedbackGenerator.notificationOccurred(.success)
        setControls(enabled: true)
    }
    
    private func answerQuestion(number: Int, with answer: Questions.Answer) {
        let result = questions.answerQuestion(number, with: answer)
        process(result: result)
        turnManager.pickNextAsker()
        navigationItem.title = "\(turnManager.currentAsker.displayName)'s Turn"
        setControls(enabled: false)
    }
    
    private func process(result: Questions.Result) {
        switch result {
        case .insert(let row):
            questionListController.insert(at: row)
        case .update(let row, done: let done):
            questionListController.update(at: row)
            if done {
                waitForGuess()
            }
        }
    }
    
    private func showFirstQuestion(subject: String) {
        let question = "What is it?"
        addQuestion(number: 1, question: question)
        broadcastFirstQuestion(question)
        let alert = UIAlertController(title: "First Question", message: "What is \(questions.subject)?", preferredStyle: .alert)
        let personAction = UIAlertAction(title: "Person", style: .default) { (_) in
            self.give(answer: .person)
        }
        let placeAction = UIAlertAction(title: "Place", style: .default) { (_) in
            self.give(answer: .place)
        }
        let thingAction = UIAlertAction(title: "Thing", style: .default) { (_) in
            self.give(answer: .thing)
        }
        let ideaAction = UIAlertAction(title: "Idea", style: .default) { (_) in
            self.give(answer: .idea)
        }
        alert.addAction(personAction)
        alert.addAction(placeAction)
        alert.addAction(thingAction)
        alert.addAction(ideaAction)
        present(alert, animated: true)
    }
    
    private func broadcastFirstQuestion(_ question: String) {
        let q = Questions.Question(number: 1, question: question, answer: nil)
        let message = QuestionNetUtil.QuestionMessage(number: q.number, question: q.question)
        netUtil.send(message: message)
    }
    
    private func waitForGuess() {
        setControls(enabled: false)
        let alert = UIAlertController(title: "Get ready!", message: "\(turnManager.currentAsker.displayName) is preparing a guess.", preferredStyle: .alert)
        waitAlert = alert
        present(alert, animated: true)
    }
    
    private func showGuess(_ guess: String) {
        waitAlert.dismiss(animated: true)
        feedbackGenerator.notificationOccurred(.success)
        let alert = UIAlertController(title: guess, message: "Is this what you were thinking of?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .default) { (_) in
            self.gameOver(correct: true)
        }
        let noAction = UIAlertAction(title: "No", style: .destructive) { (_) in
            self.gameOver(correct: false)
        }
        alert.addAction(yesAction)
        alert.addAction(noAction)
        present(alert, animated: true)
    }
    
    private func gameOver(correct: Bool) {
        broadcast(correct: correct)
        turnManager.gameOver()
        if turnManager.iAmPicker {
            let subjectSelection = SubjectViewController.newInstance(netUtil: netUtil)
            navigationController?.setViewControllers([subjectSelection], animated: true)
        } else {
            let wait = WaitViewController.newInstance(purpose: .waiting, utilType: .questions(netUtil))
            navigationController?.setViewControllers([wait], animated: true)
        }
    }
    
    private func broadcast(correct: Bool) {
        let message = QuestionNetUtil.GuessConfirmationMessage(guessWasCorrect: correct)
        netUtil.send(message: message)
    }
    
    // MARK: - Input Handling
    
    @IBAction private func yesButtonPressed() {
        give(answer: .yes)
    }
    
    @IBAction private func noButtonPressed() {
        give(answer: .no)
    }
    
    @IBAction private func sometimesButtonPressed() {
        give(answer: .sometimes)
    }
    
    @IBAction private func unknownButtonPressed() {
        give(answer: .unknown)
    }
    
    private func give(answer: Questions.Answer) {
        broadcast(answer: answer) // updating the model increments the current question
        answerQuestion(number: questions.currentQuestion, with: answer)
    }
    
    func broadcast(answer: Questions.Answer) {
        let message = QuestionNetUtil.AnswerMessage(number: questions.currentQuestion, answer: answer)
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
            self?.showGuess($1.guess)
        })
    }
    
    private func handleQuestionRecieved(_ message: QuestionNetUtil.QuestionMessage) {
        addQuestion(number: message.number, question: message.question)
    }
    
    private func handleAnswerRecieved(_ message: QuestionNetUtil.AnswerMessage) {
        answerQuestion(number: message.number, with: message.answer)
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
