//
//  WeakArrayTests.swift
//  RaveTests
//
//  Created by Stefan Vasiljevic on 2017-10-31.
//  Copyright © 2017 WeMesh. All rights reserved.
//

import XCTest
import Foundation
@testable import Rave


class EventTests: XCTestCase {
	
	class ObservableClass {
		var propertyChangedEvent = Event<String>()
		
		var property: String = "" {
			didSet {
				self.propertyChangedEvent.raise(sender: self, arguments: self.property)
			}
		}
	}
	
	class SubscriberClass {
		private let observableClass: ObservableClass
		private var handle: Event<String>.Handle? = nil
		private var newObservableValue: String? = nil
		
		init(_ newObservableClass: ObservableClass) {
			self.observableClass = newObservableClass
			self.handle = self.observableClass.propertyChangedEvent.subscribe() { [weak self] sender, arg in
				self?.newObservableValue = arg
			}
		}
	}
	
	
	func testHandleRemovedFromSubscribersWhenScopeIsLost() {
		let completionExpectation = expectation(description: "Completed")
		let expectedHandlerCount = 0
		
		// TEST
		
		let observableClass = ObservableClass()
		var subscriberClass: SubscriberClass? = SubscriberClass(observableClass)
		subscriberClass = nil
		observableClass.propertyChangedEvent.trim() {
			completionExpectation.fulfill()
		}
		
		//ASSESS
		
		waitForExpectations(timeout: 1) { error in
			XCTAssert(observableClass.propertyChangedEvent.handlerCount == expectedHandlerCount && subscriberClass == nil, "Subribers not 0!")
		}
	}
	
    func testValueChangedAndEventHandlerWasCalledWithTheProperValue() {
		let completionExpectation = expectation(description: "Completed")
		let expectedArgumentValue = "Test test test"
		var actualArgumentValue: String? = nil
		
		//TEST
		
		let obsClass = ObservableClass()
		let handle: Event.Handle? = obsClass.propertyChangedEvent.subscribe(queue: DispatchQueue.main) { sender, arg in
			actualArgumentValue = arg
			completionExpectation.fulfill()
		}
		obsClass.property = expectedArgumentValue
		
		//ASSESS
		
		waitForExpectations(timeout: 1) { error in
			XCTAssertNil(error, error?.localizedDescription ?? "")
			XCTAssert(expectedArgumentValue == actualArgumentValue && handle != nil)
		}
    }
	
	func testValueChangedAndAllHandlersAreCalled() {
		let completionExpectation = expectation(description: "Completed")
		completionExpectation.expectedFulfillmentCount = 3
		let expectedArgumentValue = "Test"
		var actualArgumentValue1: String? = nil
		var actualArgumentValue2: String? = nil
		var actualArgumentValue3: String? = nil
		
		//TEST
		
		let eventHandler1: (Any, String) -> () = { sender, arg in
			actualArgumentValue1 = arg
			completionExpectation.fulfill()
		}
		let eventHandler2: (Any, String) -> () = { sender, arg in
			actualArgumentValue2 = arg
			completionExpectation.fulfill()
		}
		let eventHandler3: (Any, String) -> () = { sender, arg in
			actualArgumentValue3 = arg
			completionExpectation.fulfill()
		}
		
		let obsClass = ObservableClass()
		let handle1: Event.Handle? = obsClass.propertyChangedEvent.subscribe(eventHandler1)
		let handle2: Event.Handle? = obsClass.propertyChangedEvent.subscribe(eventHandler2)
		let handle3: Event.Handle? = obsClass.propertyChangedEvent.subscribe(eventHandler3)
		obsClass.property = expectedArgumentValue
		
		
		//ASSESS
		
		waitForExpectations(timeout: 1) { error in
			XCTAssertNil(error, error?.localizedDescription ?? "")
			XCTAssert(expectedArgumentValue == actualArgumentValue1 && expectedArgumentValue == actualArgumentValue2 && expectedArgumentValue == actualArgumentValue3 && handle1 != nil && handle2 != nil && handle3 != nil)
		}
	}
	
	func testHandlerNotCalledWhenHandleBecomesNil() {
		let expectedHandlerCount = 0
		
		//TEST
		
		let eventHandler: (Any, String) -> () = { sender, arg in
			XCTFail() // - ASSESS
		}
		
		let obsClass = ObservableClass()
		var handle: Event.Handle? = obsClass.propertyChangedEvent.subscribe(eventHandler)
		handle = nil
		obsClass.property = "TEST"
		
		//ASSESS
		
		XCTAssert(obsClass.propertyChangedEvent.handlerCount == expectedHandlerCount && handle == nil)
	}
	
	func testValueChangedAnd2OutOf3HandlersAreCalledWhenOneHandleIsSetToNil() {
		let completionExpectation = expectation(description: "Completed")
		completionExpectation.expectedFulfillmentCount = 2
		let expectedArgumentValue = "TEST"
		var actualArgumentValue1: String? = nil
		var actualArgumentValue3: String? = nil
		
		//TEST
		
		let eventHandler1: (Any, String) -> () = { sender, arg in
			actualArgumentValue1 = arg
			completionExpectation.fulfill()
		}
		let eventHandler2: (Any, String) -> () = { sender, arg in
			XCTFail()
		}
		let eventHandler3: (Any, String) -> () = { sender, arg in
			actualArgumentValue3 = arg
			completionExpectation.fulfill()
		}
		
		let obsClass = ObservableClass()
		let handle1: Event.Handle? = obsClass.propertyChangedEvent.subscribe(eventHandler1)
		var handle2: Event.Handle? = obsClass.propertyChangedEvent.subscribe(eventHandler2)
		handle2 = nil
		let handle3: Event.Handle? = obsClass.propertyChangedEvent.subscribe(eventHandler3)
		
		obsClass.property = expectedArgumentValue
		
		//ASSESS
		
		waitForExpectations(timeout: 1) { error in
			XCTAssertNil(error, error?.localizedDescription ?? "")
			XCTAssert(expectedArgumentValue == actualArgumentValue1 && expectedArgumentValue == actualArgumentValue3 && obsClass.propertyChangedEvent.handlerCount == 2 && handle1 != nil && handle2 == nil && handle3 != nil)
		}
	}

}
