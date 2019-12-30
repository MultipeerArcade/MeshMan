//
//  RootManager.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/28/19.
//  Copyright © 2019 Russell Pecka. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import UIKit

class RootManager: NSObject, MCBrowserViewControllerDelegate {
    
    static let shared = RootManager()
    
    var navigationController: UINavigationController!
    
    func goToWelcome() {
        let welcome = WelcomeViewController.newInstance()
        navigationController.setViewControllers([welcome], animated: true)
    }
    
    func startWaitingForInvite() {
        let waitVC = WaitInviteViewController.newInstance()
        navigationController.setViewControllers([waitVC], animated: true)
        MCManager.shared.startAdvertising()
    }
    
    func goToLobby() {
        let lobbyVC = LobbyViewController.newInstance()
        MCManager.shared.statusHandler = lobbyVC
        navigationController.setViewControllers([lobbyVC], animated: true)
    }
    
    func handleLostConnection() {
        let alertController = UIAlertController(title: "Connection Lost", message: "You have lost your connection to the game.", preferredStyle: .alert)
        alertController.addAction(.init(title: VisibleStrings.Generic.okay, style: .default, handler: { _ in
            self.goToWelcome()
        }))
        navigationController.present(alertController, animated: true, completion: nil)
    }
    
    func handleReconnect(for peer: MCPeerID) {
        let alertController = UIAlertController(title: "Lost Player", message: "The connection to \(peer.displayName)", preferredStyle: .alert)
        alertController.addAction(.init(title: "Reconnect", style: .default, handler: { _ in
            self.showReconnectBrowser(for: peer)
        }))
        alertController.addAction(.init(title: "Abandon Them", style: .destructive, handler: { _ in
            return
        }))
        navigationController.present(alertController, animated: true, completion: nil)
    }
    
    private func showReconnectBrowser(for peer: MCPeerID) {
        let browserVC = MCManager.shared.makeBrowserVC()
        browserVC.delegate = self
        navigationController.present(browserVC, animated: true, completion: nil)
    }
    
    // MARK: - MCBrowserViewControllerDelegate
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        navigationController.dismiss(animated: true)
        MCManager.shared.handlingDisconnects = false
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        navigationController.dismiss(animated: true)
        MCManager.shared.handlingDisconnects = false
    }
    
}
