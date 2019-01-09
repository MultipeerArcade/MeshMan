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
		static let testWordFullObfuscation = "_ _   _ _ _   _ _ _ _   _ _ _ _ ?   _ _ _   1 2 3 . "
		static let exluded: [Character] = ["I", "E", "N"]
		static let testWordExcludingExcluded = "I _   _ _ E   _ E _ N   _ E _ N ?   _ E _   1 2 3 . "
		static let someInvalidCharacters = "!.,#@?/\"+=1234567890"
		static let validCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		static let testWordExcludingE = "__ __E _E_N _E_N? _E_ 123."
        static let whitespaces: [String] = [" ", "  ", "\n", " \n", "\t", " \t"]
        static let longGuesses = ["hello", "hi", "bye", "goodbye "]
	}
	
    private var testman: HangmanGameModel!
    
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
			XCTAssert(!HangmanGameModel.characterIsValid(char), "Hangman claimed that \(char) was a valid character")
		}
	}
	
	func testValidCharacters() {
		for char in Constants.validCharacters {
			XCTAssert(HangmanGameModel.characterIsValid(char), "Hangman claimed that \(char) was an invalid character")
		}
	}
    
	func testObfuscation() {
		let result = HangmanGameModel.obfuscate(word: Constants.testWord)
		XCTAssert(Constants.testWordFullObfuscation == result.displayString, "Obfuscation did not meet expectations: \(result)")
	}
	
	func testObfuscationWithExclusion() {
		let result = HangmanGameModel.obfuscate(word: Constants.testWord, excluding: Constants.exluded)
		XCTAssert(Constants.testWordExcludingExcluded == result.displayString, "Obfuscation with exclusion did not meet expectations: \(result)")
	}
    
    func testGuessSanitationWhitespace() {
        testman = HangmanGameModel(word: Constants.testWord)
        for entry in Constants.whitespaces {
            switch testman.sanitize(guess: entry) {
            case .tooShort:
                break
            default:
                XCTFail("Sanitation should fail with invalid entry: \"\(entry)\"")
            }
        }
    }
    
    func testGuessSanitationLong() {
        testman = HangmanGameModel(word: Constants.testWord)
        for entry in Constants.longGuesses {
            switch testman.sanitize(guess: entry) {
            case .tooLong:
                break
            default:
                XCTFail("Sanitation should fail with invalid entry: \"\(entry)\"")
            }
        }
    }
    
    func testGuessSanitationInvalid() {
        testman = HangmanGameModel(word: Constants.testWord)
        for entry in Constants.someInvalidCharacters {
            switch testman.sanitize(guess: "\(entry)") {
            case .invalidCharacter:
                break
            default:
                XCTFail("Sanitation should fail with invalid entry: \"\(entry)\"")
            }
        }
    }
    
    func testGuessSanitationAlreadyGuessed() {
        testman = HangmanGameModel(word: Constants.testWord)
        _ = testman.guess(letter: "A")
        switch testman.sanitize(guess: "A") {
        case .alreadyGuessed:
            break
        default:
            XCTFail("Model failed to recognize that \"A\" was already guessed")
        }
        
        _ = testman.guess(letter: "Z")
        switch testman.sanitize(guess: "Z") {
        case .alreadyGuessed:
            break
        default:
            XCTFail("Model failed to recognized that \"Z\" was already guessed")
        }
    }
    
    func testGuessCorrect() {
        testman = HangmanGameModel(word: Constants.testWord)
        switch testman.guess(letter: "B") {
        case .correct:
            break
        default:
            XCTFail("Guess should have been correct")
        }
    }
    
    func testWordGuessed() {
        testman = HangmanGameModel(word: Constants.testWord)
        _ = testman.guess(letter: "I")
        _ = testman.guess(letter: "S")
        _ = testman.guess(letter: "T")
        _ = testman.guess(letter: "H")
        _ = testman.guess(letter: "E")
        _ = testman.guess(letter: "B")
        _ = testman.guess(letter: "A")
        _ = testman.guess(letter: "N")
        _ = testman.guess(letter: "M")
        switch testman.guess(letter: "Y") {
        case .wordGuessed:
            break
        default:
            XCTFail("Word should be guessed when the last char is guessed")
        }
    }
    
}
