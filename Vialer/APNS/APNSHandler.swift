//
//  APNSHandler.swift
//  Vialer
//
//  Created by Chris Kontos on 05/06/2019.
//  Copyright © 2019 VoIPGRID. All rights reserved.
//

import Foundation
import PushKit
import UIKit


@objc class APNSHandler: NSObject, PKPushRegistryDelegate {
    
// MARK: - Properties
    @objc static var sharedAPNSHandler = APNSHandler()
    @objc var voipRegistry: PKPushRegistry = PKPushRegistry(queue: nil)
    @objc var middleware: Middleware = Middleware()
    
// MARK: - Lifecyrcle
    @objc private override init(){}
    
    @objc class func setSharedHandler(_ sharedHandler: APNSHandler) {
        if sharedAPNSHandler != sharedHandler {
            sharedAPNSHandler = sharedHandler
        }
    }
    
// MARK: - Actions
    @objc func registerForVoIPNotifications() {
        // Only register once, if delegate is set, registration has been done before:
        if voipRegistry.delegate == nil {
            voipRegistry.delegate = self
            
            VialerLogVerbose("Initiating VoIP push registration")
            voipRegistry.desiredPushTypes = Set([.voIP])
        }
    }
    
    @objc class func storedAPNSToken() -> String? {
        let sharedHandler: APNSHandler? = self.sharedAPNSHandler
        let token: Data? = sharedHandler?.voipRegistry.pushToken(for: .voIP)
        return sharedHandler?.nsString(fromNSData: token) as String?
    }
    
// MARK: - PKPushRegistry management
    @objc func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        VialerLogWarning("APNS Token became invalid")
    }
    
    @objc func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
        VialerLogDebug("Incoming push notification of type: \(type)")
        middleware.handleReceivedAPSNPayload(payload.dictionaryPayload)
    }
    
    @objc func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        VialerLogInfo("Type:\(type). APNS registration successful. Token: \(credentials.token)")
        middleware.sentAPNSToken(nsString(fromNSData: credentials.token) as String? ?? "" as String)
    }
    
// MARK: - Token conversion
    @objc func nsString(fromNSData data: Data?) -> NSString? { //no error
        guard let data = data else { return "" }
        let token = data.map { String(format: "%02.2hhx", $0 as CVarArg) }.joined()
        return NSString(utf8String: token)
    }
}
