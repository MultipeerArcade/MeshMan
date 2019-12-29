//
//  GameDataCommand.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/28/19.
//  Copyright © 2019 Russell Pecka. All rights reserved.
//

import Foundation

class GameDataCommand: CommandDescribable, Codable {
    
    let command: CommandType = CommandType.gameData
    
    let payload: Data
    
    init(payload: Data) {
        self.payload = payload
    }
    
}
