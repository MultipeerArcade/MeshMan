//
//  QuestionListViewController.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/24/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import UIKit

class QuestionListViewController: UIViewController, UITableViewDataSource {
    
    // MARK: - Outlets

    @IBOutlet private weak var questionTable: UITableView!
    
    // MARK: - Private Members
    
    private var questionList = [Questions.Question]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    // MARK: - Adding and Updating Rows
    
    func addQuestion(_ number: Int, question: String) {
        let index = questionList.firstIndex { $0.number == number } ?? questionList.count
        questionList.append(Questions.Question(number: number, question: question, answer: nil))
        questionTable.insertRows(at: [IndexPath(item: index, section: 0)], with: .automatic)
    }
    
    func updateQuestion(_ number: Int, with answer: Questions.Answer) {
        for (index, existing) in questionList.enumerated() {
            guard existing.number == number else { continue }
            let updatedQuestion = Questions.Question(number: number, question: existing.question, answer: answer)
            questionList[index] = updatedQuestion
            questionTable.reloadRows(at: [IndexPath(item: index, section: 0)], with: .automatic)
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return questionList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "questionCell", for: indexPath) as! QuestionCell
        cell.configureWith(question: questionList[indexPath.item])
        return cell
    }

}
