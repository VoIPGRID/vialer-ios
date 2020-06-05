//
//  SynchronousSipRegistration.swift
//  Vialer
//
//  Created by Jeremy Norman on 08/04/2020.
//  Copyright © 2020 VoIPGRID. All rights reserved.
//

import Foundation
import PushKit

class VoipTaskSynchronizer {
    
    private var hasRegistered = false

    private var hasFailed = false

    private var hasRespondedToMiddleware = false

    private var vsl = VialerSIPLib.sharedInstance()

    var account: VSLAccount?

    /**
        Perform asynchronous registration and then stall in a while loop
        until that registration request has returned.
    */
    func registerWithSip() -> (Bool, VSLAccount?) {
        VialerLogInfo("Attempting to register SIP account")

        SIPUtils.setupSIPEndpoint()

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

        wait(timeoutInMilliseconds: 10000, until: { hasRegistered || hasFailed })

        return (hasRegistered, self.account)
    }

    /**
        Respond to the middleware synchronously.
    */
    func respondToMiddleware(payload: PKPushPayload) -> Bool {
        guard let url: String = payload.dictionaryPayload[PushedCall.MiddlewareAPNSPayloadKeyResponseAPI] as? String else {
            return false
        }

        do {
            VialerLogInfo("Attempting to respond to middleware")
            let post = "unique_key=\(payload.dictionaryPayload["unique_key"]!)&available=True&message_start_time=\(payload.dictionaryPayload["message_start_time"]!)" as NSString
            let apiUrl = URL(string: url)!
            let postData = post.data(using: String.Encoding.ascii.rawValue)!
            let postLength = String( postData.count ) as NSString
            let request = NSMutableURLRequest(url: apiUrl)

            request.httpMethod = "POST"
            request.httpBody = postData
            request.setValue(postLength as String, forHTTPHeaderField: "Content-Length")
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            var response: URLResponse?
            try NSURLConnection.sendSynchronousRequest(request as URLRequest, returning:&response)
            VialerLogInfo("Successfully responded to middleware")
            return true
        } catch let error as NSError {
            VialerLogError("Error... \(error.localizedDescription)")
            return false
        }
    }

    /**
        We will wait for to make sure that our SIP call has been confirmed.
    */
    func waitForCallConfirmation() -> Bool {
        wait(timeoutInMilliseconds: 5000) { APNSCallHandler.incomingCallConfirmed }

        return APNSCallHandler.incomingCallConfirmed
    }

    /**
        Wait for a given condition or until a certain timeout has been reached.
    */
    private func wait(timeoutInMilliseconds: Int = 10000, until: () -> Bool) {
        let TIMEOUT_MILLISECONDS = timeoutInMilliseconds
        let MILLISECONDS_BETWEEN_ITERATION = 5
        var millisecondsTrying = 0

        while (!until() && millisecondsTrying < TIMEOUT_MILLISECONDS) {
            millisecondsTrying += MILLISECONDS_BETWEEN_ITERATION
            usleep(useconds_t(MILLISECONDS_BETWEEN_ITERATION * 1000))
        }
    }
}
