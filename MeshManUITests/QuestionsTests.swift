//
//  QuestionsTests.swift
//  MeshManUITests
//
//  Created by Russell Pecka on 12/29/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import XCTest

class QuestionsTests: XCTestCase {
    
    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launch()
    }
    
    func testLeadGame() {
        let displayName = WelcomeElements.createGame(app: app, instance: self, game: .questions)
        let browserElements = BrowserElements(app: app)
        let doneButtonExpectation = expectation(for: NSPredicate(format: "isEnabled == true"), evaluatedWith: browserElements.doneButton, handler: nil)
        let joinExpectation = expectation(description: "Dummy should accept an invite")
        let dummyName = Random.randomName()
        let advDummy = AdvertiserDummy(displayName: dummyName, acceptFrom: displayName, expectation: joinExpectation)
        advDummy.advertiser.startAdvertisingPeer()
        BrowserElements.invite(app: app, instance: self, peers: [dummyName])
        wait(for: [doneButtonExpectation, joinExpectation], timeout: 6)
        browserElements.doneButton.tap()
        let subjectElements = SubjectElements(app: app)
        waitForSubjectToAppear(elements: subjectElements)
        let subject = "Car"
        SubjectElements.fillSubject(elements: subjectElements, with: subject, done: true)
        let answersElements = AnswersElements(app: app)
        waitForAnswersToAppear(elements: answersElements)
        waitForFirstQuestionToAppear(elements: answersElements)
        answersElements.pick(answer: .thing)
    }

}
