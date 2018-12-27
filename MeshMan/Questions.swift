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
    
    // MARK: - Internal Members
    
    private(set) var currentQuestion = 1
    
    private(set) var questions = [Question]()
    
    // MARK: - Private Members
    
    private let subject: String
    
    // MARK: - Initialization
    
    init(subject: String) {
        self.subject = subject
    }
    
    // MARK: - Gameplay
    
    func addQuestion(_ number: Int, question: String) -> Int {
        let index: Int
        let q = Question(number: number, question: question, answer: nil)
        if let previous = questions.firstIndex(where: { $0.number == number - 1 }) {
            questions.insert(q, at: previous + 1)
            index = previous + 1
        } else {
            index = questions.count
            questions.append(q)
        }
        return index
    }
    
    func answerQuestion(_ number: Int, with answer: Questions.Answer) -> Int {
        defer { currentQuestion += 1 }
        for (index, existing) in questions.enumerated() {
            guard existing.number == number else { continue }
            let updatedQuestion = Question(number: number, question: existing.question, answer: answer)
            questions[index] = updatedQuestion
            return index
        }
        return 0
    }
    
}
