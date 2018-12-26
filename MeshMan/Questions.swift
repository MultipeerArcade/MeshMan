//
//  Questions.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/24/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import Foundation

final class Questions {
    
    // MARK: - Types
    
    enum Rules {
        static let numberOfQuestions = 20
    }
    
    struct Question {
        let number: Int
        let question: String
        var answer: Answer?
    }
    
    enum Answer: String, Codable {
        case yes
        case no
        case sometimes
        case unknown
    }
    
    // MARK: - Private Members
    
    private let subject: String
    
    private var questions = [Question]()
    
    // MARK: - Initialization
    
    init(subject: String) {
        self.subject = subject
    }
    
    // MARK: - Gameplay
    
    func ask(question: String) {
        
    }
    
    func give(answer: Answer) {
        
    }
    
}
