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
    
    // MARK: - Lifecycle
    @objc private override init(){}
    
    @objc class func setSharedHandler(_ sharedHandler: APNSHandler) {
        if sharedAPNSHandler != sharedHandler {
            sharedAPNSHandler = sharedHandler
        }
    }
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
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
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        if type == .voIP {
            // Extract the call information from the push notification payload
            if let phoneNumberString = payload.dictionaryPayload[PushedCall.MiddlewareAPNSPayloadKeyPhonenumber] as? String,
                let uuidString = payload.dictionaryPayload[PushedCall.MiddlewareAPNSPayloadKeyUniqueKey] as? String {
                    // The uuid string in the payload is missing hyphens so fix that.
                    let callUUID = NSUUID.uuidFixer(uuidString: uuidString)! as UUID
                    
                    // Configure the call information data structures.
                    let callUpdate = CXCallUpdate()
                    let phoneNumberHandle = CXHandle(type: .phoneNumber, value: phoneNumberString)
                    callUpdate.remoteHandle = phoneNumberHandle
                    callUpdate.localizedCallerName = phoneNumberString
                    if let callerId = payload.dictionaryPayload[PushedCall.MiddlewareAPNSPayloadKeyCallerId] as? String {
                        callUpdate.localizedCallerName = callerId
                    }

                    VialerLogDebug("Reporting a new call to CallKit provider with UUID: \(String(describing: callUUID.uuidString))")
                    appDelegate.callKitProviderDelegate.provider.reportNewIncomingCall(with: callUUID, update: callUpdate, completion: { (error) in
                    // TODO with each push message the same call is reported multiple times before middleware knows the call is setup, is that a problem?
                        if error == nil {  // The call is not blocked by DnD or blacklisted by the iPhone, so continue processing the call. At this stage account is not available - sip invite has not arrived yet.
                            
                            let newCall = VSLCall(inboundCallWith: callUUID, number: phoneNumberString, name:callUpdate.localizedCallerName ?? "")
                            let callManager =  VialerSIPLib.sharedInstance().callManager
                            callManager.add(newCall!)
                        
                            DispatchQueue.main.async {
                                self.middleware.handleReceivedAPSNPayload(payload.dictionaryPayload)
                            }
                        }
                        // Tell PushKit that the notification is handled.
                        completion()
                    })
            }
        }
    }
    
    @objc func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        VialerLogInfo("Type:\(type). APNS registration successful.")
        middleware.sentAPNSToken(nsString(fromNSData: credentials.token) as String? ?? "")
    }
    
    // MARK: - Token conversion
    /*
     * Returns hexadecimal string of NSData. Empty string if data is empty.
     * http://stackoverflow.com/questions/1305225/best-way-to-serialize-a-nsdata-into-an-hexadeximal-string
     */
    @objc func nsString(fromNSData data: Data?) -> NSString? {
        guard
            let data = data
            else {
                return ""
        }
        let token = data.map { String(format: "%02.2hhx", $0) }.joined()
        return NSString(utf8String: token)
    }
}

