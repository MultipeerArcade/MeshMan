//
//  SetStatusCommand.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/28/19.
//  Copyright © 2019 Russell Pecka. All rights reserved.
//

import Foundation

struct SetStatusCommand: CommandDescribable, Codable {
    
    let command: CommandType = .status
    let message: String
    
    init(message: String) {
        self.message = message
    }
    
}
