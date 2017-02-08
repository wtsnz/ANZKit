//
//  Coordinator.swift
//  ANZ
//
//  Created by Will Townsend on 8/02/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import Foundation

/// The Coordinator protocol
public protocol Coordinator: class {
    
    /// The services that the coordinator can use
    var context: AppContext { get }
    
    /// The array containing any child Coordinators
    var childCoordinators: [Coordinator] { get set }
    
}

public extension Coordinator {
    
    /// Add a child coordinator to the parent
    public func addChildCoordinator(_ childCoordinator: Coordinator) {
        self.childCoordinators.append(childCoordinator)
    }
    
    /// Remove a child coordinator from the parent
    public func removeChildCoordinator(_ childCoordinator: Coordinator) {
        self.childCoordinators = self.childCoordinators.filter { $0 !== childCoordinator }
    }
    
}
