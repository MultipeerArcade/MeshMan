//
//  WelcomeTests.swift
//  MeshManUITests
//
//  Created by Russell Pecka on 12/29/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import XCTest

class WelcomeTests: XCTestCase {
    
    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launch()
    }
    
    func testStartQuestions() {
        WelcomeElements.createGame(app: app, instance: self, game: .questions)
    }
    
    func testStartHangman() {
        WelcomeElements.createGame(app: app, instance: self, game: .hangman)
    }

}
