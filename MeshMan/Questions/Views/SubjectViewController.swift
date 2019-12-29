//
//  SubjectViewController.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/24/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import UIKit

class SubjectViewController: UIViewController, UITextFieldDelegate {
    
    enum Result {
        case choseSubject(String)
        case cancelled
    }
    
    // MARK: - Outlets
    
    @IBOutlet private weak var subjectField: UITextField!
    @IBOutlet private weak var rulesLabel: UILabel!
    
    // MARK: - Private Members
    
    private var completion: ((Result) -> Void)!
    
    // MARK: - New Instance
    
    static func newInstance(completion: @escaping (Result) -> Void) -> SubjectViewController {
        guard let subjectVC = Storyboards.subjectSelection.instantiateInitialViewController() as? SubjectViewController else { fatalError("Could not cast the resulting storyboard correctly") }
        subjectVC.completion = completion
        return subjectVC
    }
    
    // MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        subjectField.becomeFirstResponder()
    }
    
    // MARK: -
    
    @IBAction func doneButtonPressed() {
        guard let text = subjectField.text else { return }
        processText(input: text)
    }
    
    // MARK: - Input Sanitation
    
    private func processText(input: String) {
        switch Questions.sanitize(subject: input) {
        case .invalid:
            showInvalidSubjectMessage(for: input)
        case .sanitized(let subject):
            self.dismiss(animated: true) {
                self.completion(.choseSubject(subject))
            }
        }
    }
    
    private func showInvalidSubjectMessage(for input: String) {
        let alert = UIAlertController(title: "Invalid Subject", message: "\"\(input)\" is not a valid entry.", preferredStyle: .alert)
        let okayAction = UIAlertAction(title: "Okay", style: .default)
        alert.addAction(okayAction)
        present(alert, animated: true)
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text else { return false }
        processText(input: text)
        textField.resignFirstResponder()
        return false
    }

}
