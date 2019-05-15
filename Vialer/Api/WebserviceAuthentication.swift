//
//  WebserviceAuthentication.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import Foundation

/// Convience Protocol to make authentication initialization easy for webservice
protocol WebserviceAuthentication {
    var username: String! { get }
    var apiToken: String! { get }
}

extension Webservice {
    /// Convience initializer
    ///
    /// Can use any instance that will confirm to Webservice Authentication to setup authenticated requests
    ///
    /// - Parameter authentication: instance that confirms to WebserviceAuthentication
    convenience init?(authentication: WebserviceAuthentication) {
        guard let unwrappedUsername = authentication.username, let unwrappedApiToken = authentication.apiToken else {
            if let username = SystemUser.current()?.username, let apiToken = SystemUser.current()?.apiToken {
                self.init(username: username, apiToken: apiToken)
                return
            }
                return nil
        }
        self.init(username: unwrappedUsername, apiToken: unwrappedApiToken)
    }
}

/// Let SystemUser conform to WebserviceAuthentication
extension SystemUser : WebserviceAuthentication {}
