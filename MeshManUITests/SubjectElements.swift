//
//  SubjectElements.swift
//  MeshManUITests
//
//  Created by Russell Pecka on 12/31/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import Foundation
import XCTest

struct SubjectElements {
    
    let app: XCUIApplication
    
    var rootView: XCUIElement {
        return app.otherElements["questions.subject"]
    }
    
    var subjectField: XCUIElement {
        return app.textFields["subjectField"]
    }
    
    var doneButton: XCUIElement {
        return app.buttons["doneButton"]
    }
    
    var rulesLabel: XCUIElement {
        return app.staticTexts["rulesLabel"]
    }
    
    static func fillSubject(elements: SubjectElements, with subject: String, done: Bool) {
        elements.subjectField.tap()
        elements.subjectField.typeText(subject)
        if done {
            elements.doneButton.tap()
        }
    }
    
}

extension XCTestCase {
    
    func waitForSubjectToAppear(elements: SubjectElements) {
        let subjectExpectation = expectation(for: NSPredicate(format: "exists == true"), evaluatedWith: elements.rootView, handler: nil)
        wait(for: [subjectExpectation], timeout: 5)
    }
    
}
