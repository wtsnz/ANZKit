//
//  AppDelegate.swift
//  ANZ
//
//  Created by Will Townsend on 8/01/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import UIKit
import WatchConnectivity
import ANZKit
import RxSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    let disposeBag = DisposeBag()
    
    var window: UIWindow?
    var appCoordinator: AppCoordinator!

    var appContext: AppContext? = nil
    
    var session: WCSession? {
        didSet {
            if let session = session {
                session.delegate = self
                session.activate()
            }
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        if WCSession.isSupported() {
            session = WCSession.default()
        }
        
        application.setMinimumBackgroundFetchInterval(60 * 5)
        
        let localDataService = LocalDataService()
        let anzService = self.anzService(using: localDataService)
        
        let appContext = AppContext(apiService: anzService, localDataService: localDataService)
        self.appContext = appContext
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.appCoordinator = AppCoordinator(window: self.window!, context: appContext)
        self.appCoordinator.start()
        
        return true
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        let keychain = KeychainWrapper(serviceName: "anzkit.quickbalance")
        
        guard let quickBalanceToken = keychain.string(forKey: "qb.token") else {
//            replyHandler(["response": "qb", "balance": "error"])
            return
        }
        guard let account = keychain.string(forKey: "qb.account") else {
//            replyHandler(["response": "qb", "balance": "error"])
            return
        }
        
        guard let service = self.appContext?.apiService.quickBalanceService() else {
//            replyHandler(["response": "qb", "balance": "error"])
            return
        }
        
        service.quickBalances(with: quickBalanceToken, for: [account])
            .subscribe(onNext: { (balances) in
                dump(balances)
                
                guard let watchSession = self.session else {
                    // Lie
                    completionHandler(UIBackgroundFetchResult.newData)
                    return
                }
                
                watchSession.transferCurrentComplicationUserInfo(["balance": balances.first!.balance])
                
                completionHandler(UIBackgroundFetchResult.newData)
                
            }, onError: { (error) in
                dump(error)
                
//                replyHandler(["response": "qb", "balance": "error"])
                completionHandler(UIBackgroundFetchResult.newData)
            })
            .addDisposableTo(self.disposeBag)
        
    }
    
    func anzService(using dataService: LocalDataService) -> ANZService {
        
        let serverConfig = ServerConfig.production
        
        // Load device id, or create if doesn't exist
        
        let deviceId = "EA06918A-844A-4BB8-B053-0827CE0E43B1"//"ad375799-7bc6-4d3a-b0a3-bed6e7ff4094" // NSUUID().uuidString
        
        // Load request number
        
        let requestId = 5000
        
        let service = ANZService(
            serverConfig: serverConfig,
            requestId: requestId,
            apiKey: "41b4c957-56c8-4f0a-9ed6-bab90a43fcf5",
            userAgent: "goMoney NZ/5.8.1/wifi/samsung SM-G900F/4.4.2/landscape/",
            deviceId: deviceId,
            deviceDescription: "iPhone",
            deviceApiVersion: "19",
            accessToken: nil,
            ibSessionId: nil
        )
        
        return service
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}

extension AppDelegate: WCSessionDelegate {
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print(message)
        
        guard let command = message["command"] as? String else {
            return
        }
        
        switch command {
        case "qb":
            
            let keychain = KeychainWrapper(serviceName: "anzkit.quickbalance")
            
            guard let quickBalanceToken = keychain.string(forKey: "qb.token") else {
                replyHandler(["response": "qb", "balance": "error"])
                return
            }
            guard let account = keychain.string(forKey: "qb.account") else {
                replyHandler(["response": "qb", "balance": "error"])
                return
            }
            
            guard let service = self.appContext?.apiService.quickBalanceService() else {
                replyHandler(["response": "qb", "balance": "error"])
                return
            }
            
            service.quickBalances(with: quickBalanceToken, for: [account])
                .subscribe(onNext: { (balances) in
                    dump(balances)
                    
                    replyHandler(["response": "qb", "balance": balances.first!.balance])
                    
                }, onError: { (error) in
                    dump(error)
                    
                    replyHandler(["response": "qb", "balance": "error"])
                    
                })
            
        default:
            break
        }
        
    }
    
    
}
