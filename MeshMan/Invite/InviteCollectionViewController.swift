//
//  InviteCollectionViewController.swift
//  MeshMan
//
//  Created by Russell Pecka on 1/5/20.
//  Copyright © 2020 Russell Pecka. All rights reserved.
//

import MultipeerConnectivity
import UIKit

class InviteCollectionViewController: UICollectionViewController, MCNearbyServiceBrowserDelegate, ConnectionStateDelegate {
    
    private enum Constants {
        static let connectedPeersSection = 0
        static let discoveredPeersSeciton = 1
        static let sectionCount = 2
    }
    
    static func newInstance(with browser: MCNearbyServiceBrowser, session: MCSession) -> InviteCollectionViewController {
        let vc = UIStoryboard(name: "Invite", bundle: nil).instantiateInitialViewController() as! InviteCollectionViewController
        vc.browser = browser
        vc.session = session
        browser.delegate = vc
        MCManager.shared.connectionStateDelegate = vc
        return vc
    }
    
    private var browser: MCNearbyServiceBrowser!
    
    private var session: MCSession!
    
    private var connectedPeers = [(MCPeerID, connectionInProgress: Bool)]()
    
    private var discoveredPeers = [MCPeerID]()
    
    // MARK: - ViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        browser.startBrowsingForPeers()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        browser.stopBrowsingForPeers()
    }
    
    // MARK: - MCNearbyServiceBrowserDelegate
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        discoveredPeers.append(peerID)
        collectionView.insertItems(at: [.init(row: discoveredPeers.count - 1, section: Constants.discoveredPeersSeciton)])
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        guard let index = discoveredPeers.firstIndex(of: peerID) else { return }
        discoveredPeers.remove(at: index)
        collectionView.deleteItems(at: [.init(row: index, section: Constants.discoveredPeersSeciton)])
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return Constants.sectionCount
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case Constants.connectedPeersSection:
            return connectedPeers.count
        case Constants.discoveredPeersSeciton:
            return discoveredPeers.count
        default:
            return 0
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlayerCollectionViewCell.reuseIdentifier, for: indexPath)
    
        if let cell = cell as? PlayerCollectionViewCell {
            switch indexPath.section {
            case Constants.connectedPeersSection:
                let (peer, connecting) = connectedPeers[indexPath.row]
                cell.configure(with: peer.displayName, color: .systemBlue, connecting: connecting)
            case Constants.discoveredPeersSeciton:
                cell.configure(with: discoveredPeers[indexPath.row].displayName, color: UIColor.systemBlue)
            default:
                return cell
            }
        }
    
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        browser.invitePeer(discoveredPeers[indexPath.row], to: session, withContext: nil, timeout: 30)
    }
    
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // MARK: - ConnectionStateDelegate
    
    func connectionState(forPeer peerID: MCPeerID, didChange state: MCSessionState) {
        if let existingIndex = connectedPeers.firstIndex(where: { (peer, connectionInProgress) -> Bool in
            return peer == peerID
        }) {
            updateConnectionProgress(peerID: peerID, atIndex: existingIndex, using: state)
        } else {
            addConnectionProgress(forPeer: peerID, using: state)
        }
    }
    
    // MARK: -
    
    private func updateConnectionProgress(peerID: MCPeerID, atIndex peerIndex: Int, using state: MCSessionState) {
        switch state {
        case .connected:
            connectedPeers[peerIndex] = (peerID, false)
            collectionView.reloadItems(at: [.init(row: peerIndex, section: Constants.connectedPeersSection)])
        case .connecting:
            connectedPeers[peerIndex] = (peerID, true)
            collectionView.reloadItems(at: [.init(row: peerIndex, section: Constants.connectedPeersSection)])
        case .notConnected:
            connectedPeers.remove(at: peerIndex)
            collectionView.deleteItems(at: [.init(row: peerIndex, section: Constants.connectedPeersSection)])
        }
    }
    
    private func addConnectionProgress(forPeer peerID: MCPeerID, using state: MCSessionState) {
        let row = connectedPeers.count
        switch state {
        case .connected:
            connectedPeers.append((peerID, false))
            collectionView.insertItems(at: [.init(row: row, section: Constants.connectedPeersSection)])
        case .connecting:
            connectedPeers.append((peerID, true))
            collectionView.insertItems(at: [.init(row: row, section: Constants.connectedPeersSection)])
        case .notConnected:
            break
        }
    }

}
