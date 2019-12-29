//
//  QuestionsCommand.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/28/19.
//  Copyright © 2019 Russell Pecka. All rights reserved.
//

import Foundation

protocol QuestionsCommandDescribable {
    var commandType: QuestionsCommandType { get }
}

struct QuestionsCommand: QuestionsCommandDescribable, Codable {
    
    let commandType: QuestionsCommandType
    
    let payload: Data
    
}

enum QuestionsCommandType: String, Codable {
    case setState
}
