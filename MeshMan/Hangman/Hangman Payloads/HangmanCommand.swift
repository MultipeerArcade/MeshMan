//
//  HangmanCommand.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/28/19.
//  Copyright © 2019 Russell Pecka. All rights reserved.
//

import Foundation


protocol HangmanCommandDescribable {
    var commandType: HangmanCommandType { get }
}


struct HangmanCommand: HangmanCommandDescribable, Codable {
    
    let commandType: HangmanCommandType
    
    let payload: Data
    
}


enum HangmanCommandType: String, Codable {
    case setState
}
