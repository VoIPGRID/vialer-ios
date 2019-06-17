//
//  Resource.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import Foundation

typealias JSONDictionary = [String: Any]

/// Generic Resource struct
struct Resource<A> {
    /// Relative path to the base URL
    let path: String
    /// Optional parameters to sent with the request
    var parameters: [String: Any]?
    /// Parser that will parse raw Data to specific type
    let parse: (Data) -> A?
}

extension Resource {
    /// Convience initializer to create Resource struct that will parse JSON responses
    ///
    /// - Parameters:
    ///   - path: Relative path to the base URL
    ///   - parameters: Optional parameters to sent with the request
    ///   - parseJSON: Parser that will parse JSON to specific type
    init(path: String, parameters: [String: Any]? = nil, parseJSON: @escaping (JSONDictionary) -> A?) {
        self.path = path
        self.parameters = parameters
        self.parse = { data in
            guard let json = ((try? JSONSerialization.jsonObject(with: data, options: []) as? JSONDictionary) as JSONDictionary??) else { return nil }
            return json.flatMap(parseJSON)
        }
    }

    mutating func add(parameters: [String: Any]) {
        self.parameters += parameters
    }
}

func += <String: Any> (lhs: inout [String: Any]?, rhs: [String: Any]) {
    var new = lhs ?? [String: Any]()
    for (k, v) in rhs {
        new.updateValue(v, forKey: k)
    }
    lhs = new
}
