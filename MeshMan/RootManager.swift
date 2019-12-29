//
//  RootManager.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/28/19.
//  Copyright © 2019 Russell Pecka. All rights reserved.
//

import Foundation
import UIKit

class RootManager {
    
    static let shared = RootManager()
    
    var navigationController: UINavigationController!
    
    private init() {
        
    }
    
    func startWaitingForInvite() {
        let waitVC = WaitInviteViewController.newInstance()
        navigationController.setViewControllers([waitVC], animated: true)
        MCManager.shared.startAdvertising()
    }
    
    func goToLobby(asHost: Bool) {
        let lobbyVC = LobbyViewController.newInstance(asHost: asHost)
        MCManager.shared.statusHandler = lobbyVC
        navigationController.setViewControllers([lobbyVC], animated: true)
    }
    
}
