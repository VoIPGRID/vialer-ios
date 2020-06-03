//
//  SynchronousSipRegistration.swift
//  Vialer
//
//  Created by Jeremy Norman on 08/04/2020.
//  Copyright © 2020 VoIPGRID. All rights reserved.
//

import Foundation
import PushKit

class SynchronousSipRegistration {
    
    private var hasRegistered = false

    private var hasFailed = false

    private var vsl = VialerSIPLib.sharedInstance()

    var account: VSLAccount?

    /**
        Perform synchronous registration, this code will hang until registration succeeds or fails
     */
    func register() -> Bool {
        performRegister()

        return hasRegistered
    }

    /**
        Perform asynchronous registration and then stall in a while loop
        until that registration request has returned.
    */
    func performRegister() {
        VialerLogInfo("Attempting to register SIP account")

        if (vsl.firstAccount()?.isRegistered == true) {
            VialerLogInfo("Account is already registered!")
            hasRegistered = true
            self.account = vsl.firstAccount()
            return;
        }

        SIPUtils.registerSIPAccountWithEndpoint { (success, account) in
            if (success) {
                VialerLogInfo("Registered successfully")
                self.hasRegistered = true
                self.account = account
            } else {
                VialerLogInfo("Registration failed")
                self.hasFailed = true
            }
        }

        let TIMEOUT_MILLISECONDS = 10 * 1000
        let MILLISECONDS_BETWEEN_ITERATION = 5
        var millisecondsTrying = 0

        while (!hasRegistered && !hasFailed && millisecondsTrying < TIMEOUT_MILLISECONDS) {
            millisecondsTrying += MILLISECONDS_BETWEEN_ITERATION
            usleep(useconds_t(MILLISECONDS_BETWEEN_ITERATION * 1000))
        }
    }
}
