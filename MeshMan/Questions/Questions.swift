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
    func questions(_ questions: Questions, stateUpdatedFromOldState oldState: QuestionsGameState, toNewState newState: QuestionsGameState)
}

final class Questions: DataHandler {
    
    // MARK: - Types
    
    enum Rules {
        static let numberOfQuestions = 20
    }
    
    enum GuessJudgement: String, Codable {
        case correct
        case incorrect
    }
    
    struct Question: Codable, Comparable, Equatable {
        let number: Int
        let question: String
        let answer: Answer?
        
        func answered(answer: Answer) -> Question {
            return Question(number: number, question: question, answer: answer)
        }
        
        static func <(lhs: Question, rhs: Question) -> Bool {
            return lhs.number < rhs.number
        }
        
        static func ==(lhs: Question, rhs: Question) -> Bool {
            return lhs.number == rhs.number
        }
    }
    
    enum Answer: String, Codable {
        case yes = "Yes"
        case no = "No"
        case sometimes = "Sometimes"
        case sortOf = "Sort Of"
        case unknown = "Unknown"
        
        case person = "Person"
        case place = "Place"
        case thing = "Thing"
        case idea = "Idea"
    }
    
    enum SanitizationResult {
        case sanitized(String)
        case invalid
    }
    
    // MARK: - Internal Members
    
    private(set) var state: QuestionsGameState
    
    private let networkHandler: NetworkHandler
    
    var currentGuesser: MCPeerID {
        return MCPeerID.from(data: state.guesserData)
    }
    
    var currentPicker: MCPeerID {
        return MCPeerID.from(data: state.pickerData)
    }
    
    var iAmGuesser: Bool {
        return MCManager.shared.isThisMe(currentGuesser)
    }
    
    var iAmPicker: Bool {
        return MCManager.shared.isThisMe(currentPicker)
    }
    
    weak var delegate: QuestionsDelegate?
    
    var gameInfo: (Game, Data) {
        let stateData = try! JSONEncoder().encode(state)
        return (.twentyQuestions, stateData)
    }
    
    // MARK: - Initialization
    
    init(state: QuestionsGameState, networkHandler: NetworkHandler) {
        self.state = state
        self.networkHandler = networkHandler
    }
    
    // MARK: -
    
    func nextGuesser() -> MCPeerID {
        return networkHandler.turnHelper.getPeerAfterMe(otherThan: currentPicker)
    }
    
    // MARK: - DataHandler
    
    func process(data: Data) {
        let command = try! JSONDecoder().decode(QuestionsCommand.self, from: data)
        switch command.commandType {
        case .setState:
            let newState = try! JSONDecoder().decode(QuestionsGameState.self, from: command.payload)
            update(from: newState)
        }
    }
    
    func handleLostPeers(_ lostPeers: [MCPeerID]) {
        if lostPeers.contains(currentPicker) {
            pickerDisconnected()
        } else if iAmPicker && MCManager.shared.session.connectedPeers.isEmpty {
            allGuessersDisconnected()
        } else {
            nonEssentialPlayersDisconnected()
        }
    }
    
    // MARK: - Handling Disconnections
    
    private func pickerDisconnected() {
        RootManager.shared.handleReconnect(for: [currentPicker], completion: { allPeersReconnected in
            if !allPeersReconnected {
                RootManager.shared.goToLobby()
            }
        })
    }
    
    private func allGuessersDisconnected() {
        RootManager.shared.handleReconnectForArbitraryPeer { [weak self] foundNewPeer in
            guard foundNewPeer else {
                RootManager.shared.goToLobby()
                return
            }
            self?.fixUpGuesserIfNeeded()
        }
    }
    
    private func nonEssentialPlayersDisconnected() {
        RootManager.shared.handleReconnectForArbitraryPeer { [weak self] _ in
            self?.fixUpGuesserIfNeeded()  // We dont care if we got them back, just fix up the guesser if needed
        }
    }
    
    private func fixUpGuesserIfNeeded() {
        if !MCManager.shared.turnHelper.allPeers.contains(self.currentGuesser) {
            let nextGuesserData = nextGuesser().dataRepresentation
            let newState = state.withGuesser(nextGuesserData)
            send(newState: newState)
            update(from: newState)
        }
    }
    
    // MARK: -
    
    private func update(from newState: QuestionsGameState) {
        let oldState = state
        state = newState
        DispatchQueue.main.async {
            self.delegate?.questions(self, stateUpdatedFromOldState: oldState, toNewState: newState)
        }
    }
    
    // MARK: - UI Event Handling
    
    func ask(question: String) -> SanitizationResult {
        let result = Questions.sanitize(question: question)
        switch result {
        case .invalid:
            break
        case .sanitized(let sanitizedQuestion):
            let newState = state.ask(question: sanitizedQuestion)
            send(newState: newState)
            update(from: newState)
        }
        return result
    }
    
    func answer(questionAtIndex questionIndex: Int, with answer: Answer) {
        let nextGuesserData = nextGuesser().dataRepresentation
        let newState = state.answer(questionAtIndex: questionIndex, with: answer, nextGuesserData: nextGuesserData)
        send(newState: newState)
        update(from: newState)
    }
    
    func answerLastQuestion(with answer: Answer) {
        let nextGuesserData = nextGuesser().dataRepresentation
        let newState = state.answer(questionAtIndex: state.questions.endIndex - 1, with: answer, nextGuesserData: nextGuesserData)
        send(newState: newState)
        update(from: newState)
    }
    
    func guess(answer: String) -> SanitizationResult {
        let result = Questions.sanitize(guess: answer)
        switch result {
        case .invalid:
            break
        case .sanitized(let sanitizedGuess):
            let newState = state.guess(answer: sanitizedGuess)
            send(newState: newState)
            update(from: newState)
        }
        return result
    }
    
    func judgeGuess(judgement: GuessJudgement) {
        let newState = state.judgeGuess(judgement: judgement)
        send(newState: newState)
        update(from: newState)
    }
    
    func send(newState: QuestionsGameState) {
        let stateData = try! JSONEncoder().encode(newState)
        let questionsCommand = QuestionsCommand(commandType: .setState, payload: stateData)
        let questionsCommandData = try! JSONEncoder().encode(questionsCommand)
        let gameDataCommand = GameDataCommand(payload: questionsCommandData)
        networkHandler.sendGameCommand(command: gameDataCommand)
    }
    
    func done() {
        RootManager.shared.goToLobby()
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
