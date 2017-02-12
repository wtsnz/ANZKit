//
//  ExtensionDelegate.swift
//  ANZWatch Extension
//
//  Created by Will Townsend on 7/02/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import WatchKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    
    var balances: [[String: Any]] {
        set {
            UserDefaults.standard.set(newValue, forKey: "balances")
            UserDefaults.standard.synchronize()
        }
        get {
            if let balances = UserDefaults.standard.array(forKey: "balances") as? [[String: Any]] {
                return balances
            } else {
                return []
            }
        }
    }
    
    var balance: String {
        
        guard let account = self.balances.first else {
            return "Not found"
        }
        
        guard let balance = account["balance"] as? String else {
            return "Not found"
        }
        
        return "$\(balance)"
    }
    
//    var balance: String {
//        set {
//            UserDefaults.standard.set(newValue, forKey: "balance")
//            UserDefaults.standard.synchronize()
//        }
//        get {
//            
//            if let balance = UserDefaults.standard.string(forKey: "balance") {
//                return balance
//            } else {
//                return "UNKNOWN"
//            }
//        }
//    }
    
    var session: WCSession? {
        didSet {
            if let session = session {
                session.delegate = self
                session.activate()
            }
        }
    }
    
    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
        
        if WCSession.isSupported() {
            self.session = WCSession.default()
            
        } else {
            print("Failed to create session")
        }
        
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompleted()
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompleted()
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompleted()
            default:
                // make sure to complete unhandled task types
                task.setTaskCompleted()
            }
        }
    }
    
    func requestBalances(completion: @escaping (_ balances: [[String: Any]]?) -> Void) {
        
        if self.session?.activationState == .activated {
            self.session?.sendMessage(["command": "qb"], replyHandler: { (data) in
                
                print("received response")
                print(data)
                
                guard let response = data["response"] as? String, response == "qb" else {
                    completion(nil)
                    return
                }
                
                guard let balances = data["balances"] as? [[String: Any]] else {
                    completion(nil)
                    return
                }
                
                self.balances = balances
                
                completion(balances)
                
                let complicationServer = CLKComplicationServer.sharedInstance()
                
                guard let activeComplications = complicationServer.activeComplications else {
                    return
                }
                
                for complication in activeComplications {
                    complicationServer.reloadTimeline(for: complication)
                }
                
            }, errorHandler: { (error) in
                print(error)
                completion(nil)
            })
        } else {
            completion(nil)
            print("not activated")
        }
        
    }
}


extension ExtensionDelegate: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        dump(activationState)
        dump(error)
        
        self.requestBalances { (balances) in
            
            if let balances = balances {
                self.balances = balances
            } else {
                print("failed")
            }
        }
        
    }
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        dump(session.isReachable)
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        dump(message)
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        
        dump(userInfo)
        
        if let balances = userInfo["balances"] as? [[String: Any]] {
            self.balances = balances
        }
        
    }
    
}

