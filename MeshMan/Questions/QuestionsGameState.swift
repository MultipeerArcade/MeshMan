//
//  QuestionsGameState.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/28/19.
//  Copyright © 2019 Russell Pecka. All rights reserved.
//

import Foundation

class QuestionsGameState: Codable {
    
    enum GameProgress {
        case waitingForQuestion
        case waitingForAnswer
        case waitingForGuess
        case waitingForGuessJudgement(String)
        case wordGuessedCorrectly
        case wordGuessedIncorrectly
    }
    
    let subject: String
    
    let questions: [Questions.Question]
    
    let asking: Bool
    
    let guess: String?
    
    let judgement: Questions.GuessJudgement?
    
    private(set) lazy var gameProgress: GameProgress = {
        if let guess = guess {
            if let judgement = judgement {
                switch judgement {
                case .correct:
                    return .wordGuessedCorrectly
                case .incorrect:
                    return .wordGuessedIncorrectly
                }
            } else {
                return .waitingForGuessJudgement(guess)
            }
        } else if !asking {
            return .waitingForAnswer
        } else if questions.count >= Questions.Rules.numberOfQuestions {
            return .waitingForGuess
        } else {
            return .waitingForQuestion
        }
    }()
    
    let pickerData: Data
    
    let guesserData: Data
    
    init(subject: String, questions: [Questions.Question] = [], asking: Bool, guess: String? = nil, judgement: Questions.GuessJudgement? = nil, pickerData: Data, guesserData: Data) {
        self.subject = subject
        self.questions = questions
        self.asking = asking
        self.guess = guess
        self.judgement = judgement
        self.pickerData = pickerData
        self.guesserData = guesserData
    }
    
    func ask(question: String) -> QuestionsGameState {
        var newQuestionList = questions
        newQuestionList.append(Questions.Question(number: questions.count + 1, question: question, answer: nil))
        return QuestionsGameState(subject: subject, questions: newQuestionList, asking: false, pickerData: pickerData, guesserData: guesserData)
    }
    
    func answer(questionAtIndex questionIndex: Int, with answer: Questions.Answer, nextGuesserData: Data) -> QuestionsGameState {
        let answeredQuestion = questions[questionIndex].answered(answer: answer)
        var newQuestionList = questions
        newQuestionList[questionIndex] = answeredQuestion
        return QuestionsGameState(subject: subject, questions: newQuestionList, asking: true, pickerData: pickerData, guesserData: nextGuesserData)
    }
    
    func guess(answer: String) -> QuestionsGameState {
        return QuestionsGameState(subject: subject, questions: questions, asking: false, guess: answer, pickerData: pickerData, guesserData: guesserData)
    }
    
    func judgeGuess(judgement: Questions.GuessJudgement) -> QuestionsGameState {
        return QuestionsGameState(subject: subject, questions: questions, asking: false, guess: guess, judgement: judgement, pickerData: pickerData, guesserData: guesserData)
    }
    
}
