//
//  AppCoordinator.swift
//  ANZ
//
//  Created by Will Townsend on 8/02/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//


import Foundation
import UIKit
import RxSwift
import ANZKit

/// The AppCoordinator is our first coordinator
/// In this example the AppCoordinator as a rootViewController
class AppCoordinator: RootViewCoordinator {
    
    // MARK: - Properties
    
    let context: AppContext
    var childCoordinators: [Coordinator] = []
    
    var rootViewController: UIViewController {
        return self.navigationController
    }
    
    let disposeBag = DisposeBag()
    
    /// Window to manage
    let window: UIWindow
    
    private lazy var navigationController: UINavigationController = {
        let navigationController = UINavigationController()
        navigationController.isNavigationBarHidden = false
        return navigationController
    }()
    
    // MARK: - Init
    
    public init(window: UIWindow, context: AppContext) {
        self.context = context
        
        self.window = window
        
        self.window.rootViewController = self.rootViewController
        self.window.makeKeyAndVisible()
    }
    
    // MARK: - Functions
    
    /// Starts the coordinator
    public func start() {
        
        // See if we've got a device token
                
        if let deviceToken = self.context.apiService.deviceToken {
            
            // Authenticate before showing the view controllers
            
            self.showLoginDevicePasscodeAlertController(callback: { (passcode) in
                
                guard let passcode = passcode else {
                    return
                }
                
                self.context.apiService.session(withDeviceToken: deviceToken, pin: passcode)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { (session) in
                        self.showAccountsViewController()
                    }, onError: { (error) in
                        self.handleError(error: error, callback: { })
                    })
                    .addDisposableTo(self.disposeBag)
            })
            
        } else {
            self.showLoginViewController()
        }
        
    }
    
    /// Creates a new SplashViewController and places it into the navigation controller
    private func showAuthenticationViewController() {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "auth") as! ViewController
        viewController.context = self.context
        self.navigationController.viewControllers = [viewController]

    }
    
    fileprivate func showAccountsViewController() {
        
        let viewController = AccountsViewController(context: self.context)
        viewController.delegate = self
        self.navigationController.setViewControllers([viewController], animated: true)
        
    }
    
    private func showLoginViewController() {
        
        let viewController = LoginViewController(context: self.context)
        viewController.delegate = self
        self.navigationController.viewControllers = [viewController]
        
    }
    
    func handleError(error: Error, callback: @escaping () -> Void) {
        
        guard let error = error as? ANZService.ServiceError else {
            callback()
            return
        }
        
        switch error {
        case .apiError(let anzError):
            
                switch anzError.code {
                case .authCodeSent:
                    self.showTwoFactorAlertController(message: anzError.devDescription, callback: { (authCode) in
                        
                        guard let authCode = authCode else {
                            return
                        }
                        
                        self.context.apiService
                            .getSession(authCode: authCode)
                            .observeOn(MainScheduler.instance)
                            .subscribe(onNext: { (session) in
                                callback()
                            }, onError: { (error) in
                                self.handleError(error: error, callback: { })
                            })
                            .addDisposableTo(self.disposeBag)
                        
                    })
                default:
                    self.showErrorAlert(error: anzError, callback: callback)
            }
            
        case .couldNotParseJSON:
            break;
        }
        
    }
    
    func showErrorAlert(error: ANZError, callback: @escaping () -> Void) {
        
        let alertController = UIAlertController(title: "Error \(error.code)", message: error.devDescription, preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Okay", style: .default, handler: {
            (action : UIAlertAction!) -> Void in
            callback()
        })
        
        alertController.addAction(cancelAction)
        
        self.navigationController.present(alertController, animated: true, completion: nil)
    }
    
    func showTwoFactorAlertController(message: String?, callback: @escaping (_ authCode: String?) -> Void) {
        
        let alertController = UIAlertController(title: "Two Factor Authentication", message: message, preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Submit", style: .default, handler: {
            alert -> Void in
            let authCodeTextField = alertController.textFields![0] as UITextField
            callback(authCodeTextField.text)
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: {
            (action : UIAlertAction!) -> Void in
            callback(nil)
        })
        
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Auth Code"
        }
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        self.navigationController.present(alertController, animated: true, completion: nil)
    }
    
    
    func showCreateDevicePasscodeAlertController(callback: @escaping (_ passcode: String?) -> Void) {
        
        let alertController = UIAlertController(title: "Add Device", message: "Add your device to your account. Enter your existing ANZGoMoney passcode:", preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Submit", style: .default, handler: {
            alert -> Void in
            let passcodeTextField = alertController.textFields![0] as UITextField
            callback(passcodeTextField.text)
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: {
            (action : UIAlertAction!) -> Void in
            callback(nil)
        })
        
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Passcode"
        }
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        self.navigationController.present(alertController, animated: true, completion: nil)
    }
    
    func showLoginDevicePasscodeAlertController(callback: @escaping (_ passcode: String?) -> Void) {
        
        let alertController = UIAlertController(title: "Authenticate", message: "Enter your passcode:", preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Submit", style: .default, handler: {
            alert -> Void in
            let passcodeTextField = alertController.textFields![0] as UITextField
            callback(passcodeTextField.text)
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: {
            (action : UIAlertAction!) -> Void in
            callback(nil)
        })
        
        alertController.addTextField { (textField : UITextField!) -> Void in
            textField.placeholder = "Passcode"
        }
        
        alertController.addAction(saveAction)
        alertController.addAction(cancelAction)
        
        self.navigationController.present(alertController, animated: true, completion: nil)
    }
    
    func checkLogin() {
        
        guard let sessionId = self.context.apiService.ibSessionId else {
            return
        }
        
        if self.context.apiService.deviceToken == nil {
            
            self.showCreateDevicePasscodeAlertController(callback: { (devicePasscode) in
                
                guard let devicePasscode = devicePasscode else {
                    return
                }
                
                self.context.apiService.setPin(pin: devicePasscode)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { (deviceToken) in
                        
                        self.checkLogin()
                        
                    }, onError: { (error) in
                        self.handleError(error: error, callback: {
                            self.checkLogin()
                        })
                    })
                    .addDisposableTo(self.disposeBag)
            })
            
        } else {
            
            // Show Accounts
            
            self.showAccountsViewController()
            
        }
        

    }
    
}

