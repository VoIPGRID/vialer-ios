//
//  MiddlewareApiManager.swift
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

import Foundation

class MiddlewareApiManager {
    private var userLogout: NotificationToken

    private var webService: WebserviceProtocol!

    required init(webservice: WebserviceProtocol? = nil) {
        self.webService = webService ?? Webservice(authentication: SystemUser.current())

        // When a user logsout, remove all calls.
        userLogout = NotificationCenter.default.addObserver(descriptor: SystemUser.logoutNotification) { _ in
        }
    }

    public func update() {

    }
}
