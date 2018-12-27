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

    static func newInstance(netUtil: QuestionNetUtil, turnManager: QuestionsTurnManager) -> GuessViewController {
        let vc = Storyboards.questions.instantiateViewController(withIdentifier: "questions") as! GuessViewController
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
    
    private var turnManager: QuestionsTurnManager!
    
    private var questionListController: QuestionListViewController!
    
    // MARK: - Event Handles
    
    private var questionRecievedHandle: Event<QuestionNetUtil.QuestionMessage>.Handle?
    
    private var answerRecievedHanle: Event<QuestionNetUtil.AnswerMessage>.Handle?
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    // MARK: - Input Processing
    
    @IBAction private func askButtonPressed() {
        guard let text = questionField.text else { return }
        broadcast(question: text)
    }
    
    func broadcast(question: String) {
        let message = QuestionNetUtil.QuestionMessage(number: turnManager.currentQuestion, question: question)
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
        turnManager.currentQuestion += 1
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
