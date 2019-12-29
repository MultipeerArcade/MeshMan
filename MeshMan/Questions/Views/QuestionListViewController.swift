//
//  QuestionListViewController.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/24/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import UIKit

class QuestionListViewController: UIViewController, UITableViewDataSource {
    
    private enum Update {
        case insert(Int)
        case refresh(Int)
    }
    
    // MARK: - Outlets

    @IBOutlet private weak var questionTable: UITableView!
    
    // MARK: - Private Members
    
    var questions: Questions!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        questionTable.rowHeight = UITableView.automaticDimension
    }
    
    // MARK: - Adding and Updating Rows
    
    func updateState(from oldState: QuestionsGameState, to newState: QuestionsGameState) {
        let updates = newState.questions.enumerated().compactMap { (index, question) -> Update? in
            if let oldQuestionIndex = oldState.questions.firstIndex(of: question) {
                if question.answer != oldState.questions[oldQuestionIndex].answer {
                    return .refresh(index)
                } else {
                    return nil
                }
            } else {
                return .insert(index)
            }
        }
        for update in updates {
            switch update {
            case .insert(let index):
                questionTable.insertRows(at: [IndexPath(item: index, section: 0)], with: .automatic)
            case .refresh(let index):
                questionTable.reloadRows(at: [IndexPath(item: index, section: 0)], with: .automatic)
            }
        }
        questionTable.scrollToRow(at: IndexPath(item: newState.questions.count - 1, section: 0), at: .bottom, animated: true)
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return questions.state.questions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "questionCell", for: indexPath) as! QuestionCell
        cell.configureWith(question: questions.state.questions[indexPath.item])
        return cell
    }

}
