//
//  QuestionsNetUtil.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/24/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class QuestionNetUtil: NSObject, MCSessionDelegate {
    
    // MARK: - Types
    
    private enum MessageType {
        case choosingSubject
        case startGame
        case question(QuestionMessage)
        case answer(AnswerMessage)
    }
    
    struct ChoosingSubjectMessage: Codable {
        let subjectMessage = "Placeholder"
    }
    
    struct StartGameMessage: Codable {
        let subject: String
        
        init(subject: String) {
            self.subject = subject
        }
    }
    
    struct QuestionMessage: Codable {
        let number: Int
        let question: String
    }
    
    struct AnswerMessage: Codable {
        let number: Int
        let answer: Questions.Answer
    }
    
    // MARK: - Private Members
    
    private let session: MCSession
    
    // MARK: - Message Events
    
    let choosingSubjectMessageRecieved = Event<ChoosingSubjectMessage>()
    
    let startGameMessageRecieved = Event<StartGameMessage>()
    
    let questionMessageRecieved = Event<QuestionMessage>()
    
    let answerMessageRecieved = Event<AnswerMessage>()
    
    // MARK: - Initialization
    
    init(session: MCSession) {
        self.session = session
        super.init()
        self.session.delegate = self
    }
    
    // MARK: - Sending Messages
    
    func sendChoosingSubjectMessage() {
        guard let encodedData = try? JSONEncoder().encode(ChoosingSubjectMessage()) else { return }
        try? self.session.send(encodedData, toPeers: self.session.connectedPeers, with: .reliable)
    }
    
    func sendStartGameMessage(_ message: StartGameMessage) {
        guard let encodedData = try? JSONEncoder().encode(message) else { return }
        try? session.send(encodedData, toPeers: session.connectedPeers, with: .reliable)
    }
    
    func sendQuestionMessage(_ message: QuestionMessage) {
        guard let encodedData = try? JSONEncoder().encode(message) else { return }
        try? self.session.send(encodedData, toPeers: self.session.connectedPeers, with: .reliable)
    }
    
    func sendAnswerMessage(_ message: AnswerMessage) {
        guard let encodedData = try? JSONEncoder().encode(message) else { return }
        try? self.session.send(encodedData, toPeers: self.session.connectedPeers, with: .reliable)
    }
    
    // MARK: - MCSessionDelegate
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let choosingSubjectMessage = try? JSONDecoder().decode(ChoosingSubjectMessage.self, from: data) {
            choosingSubjectMessageRecieved.raise(sender: self, arguments: choosingSubjectMessage)
        } else if let startGameMessage = try? JSONDecoder().decode(StartGameMessage.self, from: data) {
            startGameMessageRecieved.raise(sender: self, arguments: startGameMessage)
        } else if let questionMessage = try? JSONDecoder().decode(QuestionMessage.self, from: data) {
            questionMessageRecieved.raise(sender: self, arguments: questionMessage)
        } else if let answerMessage = try? JSONDecoder().decode(AnswerMessage.self, from: data) {
            answerMessageRecieved.raise(sender: self, arguments: answerMessage)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) { }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) { }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) { }
    
}
