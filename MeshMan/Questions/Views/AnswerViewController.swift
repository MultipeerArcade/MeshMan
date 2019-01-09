//
//  AnswerViewController.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/24/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import UIKit

class AnswerViewController: UIViewController, QuestionsDelegate {
    
    // MARK: - Constants
    
    enum Constants {
        static let subjectTimerDuration: TimeInterval = 2
    }
    
    private enum Strings {
        static let subjectLabelHiddenText = NSLocalizedString("Tap to Show Subject", comment: "Text shown on the subject label in 20 questions when it is hidden")
    }
    
    // MARK: - Outlets
    
    @IBOutlet private weak var subjectButton: UIButton!
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var sometimesButton: UIButton!
    @IBOutlet private weak var unknownButton: UIButton!
    
    // MARL: - Private Members
    
    private var questions: Questions!
    
    private var questionListController: QuestionListViewController!
    
    private var waitAlert: UIAlertController!
    
    private let feedbackGenerator = UINotificationFeedbackGenerator()
    
    private var subjectTimer: Timer?
    
    // MARK: - New Instance
    
    static func newInstance(subject: String, netUtil: QuestionNetUtil, turnManager: QuestionsTurnManager) -> AnswerViewController {
        let answerVC = Storyboards.questions.instantiateViewController(withIdentifier: "answer") as! AnswerViewController
        answerVC.questions = Questions(subject: subject, netUtil: netUtil, firstPicker: MCManager.shared.peerID)
        answerVC.questions.delegate = answerVC
        return answerVC
    }
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        subjectButton.setTitle(Strings.subjectLabelHiddenText, for: .normal)
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
    
    private func showSubject() {
        startSubjectTimer() {
            self.hideSubject()
        }
        subjectButton.setTitle(questions.subject, for: .normal)
    }
    
    private func hideSubject() {
        subjectButton.setTitle(Strings.subjectLabelHiddenText, for: .normal)
        subjectTimer?.invalidate()
    }
    
    private func startSubjectTimer(block: @escaping () -> Void) {
        let timer = Timer(timeInterval: Constants.subjectTimerDuration, repeats: false, block: { _ in
            block()
        })
        timer.tolerance = Constants.subjectTimerDuration * 0.1
        subjectTimer?.invalidate()
        RunLoop.main.add(timer, forMode: .default)
        subjectTimer = timer
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
    
    private func showFirstQuestion(subject: String) {
        let question = "What is it?"
        let result = questions.ask(question: question)
        process(result: result)
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
    
    private func waitForGuess() {
        setControls(enabled: false)
        let alert = UIAlertController(title: "Get ready!", message: "\(questions.turnManager.currentAsker.displayName) is preparing a guess.", preferredStyle: .alert)
        waitAlert = alert
        present(alert, animated: true)
    }
    
    private func showGuess(_ guess: String) {
        waitAlert?.dismiss(animated: true)
        waitAlert = nil
        feedbackGenerator.notificationOccurred(.success)
        let alert = UIAlertController(title: guess, message: "Is this what you were thinking of?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .default) { (_) in
            self.questions.confirm(correct: true)
        }
        let noAction = UIAlertAction(title: "No", style: .destructive) { (_) in
            self.questions.confirm(correct: false)
        }
        alert.addAction(yesAction)
        alert.addAction(noAction)
        present(alert, animated: true)
    }
    
    private func gameOver(correct: Bool) {
        questions.turnManager.gameOver()
        if questions.turnManager.iAmPicker {
            let subjectSelection = SubjectViewController.newInstance(netUtil: questions.netUtil)
            navigationController?.setViewControllers([subjectSelection], animated: true)
        } else {
            let wait = WaitViewController.newInstance(purpose: .waiting, utilType: .questions(questions.netUtil))
            navigationController?.setViewControllers([wait], animated: true)
        }
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
    
    @IBAction func subjectButtonPressed() {
        showSubject()
    }
    
    private func give(answer: Questions.Answer) {
        let result = questions.answerQuestion(with: answer)
        process(result: result)
    }
    
    // MARK: - QuestionsDelegate
    
    func questions(_ questions: Questions, didUpdateQuestion result: Questions.Result) {
        process(result: result)
    }
    
    func questions(_ questions: Questions, didSetGameStage stage: Questions.GameStage) {
        switch stage {
        case .answer:
            navigationItem.title = "Your Turn"
            feedbackGenerator.notificationOccurred(.success)
            setControls(enabled: true)
        case .question:
            navigationItem.title = "\(questions.turnManager.currentAsker.displayName)'s Turn"
            setControls(enabled: false)
        case .guess:
            waitForGuess()
        case .confirm(guess: let guess):
            navigationItem.title = "Your Turn"
            feedbackGenerator.notificationOccurred(.success)
            showGuess(guess)
        case .gameOver(let correct):
            gameOver(correct: correct)
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

}
