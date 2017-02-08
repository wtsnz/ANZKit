//
//  Services.swift
//  ANZ
//
//  Created by Will Townsend on 8/02/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import Foundation
import ANZKit

public struct AppContext {
    
    public let apiService: ANZService
    public let localDataService: LocalDataService
    
    public init(apiService: ANZService, localDataService: LocalDataService) {
        self.apiService = apiService
        self.localDataService = localDataService
    }
}

public class LocalDataService {
    
    
}
