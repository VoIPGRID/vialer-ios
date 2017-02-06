//
//  WebserviceAuthentication.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import Foundation

/// Convience Protocol to make authentication initialization easy for webservice
protocol WebserviceAuthentication {
    var username: String! { get }
    var password: String! { get }
}

extension Webservice {
    /// Convience initializer
    ///
    /// Can use any instance that will confirm to Webservice Authentication to setup authenticated requests
    ///
    /// - Parameter authentication: instance that confirms to WebserviceAuthentication
    convenience init(authentication: WebserviceAuthentication) {
        self.init(username: authentication.username, password: authentication.password)
    }
}

/// Let SystemUser conform to WebserviceAuthentication
extension SystemUser : WebserviceAuthentication {}
