//
//  WaitInviteViewController.swift
//  MeshMan
//
//  Created by Russell Pecka on 12/28/19.
//  Copyright © 2019 Russell Pecka. All rights reserved.
//

import UIKit

class WaitInviteViewController: UIViewController {
    
    static func newInstance() -> WaitInviteViewController {
        let vc = UIStoryboard(name: "WaitInvite", bundle: nil).instantiateInitialViewController() as! WaitInviteViewController
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
