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
    @available(iOS 10.0, *)
    lazy var provider = CXProvider(configuration: CXProviderConfiguration(localizedName: "Vialer"))
    lazy var vialerSIPLib = VialerSIPLib.sharedInstance()
    var callKitProviderDelegate: CallKitProviderDelegate! //orp
    var mostRecentCall : VSLCall?
    
    
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
    
    
    @objc func pushRegistry(_ registry: PKPushRegistry, didUpdate credentials: PKPushCredentials, for type: PKPushType) {
        VialerLogInfo("Type:\(type). APNS registration successful.")
        middleware.sentAPNSToken(nsString(fromNSData: credentials.token) as String? ?? "")
    }
    
//    @objc func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType) {
//        VialerLogDebug("Incoming push notification of type: \(type)")
//        middleware.handleReceivedAPSNPayload(payload.dictionaryPayload)
//    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        
        print(payload.dictionaryPayload) //orp
        let phonenumber = payload.dictionaryPayload["phonenumber"] as! NSString

        callKitProviderDelegate = CallKitProviderDelegate(callManager: vialerSIPLib.callManager)
        VialerLogDebug("Incoming push notification of type: \(type)")
        if #available(iOS 10.0, *) {
            let appname = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Vialer"
            let providerConfiguration = CXProviderConfiguration(localizedName: NSLocalizedString(appname, comment: ""))

            providerConfiguration.maximumCallGroups = 2
            providerConfiguration.maximumCallsPerCallGroup = 1
            //providerConfiguration.supportsVideo = !VSLEndpoint.shared().endpointConfiguration.disableVideoSupport
            //providerConfiguration.supportsVideo = false //by default //orp

            if Bundle.main.path(forResource: "ringtone", ofType: "wav") != nil {
                providerConfiguration.ringtoneSound = "ringtone.wav"
            } else {
             // print in log that there was no ringtone file //orp
            }

            providerConfiguration.supportedHandleTypes = [CXHandle.HandleType.phoneNumber]
            provider = CXProvider(configuration: providerConfiguration)
            provider.setDelegate(callKitProviderDelegate, queue: nil)

            NotificationCenter.default.addObserver(callKitProviderDelegate, selector: #selector(CallKitProviderDelegate.callStateChanged(_:)), name: NSNotification.Name.VSLCallStateChanged, object: nil)
        }
        
        if type == .voIP {
            if #available(iOS 10.0, *) {
                let callUpdate = CXCallUpdate()
                callUpdate.remoteHandle = CXHandle(type: .phoneNumber, value: phonenumber as String)
                let callUUID = UUID()
                
                provider.reportNewIncomingCall(with: callUUID,
                            update: callUpdate, completion: { (error) in
                   if error == nil {
                      // If the system allows the call to proceed, make a data record for it.
//                          let newCall = VoipCall(callUUID, phoneNumber: handle)
//                          self.callManager.addCall(newCall)
                        //create/update the call object here?
                        self.vialerSIPLib.setIncomingCall { call in
                            VialerGAITracker.incomingCallRingingEvent()
                            DispatchQueue.main.async {
                                VialerLogInfo("Incoming call block invoked, routing through CallKit.")
                                self.mostRecentCall = call
                                self.callKitProviderDelegate.reportIncomingCall(call)
                            }
                        }
                   }

                   // Tell PushKit that the notification is handled.
                   completion()
                })
            }
        }
        
        middleware.handleReceivedAPSNPayload(payload.dictionaryPayload)
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

