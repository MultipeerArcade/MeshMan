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
    
    // MARK: - Event Handles
    
    private var questionRecievedHandle: Event<QuestionNetUtil.QuestionMessage>.Handle?
    
    private var answerRecievedHanle: Event<QuestionNetUtil.AnswerMessage>.Handle?
    
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

        // Do any additional setup after loading the view.
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
        let updateIndex = questions.answerQuestion(questions.currentQuestion, with: answer)
        questionListController.update(at: updateIndex)
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
        answerRecievedHanle = netUtil.answerMessageRecieved.subscribe({ [weak self] in
            self?.handleAnswerRecieved($1)
        })
    }
    
    private func handleQuestionRecieved(_ message: QuestionNetUtil.QuestionMessage) {
        let updateIndex = questions.addQuestion(message.number, question: message.question)
        questionListController.insert(at: updateIndex)
    }
    
    private func handleAnswerRecieved(_ message: QuestionNetUtil.AnswerMessage) {
        let updateIndex = questions.answerQuestion(message.number, with: message.answer)
        questionListController.update(at: updateIndex)
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
