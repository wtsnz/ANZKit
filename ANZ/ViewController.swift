//
//  ViewController.swift
//  ANZ
//
//  Created by Will Townsend on 8/01/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import UIKit
import ANZKit
import Alamofire
import SwiftyRSA

class ViewController: UIViewController {

    let api = ANZAPI()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        
        self.api.authenticate(withUsername: Secrets.username, password: Secrets.password)
        .subscribe(onNext: { (authToken) in
            print(authToken)
        }, onError: { (error) in
            print(error)
        })
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

