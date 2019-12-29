//
//  SetGameCommand.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/27/19.
//  Copyright © 2019 Russell Pecka. All rights reserved.
//

import Foundation

class SetGameCommand: CommandDescribable, Codable {
    
    let command: CommandType = CommandType.setGame
    
    let game: Game
    let payload: Data
    
    init(game: Game, payload: Data) {
        self.game = game
        self.payload = payload
    }
    
}
