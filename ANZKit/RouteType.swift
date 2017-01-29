//
//  RouteType.swift
//  ANZ
//
//  Created by Will Townsend on 29/01/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import Foundation

extension Dictionary {
    func withAllValuesFrom(_ other: Dictionary) -> Dictionary {
        var result = self
        other.forEach { result[$0] = $1 }
        return result
    }
}

internal enum HTTPMethod: String {
    case options
    case get
    case head
    case post
    case put
    case patch
    case delete
    case trace
    case connect
}

internal enum BaseURL: String {
    case preAuth
    case standard
}

internal protocol RouteType {
    var requestProperties: (method: HTTPMethod, baseURL: BaseURL, path: String, parameters: [String: Any]?) { get }
}
