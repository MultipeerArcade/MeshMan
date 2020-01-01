//
//  BaseCommand.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/27/19.
//  Copyright © 2019 Russell Pecka. All rights reserved.
//

import Foundation

protocol CommandDescribable {
    var command: CommandType { get }
}

class BaseCommand: CommandDescribable, Codable {
    
    let command: CommandType
    
}

enum CommandType: String, Codable {
    case setGame
    case gameData
    case status
    case setHost
}
