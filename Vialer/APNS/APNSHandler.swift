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
    @available(iOS 10.0, *)
    static var callProvider = CXProvider(configuration: CXProviderConfiguration(localizedName: "Vialer"))

    @available(iOS 10.0, *)
    class func setCallProvider(_ provider: CXProvider) {
        callProvider = provider
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
    
//    @objc func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
//        VialerLogDebug("Incoming push notification of type: \(type)")
//        middleware.handleReceivedAPSNPayload(payload.dictionaryPayload)
//    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        if #available(iOS 10.0, *) {

            if type == .voIP {
                // Extract the call information from the push notification payload
                if let handle = payload.dictionaryPayload["phonenumber"] as? String, // TODO use constants for key
                    var uuidString = payload.dictionaryPayload["unique_key"] as? String
//                    let caller_id = payload.dictionaryPayload["caller_id"] as? String,
                    {
                    // unique_key in the payload is missing hyphens, so UUID initializer return nil, so add them.
                    uuidString.insert("-", at: uuidString.index(uuidString.startIndex, offsetBy: 8)) //  TODO: make more robust, and as a method
                    uuidString.insert("-", at: uuidString.index(uuidString.startIndex, offsetBy: 13))
                    uuidString.insert("-", at: uuidString.index(uuidString.startIndex, offsetBy: 18))
                    uuidString.insert("-", at: uuidString.index(uuidString.startIndex, offsetBy: 23))

                    let callUUID = UUID(uuidString: uuidString)
                    // Configure the call information data structures.
                    let callUpdate = CXCallUpdate()
                    let phoneNumber = CXHandle(type: .phoneNumber, value: handle)
                    callUpdate.remoteHandle = phoneNumber
//                    callUpdate.localizedCallerName = caller_id
                    callUpdate.localizedCallerName = "Connecting Call..." // At this stage you don't know yet whose calling, it will update after registration at Asteriks if successful.
                        
                    // Report the call to CallKit, and let it display the call UI.
                        APNSHandler.callProvider.reportNewIncomingCall(with: callUUID!, update: callUpdate, completion: { (error) in
                        if error == nil {
                            // If the system allows the call to proceed, make a data record for it.
//                            let newCall = VoipCall(callUUID, phoneNumber: phoneNumber)
                            
                            // TODO: at this stage account is not available yet - sip invite has not arrived
                            // TODO: create a new VSCall constructor with only uuid and phone number
                            
//                            let endpoint = VialerSIPLib.sharedInstance().endpoint
//                            let account = endpoint.lookupAccount(<#T##accountId: Int##Int#>)
//                            let newCall = VSLCall(inboundCallWithCallId: callUUID, account: <#T##VSLAccount#>)
                            let newCall = VSLCall(inboundCallWithUUIDandNumber: callUUID!, number: handle)
                            let callManager = VialerSIPLib.sharedInstance().callManager

                            callManager.add(newCall!)
                        }

                        // Tell PushKit that the notification is handled.
                        completion()
                    }
                )
                
                // Asynchronously register with the telephony server and
                // process the call. Report updates to CallKit as needed.
    //            establishConnection(for: callUUID)
                        middleware.handleReceivedAPSNPayload(payload.dictionaryPayload, uuid:callUUID!) // TODO: correct place? not directly after completion()
              }
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

