//
//  HangmanTests.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/28/17.
//  Copyright © 2017 Russell Pecka. All rights reserved.
//

import XCTest
@testable import MeshMan

class HangmanTests: XCTestCase {
	
	private enum Constants {
		static let testWord = "IS THE BEAN MEAN? YES 123."
		static let testWordFullObfuscation = "__ ___ ____ ____? ___ 123."
		static let exluded: [Character] = ["I", "E", "N"]
		static let testWordExcludingExcluded = "I_ __E _E_N _E_N? _E_ 123."
		static let someInvalidCharacters = "!.,#@?/\"+= 1234567890"
		static let validCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		static let testWordExcludingE = "__ __E _E_N _E_N? _E_ 123."
	}
	
	private let testman = Hangman(word: Constants.testWord)
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
	
	func testInvalidCharacters() {
		for char in Constants.someInvalidCharacters {
			XCTAssert(!Hangman.characterIsValid(char), "Hangman claimed that \(char) was a valid character")
		}
	}
	
	func testValidCharacters() {
		for char in Constants.validCharacters {
			XCTAssert(Hangman.characterIsValid(char), "Hangman claimed that \(char) was an invalid character")
		}
	}
    
	func testObfuscation() {
		let result = Hangman.obfuscate(word: Constants.testWord)
		XCTAssert(Constants.testWordFullObfuscation == result, "Obfuscation did not meet expectations: \(result)")
	}
	
	func testObfuscationWithExclusion() {
		let result = Hangman.obfuscate(word: Constants.testWord, excluding: Constants.exluded)
		XCTAssert(Constants.testWordExcludingExcluded == result, "Obfuscation with exclusion did not meet expectations: \(result)")
	}
	
	func testGuess() {
		var result = self.testman.guess(letter: "e")
		switch result {
		case .correct:
			break
		default:
			XCTAssert(false, "Hangman said that the test word did not contain E or that E had already been guessed")
		}
		
		result = self.testman.guess(letter: "4")
		switch result {
		case .invalid:
			break
		default:
			XCTAssert(false, "Hangman did not say that guessing 4 is invalid")
		}
		
		result = self.testman.guess(letter: "E")
		switch result {
		case .alreadyGuessed:
			break
		default:
			XCTAssert(false, "Hangman did not say that E had already been guessed")
		}
		
		result = self.testman.guess(letter: "a")
		result = self.testman.guess(letter: "m")
		result = self.testman.guess(letter: "s")
		result = self.testman.guess(letter: "n")
		result = self.testman.guess(letter: "b")
		result = self.testman.guess(letter: "y")
		result = self.testman.guess(letter: "i")
		result = self.testman.guess(letter: "t")
		result = self.testman.guess(letter: "h")
		switch result {
		case .win:
			break
		default:
			XCTAssert(false, "The result was not a win")
		}
	}
    
}
