//
//  QuestionsNetUtil.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/24/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class QuestionNetUtil: NSObject, NetUtil {
    
    // MARK: - Types
    
    private enum MessageType {
        case choosingSubject
        case startGame
        case question(QuestionMessage)
        case answer(AnswerMessage)
    }
    
    struct StartGamePayload: Codable {
        let firstPickerData: Data
        let subject: String
        
        var firstPicker: MCPeerID { return MCPeerID.from(data: firstPickerData) }
        
        init(subject: String, firstPicker: MCPeerID) {
            self.subject = subject
            self.firstPickerData = firstPicker.dataRepresentation
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
    
    struct GuessMessage: Codable {
        let guess: String
    }
    
    struct GuessConfirmationMessage: Codable {
        let guessWasCorrect: Bool
    }
    
    // MARK: - Internal Members
    
    let session: MCSession
    
    // MARK: - Message Events
    
    let peerConnectionStateChanged = Event<PeerConnectionState>()
    
    let waitMessageRecieved = Event<WaitMessage>()
    
    let startMessageRecieved = Event<StartMessage>()
    
    let questionMessageRecieved = Event<QuestionMessage>()
    
    let answerMessageRecieved = Event<AnswerMessage>()
    
    let guessMessageRecieved = Event<GuessMessage>()
    
    let guessConfirmationRecieved = Event<GuessConfirmationMessage>()
    
    // MARK: - Initialization
    
    init(session: MCSession = MCManager.shared.session) {
        self.session = session
        super.init()
        self.session.delegate = self
    }
    
    // MARK: - MCSessionDelegate
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        peerConnectionStateChanged.raise(sender: self, arguments: (peer: peerID, state: state))
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let choosingSubjectMessage = try? JSONDecoder().decode(WaitMessage.self, from: data) {
            waitMessageRecieved.raise(sender: self, arguments: choosingSubjectMessage)
        } else if let startGameMessage = try? JSONDecoder().decode(StartMessage.self, from: data) {
            startMessageRecieved.raise(sender: self, arguments: startGameMessage)
        } else if let questionMessage = try? JSONDecoder().decode(QuestionMessage.self, from: data) {
            questionMessageRecieved.raise(sender: self, arguments: questionMessage)
        } else if let answerMessage = try? JSONDecoder().decode(AnswerMessage.self, from: data) {
            answerMessageRecieved.raise(sender: self, arguments: answerMessage)
        } else if let guessMessage = try? JSONDecoder().decode(GuessMessage.self, from: data) {
            guessMessageRecieved.raise(sender: self, arguments: guessMessage)
        } else if let confirmation = try? JSONDecoder().decode(GuessConfirmationMessage.self, from: data) {
            guessConfirmationRecieved.raise(sender: self, arguments: confirmation)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) { }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) { }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) { }
    
}
