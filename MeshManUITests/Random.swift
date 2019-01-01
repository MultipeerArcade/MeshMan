//
//  Random.swift
//  MeshManUITests
//
//  Created by Russell Pecka on 12/31/18.
//  Copyright © 2018 Russell Pecka. All rights reserved.
//

import Foundation

struct Random {
    
    static func randomName() -> String {
        return String(Int.random(in: 100000...1000000))
    }
    
}
