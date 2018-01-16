//
//  WordSelectionDialog.swift
//  MeshMan
//
//  Created by Russell Pecka on 1/12/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import Foundation
import UIKit

internal class WordSelectionDialog {
	
	private enum Strings {
		static let chooseAWord = NSLocalizedString("Choose a word", comment: "Title of the prompt that asks the user to pick a word to play")
		static let chooseAWordMessage = NSLocalizedString("Your word cannot be greater than %d characters long, including special characters.", comment: "Subtitle for the choose a word message in hangman")
	}
	
	internal static func make(withOkayAction okayAction: @escaping ((UIAlertAction, String) -> Void)) -> UIAlertController {
		let alertView = UIAlertController(title: Strings.chooseAWord, message: String(format: Strings.chooseAWordMessage, Hangman.Rules.maxCharacters), preferredStyle: .alert)
		alertView.addTextField(configurationHandler: nil)
		let okay = UIAlertAction(title: VisibleStrings.Generic.okay, style: .default) { (action) in
			guard let text = alertView.textFields?.first?.text else { fatalError() }
			guard text.count <= Hangman.Rules.maxCharacters else { fatalError() }
			okayAction(action, text)
		}
		alertView.addAction(okay)
		return alertView
	}
	
}
