//
//  ANZKitTests.swift
//  ANZKitTests
//
//  Created by Will Townsend on 29/01/17.
//  Copyright © 2017 Will Townsend. All rights reserved.
//

import XCTest

/// Return a path for a file in the the current bundle
func filePathFor(_ filename: String, ofType type: String) -> String? {
    @objc class TestClass: NSObject { }
    let bundle = Bundle(for: TestClass.self)
    let path = bundle.path(forResource: filename, ofType: type)
    return path
}

func fileURLFor(_ filename: String, ofType type: String) -> URL? {
    @objc class TestClass: NSObject { }
    let bundle = Bundle(for: TestClass.self)
    
    guard let path = bundle.path(forResource: filename, ofType: type) else {
        return nil
    }
    
    return URL(fileURLWithPath: path)
}

func jsonDataFor(_ filename: String, ofType type: String) -> Any? {
    
    guard let filePath = fileURLFor(filename, ofType: type) else {
        return nil
    }
    
    guard let data = try? Data.init(contentsOf: filePath) else {
        return nil
    }
    
    return try? JSONSerialization.jsonObject(with: data, options: [])
}

