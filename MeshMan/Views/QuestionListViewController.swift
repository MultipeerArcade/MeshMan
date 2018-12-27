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

        // Do any additional setup after loading the view.
    }
    
    // MARK: - Adding and Updating Rows
    
    func insert(at row: Int) {
        questionTable.insertRows(at: [IndexPath(item: row, section: 0)], with: .automatic)
    }
    
    func update(at row: Int) {
        questionTable.reloadRows(at: [IndexPath(item: row, section: 0)], with: .automatic)
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
