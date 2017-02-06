//
//  ServiceType.swift
//  ANZ
//
//  Created by Will Townsend on 29/01/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import Foundation

protocol ServiceType {
    
    /// The configuration of the server
    var serverConfig: ServerConfigType { get }
    
    /// The id of the next request
    var requestId: Int { get }
    
    /// The client API key
    var apiKey: String { get }
    
    /// The clients device id. This is a UUID
    var deviceId: String { get }
    
    /// The clients user agent. Eg. 'goMoney NZ/5.8.1/wifi/samsung SM-G900F/4.4.2/landscape/'
    var userAgent: String { get }
    
    /// The clients device description. Eg: 'SM-G900F'
    var deviceDescription: String { get }
    
    /// The android devices' API version. Eg. '19'
    var deviceApiVersion: String { get }
    
    /// The current access token.
    var accessToken: String? { get }
    
    /// The clients current session id
    var ibSessionId: String? { get }
    
}

extension ServiceType {
    
    fileprivate var defaultHeaders: [String: String] {
        
        var headers = [String: String]()
        
        headers["User-Agent"] = self.userAgent
        headers["Android-Device-Description"] = self.deviceDescription
        headers["Android-Api-Version"] = self.deviceApiVersion
        headers["Api-Key"] = self.apiKey
        headers["Api-Request-Id"] = String(self.requestId)
        headers["Content-Type"] = "application/json; charset=utf-8"
        headers["Accept"] = "application/json; charset=utf-8"

        headers["Device-Id"] = self.deviceId

        if let accessToken = self.accessToken {
            headers["Access-Token"] = accessToken
        }
        
        if let ibSessionId = self.ibSessionId {
            headers["IB-Session-ID"] = ibSessionId
        }
        
        return headers
    }
    
    public func preparedRequest(forURL url: URL, method: HTTPMethod = .get, parameters: [String: Any]? = nil)
        -> URLRequest {
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            return self.preparedRequest(forRequest: request, parameters: parameters)
    }
    
    public func preparedRequest(forRequest originalRequest: URLRequest, parameters: [String: Any]? = nil)
        -> URLRequest {
            
            var request = originalRequest
            guard let URL = request.url else {
                return originalRequest
            }
            
            var headers = self.defaultHeaders
            
            let method = request.httpMethod?.uppercased()
            
            var components = URLComponents(url: URL, resolvingAgainstBaseURL: false)!
            
            if let parameters = parameters {
                
                //var queryItems = components.queryItems ?? []
                
                if method == .some("POST") || method == .some("PUT") {
                    if request.httpBody == nil {
                        headers["Content-Type"] = "application/json; charset=utf-8"
                        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
                    }
                } else {
                    //                    queryItems.append(
                    //                        contentsOf: query
                    //                            .flatMap(queryComponents)
                    //                            .map(URLQueryItem.init(name:value:))
                    //                    )
                }
                
                //components.queryItems = queryItems.sorted { $0.name < $1.name }
                request.url = components.url
            }
            
            let currentHeaders = request.allHTTPHeaderFields ?? [:]
            request.allHTTPHeaderFields = currentHeaders.withAllValuesFrom(headers)
            
            return request
    }
    
    func request(route: RouteType) -> URLRequest {
        
        let properties = route.requestProperties
        let baseUrl = self.serverConfig.urlForBaseURL(baseURL: properties.baseURL)
        let URL = baseUrl.appendingPathComponent(properties.path)
        let request = self.preparedRequest(forURL: URL, method: properties.method, parameters: properties.parameters)
        
        return request
    }
    
}
