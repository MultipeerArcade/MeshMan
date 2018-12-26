//
//  QuestionCell.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/24/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import UIKit

class QuestionCell: UITableViewCell {
    
    @IBOutlet private weak var questionLabel: UILabel!
    @IBOutlet private weak var answerLabel: UILabel!
    @IBOutlet private weak var waitingIndicator: UIActivityIndicatorView!
    
    func configureWith(question: Questions.Question) {
        questionLabel.text = question.question
        if let answer = question.answer {
            answerLabel.isHidden = false
            answerLabel.text = answer.rawValue
            waitingIndicator.stopAnimating()
        } else {
            answerLabel.isHidden = true
            waitingIndicator.startAnimating()
        }
    }

}
