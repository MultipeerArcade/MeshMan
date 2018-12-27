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
    
    private var turnManager: QuestionsTurnManager!
    
    private var questionListController: QuestionListViewController!
    
    // MARK: - Event Handles
    
    private var questionRecievedHandle: Event<QuestionNetUtil.QuestionMessage>.Handle?
    
    private var answerRecievedHanle: Event<QuestionNetUtil.AnswerMessage>.Handle?
    
    // MARK: - New Instance
    
    static func newInstance(netUtil: QuestionNetUtil, turnManager: QuestionsTurnManager) -> AnswerViewController {
        let answerVC = Storyboards.questions.instantiateViewController(withIdentifier: "answer") as! AnswerViewController
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
    
    @IBAction func yesButtonPressed() {
        broadcast(answer: .yes)
    }
    
    @IBAction func noButtonPressed() {
        broadcast(answer: .no)
    }
    
    @IBAction func sometimesButtonPressed() {
        broadcast(answer: .sometimes)
    }
    
    @IBAction func unknownButtonPressed() {
        broadcast(answer: .unknown)
    }
    
    func broadcast(answer: Questions.Answer) {
        turnManager.currentQuestion += 1
        let message = QuestionNetUtil.AnswerMessage(number: turnManager.currentQuestion, answer: answer)
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
        print("Got question")
        questionListController.addQuestion(message.number, question: message.question)
    }
    
    private func handleAnswerRecieved(_ message: QuestionNetUtil.AnswerMessage) {
        print("Got answer")
        questionListController.updateQuestion(message.number, with: message.answer)
    }
    
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        switch identifier {
        case "questionList":
            questionListController = segue.destination as? QuestionListViewController
        default:
            return
        }
    }

}