extension AppCoordinator: LoginViewControllerDelegate {
    
    func loginViewController(viewController: LoginViewController, didRequestLoginWith username: String, password: String) {
        
        // Clear the device token when logging in with a new account
        self.context.apiService.deviceToken = nil
        
        self.context.apiService
            .authenticate(withUsername: username, password: password)
            .observeOn(MainScheduler.instance)
            .do(onSubscribe: {
                viewController.state.value = .loading
            })
            .subscribe(onNext: { (session) in
                dump(session)
                
                self.checkLogin()
                
            }, onError: { (error) in
                self.handleError(error: error, callback: {
                    viewController.state.value = .default
                    // Check if we've got a session
                    
                    self.checkLogin()
                    
                })
            })
            .addDisposableTo(self.disposeBag)
    }
}

extension AppCoordinator: AccountsViewControllerDelegate {
    
    func accountViewController(viewController: AccountsViewController, selectedAccount: Account) {
        
//
        // Get quickbalance token
        
        // save token + account hash in keychain.
        
        let keychain = KeychainWrapper(serviceName: "anzkit.quickbalance")
        
        self.context.apiService.quickBalanceToken()
            .subscribe(onNext: { (token) in
                keychain.setString(token, forKey: "qb.token")
                keychain.setString(selectedAccount.hashedAccountNumber, forKey: "qb.account")
            }, onError: { (error) in
                dump(error)
            })
            .addDisposableTo(self.disposeBag)
        
    }
    

    
}
