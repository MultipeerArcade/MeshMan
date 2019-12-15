//
//  Questions.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/24/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol QuestionsDelegate: class {
    func questions(_ questions: Questions, didUpdateQuestion result: Questions.Result)
    func questions(_ questions: Questions, didSetGameStage stage: Questions.GameStage)
}

final class Questions {
    
    // MARK: - Types
    
    struct Rules {
        let numberOfQuestions: Int
        
        static let `default` = Rules(numberOfQuestions: 20)
    }
    
    enum GameStage {
        case question
        case answer
        case guess
        case confirm(guess: String)
        case gameOver(correct: Bool)
    }
    
    struct Question {
        let number: Int
        let question: String
        var answer: Answer?
    }
    
    enum Answer: String, Codable {
        case yes = "Yes"
        case no = "No"
        case sometimes = "Sometimes"
        case unknown = "Unkown"
        
        case person = "Person"
        case place = "Place"
        case thing = "Thing"
        case idea = "Idea"
    }
    
    enum Result {
        case insert(Int)
        case update(Int)
    }
    
    enum SanitizationResult {
        case sanitized(String)
        case invalid
    }
    
    // MARK: - Internal Members
    
    private(set) var currentQuestion = 1
    
    private(set) var questions = [Question]()
    
    let subject: String
    
    private(set) var gameStage: GameStage = .question {
        didSet {
            delegate?.questions(self, didSetGameStage: gameStage)
        }
    }
    
    let rules: Rules
    
    let netUtil: QuestionNetUtil
    
    let turnManager: QuestionsTurnManager
    
    weak var delegate: QuestionsDelegate?
    
    // MARK: - Private Members
    
    // MARK: Event Handles
    
    private var questionMessageRecievedHandle: Event<QuestionNetUtil.QuestionMessage>.Handle?
    
    private var answerMessageRecievedHandle: Event<QuestionNetUtil.AnswerMessage>.Handle?
    
    private var guessMessageRecievedHandle: Event<QuestionNetUtil.GuessMessage>.Handle?
    
    private var guessConfirmationRecievedHandle: Event<QuestionNetUtil.GuessConfirmationMessage>.Handle?
    
    // MARK: - Initialization
    
    init(subject: String, rules: Rules = Rules.default, netUtil: QuestionNetUtil, firstPicker: MCPeerID) {
        self.subject = subject
        self.rules = rules
        self.netUtil = netUtil
        self.turnManager = QuestionsTurnManager(session: netUtil.session, myPeerID: MCManager.shared.peerID, firstPicker: firstPicker)
        configure(netUtil: netUtil)
    }
    
    private func configure(netUtil: QuestionNetUtil) {
        questionMessageRecievedHandle = netUtil.questionMessageRecieved.subscribe({ (_, message) in
            self.questionMessageRecieved(message)
        })
        answerMessageRecievedHandle = netUtil.answerMessageRecieved.subscribe({ (_, message) in
            self.answerMessageRecieved(message)
        })
        guessMessageRecievedHandle = netUtil.guessMessageRecieved.subscribe({ (_, message) in
            self.gameStage = .confirm(guess: message.guess)
        })
        guessConfirmationRecievedHandle = netUtil.guessConfirmationRecieved.subscribe({ (_, message) in
            self.gameStage = .gameOver(correct: message.guessWasCorrect)
        })
    }
    
    // MARK: - Network Event Handling
    
    private func questionMessageRecieved(_ message: QuestionNetUtil.QuestionMessage) {
        let result = addQuestion(message.number, question: message.question)
        delegate?.questions(self, didUpdateQuestion: result)
    }
    
    private func answerMessageRecieved(_ message: QuestionNetUtil.AnswerMessage) {
        let result = answerQuestion(message.number, with: message.answer)
        delegate?.questions(self, didUpdateQuestion: result)
    }
    
    // MARK: - UI Event Handling
    
    func ask(question: String) -> Result {
        let questionMessage = QuestionNetUtil.QuestionMessage(number: currentQuestion, question: question) // Make a message before the model is updated
        let result = addQuestion(currentQuestion, question: question)
        netUtil.send(message: questionMessage)
        return result
    }
    
    func answerQuestion(with answer: Answer) -> Result {
        let answerMessage = QuestionNetUtil.AnswerMessage(number: currentQuestion, answer: answer) // Make a message before the model is updated
        let result = answerQuestion(currentQuestion, with: answer)
        netUtil.send(message: answerMessage)
        return result
    }
    
    func make(guess: String) {
        let guessMessage = QuestionNetUtil.GuessMessage(guess: guess)
        netUtil.send(message: guessMessage)
        gameStage = .confirm(guess: guess)
    }
    
    func confirm(correct: Bool) {
        let message = QuestionNetUtil.GuessConfirmationMessage(guessWasCorrect: correct)
        netUtil.send(message: message)
        gameStage = .gameOver(correct: false)
    }
    
    // MARK: - Gameplay
    
    private func addQuestion(_ number: Int, question: String) -> Result {
        defer {
            startAnswerStage()
        }
        let index: Int
        let q = Question(number: number, question: question, answer: nil)
        if let previous = questions.firstIndex(where: { $0.number == number - 1 }) {
            questions.insert(q, at: previous + 1)
            index = previous + 1
        } else {
            index = questions.count
            questions.append(q)
        }
        return .insert(index)
    }
    
    private func answerQuestion(_ number: Int, with answer: Questions.Answer) -> Result {
        defer {
            startAskingStage()
        }
        for (index, existing) in questions.enumerated() {
            guard existing.number == number else { continue }
            let updatedQuestion = Question(number: number, question: existing.question, answer: answer)
            questions[index] = updatedQuestion
            currentQuestion = number + 1
            return .update(index)
        }
        fatalError("Can't answer a question that doesnt exist")
    }
    
    private func startAnswerStage() {
        gameStage = .answer
    }
    
    private func startAskingStage() {
        turnManager.pickNextAsker()
        gameStage = (currentQuestion > rules.numberOfQuestions) ? .guess : .question
    }
    
    // MARK: - Input Sanitization
    
    static func sanitize(subject: String) -> SanitizationResult {
        guard subject.count > 0 else { return .invalid }
        let sanitized = subject.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard sanitized.count > 0 else { return .invalid }
        return .sanitized(sanitized)
    }
    
    static func sanitize(question: String) -> SanitizationResult {
        guard question.count > 0 else { return .invalid }
        var sanitized = question.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard sanitized.count > 0 else { return .invalid }
        if sanitized.last != "?" {
            sanitized.append("?")
        }
        return .sanitized(sanitized)
    }
    
    static func sanitize(guess: String) -> SanitizationResult {
        guard guess.count > 0 else { return .invalid }
        let sanitized = guess.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard sanitized.count > 0 else { return .invalid }
        return .sanitized(sanitized)
    }
    
}
