//
//  AnswersElements.swift
//  MeshManUITests
//
//  Created by Russell Pecka on 12/30/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import Foundation
import XCTest

struct AnswersElements {
    
    let app: XCUIApplication
    
    var rootView: XCUIElement {
        return app.otherElements["questions.answers"]
    }
    
    var firstQuestionAlert: XCUIElement {
        return app.alerts["First Question"]
    }
    
    func pick(answer: Questions.Answer) {
        firstQuestionAlert.buttons[answer.rawValue].tap()
    }
    
}

extension XCTestCase {
    
    func waitForAnswersToAppear(app: XCUIApplication) {
        let elements = AnswersElements(app: app)
        waitForAnswersToAppear(elements: elements)
    }
    
    func waitForAnswersToAppear(elements: AnswersElements) {
        let answersExpectation = expectation(for: NSPredicate(format: "exists == true"), evaluatedWith: elements.rootView, handler: nil)
        wait(for: [answersExpectation], timeout: 4)
    }
    
    func waitForFirstQuestionToAppear(elements: AnswersElements) {
        let alertExpectation = expectation(for: NSPredicate(format: "exists == true"), evaluatedWith: elements.firstQuestionAlert, handler: nil)
        wait(for: [alertExpectation], timeout: 4)
    }
    
}
