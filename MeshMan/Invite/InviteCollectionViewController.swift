//
//  InviteCollectionViewController.swift
//  MeshMan
//
//  Created by Russell Pecka on 1/5/20.
//  Copyright © 2020 Russell Pecka. All rights reserved.
//

import MultipeerConnectivity
import UIKit

enum InviteStage {
    case invited
    case connecting
    case accepted
    case declined
}

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
    
    private var connectedPeers = [(MCPeerID, stage: InviteStage)]()
    
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
        discover(peerID: peerID)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        undiscover(peerID: peerID)
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
                let (peer, stage) = connectedPeers[indexPath.row]
                cell.configure(with: peer.displayName, color: .systemBlue, stage: stage)
            case Constants.discoveredPeersSeciton:
                cell.configure(with: discoveredPeers[indexPath.row].displayName, color: UIColor.systemBlue, stage: nil)
            default:
                return cell
            }
        }
    
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch indexPath.section {
        case Constants.discoveredPeersSeciton:
            let peerID = discoveredPeers[indexPath.row]
            browser.invitePeer(peerID, to: session, withContext: nil, timeout: 30)
            undiscover(peerID: peerID)
            connectedPeers.append((peerID, .invited))
            collectionView.insertItems(at: [.init(row: connectedPeers.endIndex - 1, section: Constants.connectedPeersSection)])
        default:
            break
        }
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
            connectedPeers[peerIndex] = (peerID, .accepted)
            collectionView.reloadItems(at: [.init(row: peerIndex, section: Constants.connectedPeersSection)])
        case .connecting:
            connectedPeers[peerIndex] = (peerID, .connecting)
            collectionView.reloadItems(at: [.init(row: peerIndex, section: Constants.connectedPeersSection)])
        case .notConnected:
            let (_, oldStage) = connectedPeers[peerIndex]
            switch oldStage {
            case .accepted, .connecting, .declined:
                connectedPeers.remove(at: peerIndex)
                collectionView.deleteItems(at: [.init(row: peerIndex, section: Constants.connectedPeersSection)])
            case .invited:
                connectedPeers[peerIndex] = (peerID, .declined)
                collectionView.reloadItems(at: [.init(row: peerIndex, section: Constants.connectedPeersSection)])
            }
        }
    }
    
    private func addConnectionProgress(forPeer peerID: MCPeerID, using state: MCSessionState) {
        let row = connectedPeers.count
        switch state {
        case .connected:
            connectedPeers.append((peerID, .accepted))
            collectionView.insertItems(at: [.init(row: row, section: Constants.connectedPeersSection)])
        case .connecting:
            connectedPeers.append((peerID, .connecting))
            collectionView.insertItems(at: [.init(row: row, section: Constants.connectedPeersSection)])
        case .notConnected:
            connectedPeers.append((peerID, .declined))
            collectionView.insertItems(at: [.init(row: row, section: Constants.connectedPeersSection)])
        }
    }
    
    private func removeConnectionProgress(forPeer peerID: MCPeerID) {
        if let index = connectedPeers.firstIndex(where: { (peer, stage) -> Bool in
            return peerID == peer
        }) {
            connectedPeers.remove(at: index)
            collectionView.deleteItems(at: [.init(row: index, section: Constants.connectedPeersSection)])
        }
    }
    
    private func discover(peerID: MCPeerID) {
        removeConnectionProgress(forPeer: peerID)
        discoveredPeers.append(peerID)
        collectionView.insertItems(at: [.init(row: discoveredPeers.count - 1, section: Constants.discoveredPeersSeciton)])
    }
    
    private func undiscover(peerID: MCPeerID) {
        guard let index = discoveredPeers.firstIndex(of: peerID) else { return }
        discoveredPeers.remove(at: index)
        collectionView.deleteItems(at: [.init(row: index, section: Constants.discoveredPeersSeciton)])
    }

}
