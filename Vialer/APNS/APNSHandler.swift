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
    
    let callKit = (UIApplication.shared.delegate as! AppDelegate).callKitProviderDelegate.provider!
    let reachabilityHelper = ReachabilityHelper.sharedInstance()
    var payload: PKPushPayload = PKPushPayload() //orp just for testing changes
    
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
        guard type == .voIP else { return }
        
        // Extract the call information from the push notification payload.
        if let number = payload.dictionaryPayload[PushedCall.MiddlewareAPNSPayloadKeyPhonenumber] as? String,
            let uuidString = payload.dictionaryPayload[PushedCall.MiddlewareAPNSPayloadKeyUniqueKey] as? String {
            // The uuid string in the payload is missing hyphens so fix that.
            let uuid = NSUUID.uuidFixer(uuidString: uuidString)! as UUID
            
            // Configure the call information data structures.
            let update = CXCallUpdate()
            let phoneNumberHandle = CXHandle(type: .phoneNumber, value: number)
            update.remoteHandle = phoneNumberHandle
            update.localizedCallerName = number
            if let callerId = payload.dictionaryPayload[PushedCall.MiddlewareAPNSPayloadKeyCallerId] as? String {
                update.localizedCallerName = callerId
            }
            
            self.payload = payload

            if (!(SystemUser.current()?.sipEnabled ?? false)) {
                VialerLogError("There is no user, we are rejecting the call, the user will still hear this notification so this should not be happening..")
                rejectCall(uuid: uuid, update: update)
                return
            }

            if (!reachabilityHelper.connectionFastEnoughForVoIP()) {
                VialerLogWarning("The connection is not fast enough for VoIP but we can no longer decline the call.")
            }

            SIPUtils.setupSIPEndpoint()

            registerAndRespond(uuid: uuid)

            sleep(1)

            callKit.reportNewIncomingCall(with: uuid, update: update, completion: { (error) in
                if error != nil {
                     self.callFailed(uuid: uuid)
                     completion()
                     return
                }

                completion()
            })
            guard let newCall = VSLCall(inboundCallWith: uuid, number: number, name:update.localizedCallerName ?? "") else {
                 self.callFailed(uuid: uuid)
                 return
            }
             
            VialerSIPLib.sharedInstance().callManager.add(newCall)

            self.registerAndRespond(uuid: uuid)
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
    
    /**
           Register to SIP and respond to the middleware when registered successfully.
    */
    private func registerAndRespond(uuid: UUID) {
        SIPUtils.registerSIPAccountWithEndpoint { (success, account) in
            if (!success) {
               self.callFailed(uuid: uuid)
               return
            }

            guard let call = VialerSIPLib.sharedInstance().callManager.call(with: uuid) else { return }

            if (call.account != nil) { return }

            call.account = account

            self.respondToMiddleware(available: true)
        }
    }
   
    private func respondToMiddleware(available: Bool) {
        //guard let payload = payload else { return }
        guard let url: String = payload.dictionaryPayload[PushedCall.MiddlewareAPNSPayloadKeyResponseAPI] as? String else { return }

        let middleware = MiddlewareRequestOperationManager(baseURLasString: url)

        middleware?.sentCallResponse(toMiddleware: payload.dictionaryPayload, isAvailable: available, withCompletion: { (error) in
            VialerLogInfo("Responded to middleware!")
        })
    }
   
    private func callFailed(uuid: UUID) {
        VialerLogError("Incoming call failed to setup!")
        self.callKit.reportCall(with: uuid, endedAt: nil, reason: CXCallEndedReason.failed)
    }
   
   /**
       To reject a call we have to momentarily show the UI and then immediately report it as failed. The user will still see/hear
       the incoming call briefly.
    */
    private func rejectCall(uuid: UUID, update: CXCallUpdate) {
        callKit.reportNewIncomingCall(with: uuid, update: update, completion: { (error) in
            self.callKit.reportCall(with: uuid, endedAt: nil, reason: CXCallEndedReason.failed)
        })
    }
}

