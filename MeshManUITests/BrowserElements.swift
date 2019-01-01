//
//  BrowserElements.swift
//  MeshManUITests
//
//  Created by Russell Pecka on 12/31/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import Foundation
import XCTest

struct BrowserElements {
    
    let app: XCUIApplication
    
    var doneButton: XCUIElement {
        return app.navigationBars.buttons["Done"]
    }
    
    func peer(named name: String) -> XCUIElement {
        return app.tables.staticTexts[name]
    }
    
    static func invite(app: XCUIApplication, instance: XCTestCase, peers: [String]) {
        let elements = BrowserElements(app: app)
        for peer in peers {
            let peerExistsExpectation = instance.expectation(for: NSPredicate(format: "exists == true"), evaluatedWith: elements.peer(named: peer), handler: nil)
            instance.wait(for: [peerExistsExpectation], timeout: 4)
            elements.peer(named: peer).tap()
        }
    }
    
}
