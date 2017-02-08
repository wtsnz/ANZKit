//
//  AppCoordinator.swift
//  ANZ
//
//  Created by Will Townsend on 8/02/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//


import Foundation
import UIKit

/// The AppCoordinator is our first coordinator
/// In this example the AppCoordinator as a rootViewController
class AppCoordinator: RootViewCoordinator {
    
    // MARK: - Properties
    
    let context: AppContext
    var childCoordinators: [Coordinator] = []
    
    var rootViewController: UIViewController {
        return self.navigationController
    }
    
    /// Window to manage
    let window: UIWindow
    
    private lazy var navigationController: UINavigationController = {
        let navigationController = UINavigationController()
        navigationController.isNavigationBarHidden = true
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
        self.showAuthenticationViewController()
    }
    
    /// Creates a new SplashViewController and places it into the navigation controller
    private func showAuthenticationViewController() {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "auth") as! ViewController
        viewController.context = self.context
        self.navigationController.viewControllers = [viewController]

    }
    
}
