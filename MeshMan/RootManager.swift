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
    
    private var peersToReconnect: [MCPeerID] = []
    private var reconnectCompletion: ((Bool) -> Void)?
    
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
    
    func handleReconnect(for peers: [MCPeerID], completion: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: "Lost Required Player", message: "The connection to a required player has been lost", preferredStyle: .alert)
        alertController.addAction(.init(title: "Reconnect", style: .default, handler: { _ in
            self.reconnectCompletion = completion
            self.peersToReconnect = peers
            self.showReconnectBrowser()
        }))
        alertController.addAction(.init(title: "Abandon Them and Quit", style: .destructive, handler: { _ in
            completion(false)
        }))
        navigationController.present(alertController, animated: true, completion: nil)
    }
    
    func handleReconnectForArbitraryPeer(completion: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: "Lost Player(s)", message: "The connection to a player has been lost.", preferredStyle: .alert)
        alertController.addAction(.init(title: "Reconnect", style: .default, handler: { _ in
            self.reconnectCompletion = completion
            self.peersToReconnect = []  // No specific peers to reconnect
            self.showReconnectBrowser()
        }))
        alertController.addAction(.init(title: "Abandon Them", style: .destructive, handler: { _ in
            completion(false)
        }))
        navigationController.present(alertController, animated: true, completion: nil)
    }
    
    private func showReconnectBrowser() {
        let browserVC = MCManager.shared.makeBrowserVC()
        browserVC.delegate = self
        navigationController.present(browserVC, animated: true, completion: nil)
    }
    
    // MARK: - MCBrowserViewControllerDelegate
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        handleBrowserViewControllerDone()
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        handleBrowserViewControllerDone()
    }
    
    // MARK: - Handling BrowserViewController Events
    
    private func handleBrowserViewControllerDone() {
        navigationController.dismiss(animated: true)
        MCManager.shared.doneHandlingDisconnections()
        let reconnectedAllPeers = peersToReconnect.reduce(true) { (result, peer) -> Bool in
            return result && MCManager.shared.session.connectedPeers.contains(peer)
            } && !MCManager.shared.session.connectedPeers.isEmpty
        reconnectCompletion?(reconnectedAllPeers)
        reconnectCompletion = nil
        peersToReconnect = []
    }
    
}
