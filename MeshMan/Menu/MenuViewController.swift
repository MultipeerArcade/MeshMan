//
//  MenuViewController.swift
//  MeshMan
//
//  Created by Russell Pecka on 1/2/20.
//  Copyright © 2020 Russell Pecka. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {
    
    static func newInstance() -> (UINavigationController, MenuViewController) {
        let navigationVC = UIStoryboard(name: "Menu", bundle: nil).instantiateInitialViewController() as! UINavigationController
        let vc = navigationVC.viewControllers.first as! MenuViewController
        return (navigationVC, vc)
    }

    @IBOutlet private weak var currentHostLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        currentHostLabel.text = MCManager.shared.host.displayName
    }
    
    @IBAction private func addPlayersButtonPressed() {
        let browserVC = MCManager.shared.makeBrowserVC()
        navigationController?.pushViewController(browserVC, animated: true)
    }
    
    @IBAction private func leaveGameButtonPressed() {
    }
    
}
