//
//  APNSCallHandler.swift
//  Vialer
//
//  Created by Jeremy Norman on 20/03/2020.
//  Copyright © 2020 VoIPGRID. All rights reserved.
//

import Foundation
import PushKit

class APNSCallHandler {
    
    let callKit = (UIApplication.shared.delegate as! AppDelegate).callKitProviderDelegate.provider!
    let reachabilityHelper = ReachabilityHelper.sharedInstance()
    let payload: PKPushPayload
    
    static var handledUuids = [String]()
    
    init(payload: PKPushPayload) {
        self.payload = payload
    }
    
    /**
        Process an incoming VoIP notification, launching the Call UI and connecting to the back-end.
     */
    func handle(completion: @escaping () -> Void, uuid: UUID, number: String, update: CXCallUpdate) {
        VialerLogError("ASDASDASDbe happening.. \(String(Thread.isMainThread))")
        // This is to temporarily ignore all other push notifications for this call, it can be removed
        // when the middleware only sends one.
        if (APNSCallHandler.handledUuids.contains(uuid.uuidString)) { return }
       
        APNSCallHandler.handledUuids.append(uuid.uuidString)
        
        if (!(SystemUser.current()?.sipEnabled ?? false)) {
            VialerLogError("There is no user, we are rejecting the call, the user will still hear this notification so this should not be happening..")
            rejectCall(uuid: uuid, update: update)
            return
        }
        
        if (!reachabilityHelper.connectionFastEnoughForVoIP()) {
            VialerLogWarning("The connection is not fast enough for VoIP but we can no longer decline the call.")
        }
        
        callKit.reportNewIncomingCall(with: uuid, update: update, completion: { (error) in
            VialerLogError("Reported")
            if error != nil {
                self.callFailed(uuid: uuid)
                completion()
                return
            }
                
            guard let newCall = VSLCall(inboundCallWith: uuid, number: number, name:update.localizedCallerName ?? "") else {
                self.callFailed(uuid: uuid)
                completion()
                return
            }
            
            SIPUtils.setupSIPEndpoint()
                
            self.registerAndRespond(uuid: uuid)
            
            VialerSIPLib.sharedInstance().callManager.add(newCall)
        
            completion()
        })
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
