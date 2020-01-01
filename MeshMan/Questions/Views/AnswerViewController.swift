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
    
    static func newInstance(questions: Questions) -> AnswerViewController {
        let answerVC = Storyboards.questions.instantiateViewController(withIdentifier: "answer") as! AnswerViewController
        answerVC.questions = questions
        answerVC.questions.delegate = answerVC
        return answerVC
    }
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        subjectButton.setTitle(Strings.subjectLabelHiddenText, for: .normal)
        configure(for: questions.state)
        if questions.state.questions.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
                self.showFirstQuestion(subject: self.questions.state.subject)
            }
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
        subjectButton.setTitle(questions.state.subject, for: .normal)
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
    
    private func showFirstQuestion(subject: String) {
        let question = "What is it?"
        _ = questions.ask(question: question)
        let alert = UIAlertController(title: "First Question", message: "What is \(questions.state.subject)?", preferredStyle: .alert)
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
        let alert = UIAlertController(title: "Get ready!", message: "\(questions.currentGuesser.displayName) is preparing a guess.", preferredStyle: .alert)
        waitAlert = alert
        present(alert, animated: true)
    }
    
    private func showGuess(_ guess: String) {
        waitAlert?.dismiss(animated: true)
        waitAlert = nil
        feedbackGenerator.notificationOccurred(.success)
        let alert = UIAlertController(title: guess, message: "Is this what you were thinking of?", preferredStyle: .alert)
        let yesAction = UIAlertAction(title: "Yes", style: .default) { (_) in
            self.questions.judgeGuess(judgement: .correct)
        }
        let noAction = UIAlertAction(title: "No", style: .destructive) { (_) in
            self.questions.judgeGuess(judgement: .incorrect)
        }
        alert.addAction(yesAction)
        alert.addAction(noAction)
        present(alert, animated: true)
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
        questions.answerLastQuestion(with: answer)
    }
    
    // MARK: - QuestionsDelegate
    
    func questions(_ questions: Questions, stateUpdatedFromOldState oldState: QuestionsGameState, toNewState newState: QuestionsGameState) {
        questionListController.updateState(from: oldState, to: newState)
        configure(for: newState)
    }
    
    // MARK: -
    
    private func configure(for state: QuestionsGameState) {
        switch state.gameProgress {
        case .waitingForAnswer:
            navigationItem.title = "Your Turn"
            feedbackGenerator.notificationOccurred(.success)
            setControls(enabled: true)
        case .waitingForQuestion:
            navigationItem.title = "\(questions.currentGuesser.displayName)'s Turn"
            setControls(enabled: false)
        case .waitingForGuess:
            waitForGuess()
        case .waitingForGuessJudgement(let guess):
            navigationItem.title = "Your Turn"
            feedbackGenerator.notificationOccurred(.success)
            showGuess(guess)
        case .wordGuessedCorrectly, .wordGuessedIncorrectly:
            questions.done()
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
