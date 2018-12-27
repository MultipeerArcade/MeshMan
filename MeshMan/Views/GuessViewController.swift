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
    
    private var turnManager: QuestionsTurnManager!
    
    private var questionListController: QuestionListViewController!
    
    // MARK: - Event Handles
    
    private var questionRecievedHandle: Event<QuestionNetUtil.QuestionMessage>.Handle?
    
    private var answerRecievedHanle: Event<QuestionNetUtil.AnswerMessage>.Handle?
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setControls(enabled: turnManager.iAmAsker)
    }
    
    // MARK: - UI Control
    
    private func setControls(enabled: Bool) {
        _ = enabled ? questionField.becomeFirstResponder() : questionField.resignFirstResponder()
        questionField.isEnabled = enabled
        askButton.isEnabled = enabled
    }
    
    // MARK: -
    
    private func addQuestion(number: Int, question: String) {
        let updateIndex = questions.addQuestion(number, question: question)
        questionListController.insert(at: updateIndex)
        setControls(enabled: false)
    }
    
    private func answerQuestion(number: Int, with answer: Questions.Answer) {
        let updateIndex = questions.answerQuestion(number, with: answer)
        questionListController.update(at: updateIndex)
        turnManager.pickNextAsker()
        if turnManager.iAmAsker {
            setControls(enabled: true)
        }
    }
    
    // MARK: - Input Processing
    
    @IBAction private func askButtonPressed() {
        guard let text = questionField.text else { return }
        addQuestion(number: questions.currentQuestion, question: text)
        broadcast(question: text)
    }
    
    private func broadcast(question: String) {
        let message = QuestionNetUtil.QuestionMessage(number: questions.currentQuestion, question: question)
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
