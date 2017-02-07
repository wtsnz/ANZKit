//
//  InterfaceController.swift
//  ANZWatch Extension
//
//  Created by Will Townsend on 7/02/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

class InterfaceController: WKInterfaceController {

    var session: WCSession? {
        didSet {
            if let session = session {
                session.delegate = self
                session.activate()
            }
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
     
        if WCSession.isSupported() {
            self.session = WCSession.default()
            
            self.session?.sendMessage(["action.fetch": ""], replyHandler: { (data) in
                
            }, errorHandler: { (error) in
                print(error)
            })
            
        } else {
            print("Failed to create session")
        }
        
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}

extension InterfaceController: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        
    }
    
}
