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
    
    var questions: Questions!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        questionTable.rowHeight = UITableView.automaticDimension
    }
    
    // MARK: - Adding and Updating Rows
    
    func insert(at row: Int) {
        let ip = IndexPath(item: row, section: 0)
        questionTable.insertRows(at: [ip], with: .automatic)
        questionTable.scrollToRow(at: ip, at: .bottom, animated: true)
    }
    
    func update(at row: Int) {
        let ip = IndexPath(item: row, section: 0)
        questionTable.reloadRows(at: [ip], with: .automatic)
        questionTable.scrollToRow(at: ip, at: .bottom, animated: true)
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return questions.questions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "questionCell", for: indexPath) as! QuestionCell
        cell.configureWith(question: questions.questions[indexPath.item])
        return cell
    }

}
