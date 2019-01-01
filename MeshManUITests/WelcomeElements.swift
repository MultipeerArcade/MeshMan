//
//  WelcomeElements.swift
//  MeshManUITests
//
//  Created by Russell Pecka on 12/29/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import Foundation
import XCTest

struct WelcomeElements {
    
    let app: XCUIApplication
    
    var nameField: XCUIElement {
        return app.textFields["nameField"]
    }
    
    var createButton: XCUIElement {
        return app.buttons["create"]
    }
    
    var joinButton: XCUIElement {
        return app.buttons["join"]
    }
    
    var chooseGameAlert: XCUIElement {
        return app.sheets["Choose a game"]
    }
    
    var hangmanButton: XCUIElement {
        return chooseGameAlert.buttons["Hangman"]
    }
    
    var questionsButton: XCUIElement {
        return chooseGameAlert.buttons["20 Questions"]
    }
    
    enum GameSelection {
        case hangman
        case questions
    }
    
    @discardableResult static func createGame(app: XCUIApplication, instance: XCTestCase, name: String = "Test", game: GameSelection) -> String {
        let elements = WelcomeElements(app: app)
        fillNameIfNeeded(elements: elements, name: name)
        let name = elements.nameField.stringValue!
        elements.createButton.tap()
        let expectation = instance.expectation(for: NSPredicate(format: "exists == true"), evaluatedWith: elements.chooseGameAlert, handler: nil)
        instance.wait(for: [expectation], timeout: 3)
        switch game {
        case .hangman:
            elements.hangmanButton.tap()
        case .questions:
            elements.questionsButton.tap()
        }
        instance.waitForBrowserToAppear(app: app)
        return name
    }
    
    private static func fillNameIfNeeded(elements: WelcomeElements, name: String) {
        guard elements.nameField.stringValue.count == 0 else { return }
        elements.nameField.tap()
        elements.nameField.typeText(name)
        elements.nameField.typeText("\r")
    }
    
}

extension XCTestCase {
    func waitForBrowserToAppear(app: XCUIApplication) {
        let browserExpectation = expectation(for: NSPredicate(format: "exists == true"), evaluatedWith: app.otherElements["browser"], handler: nil)
        wait(for: [browserExpectation], timeout: 5)
    }
}
