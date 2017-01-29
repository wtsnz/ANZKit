//
//  ServerConfig.swift
//  ANZ
//
//  Created by Will Townsend on 29/01/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import Foundation

public protocol ServerConfigType {
    var preAuthBaseUrl: URL { get }
    var baseUrl: URL { get }
}

internal extension ServerConfigType {
    
    func urlForBaseURL(baseURL: BaseURL) -> URL {
        switch baseURL {
        case .preAuth:
            return self.preAuthBaseUrl
        case .standard:
            return self.baseUrl
        }
    }
}

public struct ServerConfig: ServerConfigType {
    
    public let preAuthBaseUrl: URL
    public let baseUrl: URL
    
    public static let production: ServerConfigType = ServerConfig(
        preAuthBaseUrl: URL(string: "https://digital.anz.co.nz/preauth/web/api/v1")!,
        baseUrl: URL(string: "https://secure.anz.co.nz/api/v6")!
    )
    
}
