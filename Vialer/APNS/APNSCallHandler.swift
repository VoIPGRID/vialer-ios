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
    
    func handle(completion: @escaping () -> Void, uuid: UUID, number: String, update: CXCallUpdate) {
       
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
        
        SIPUtils.setupSIPEndpoint()
        
        registerAndRespond(uuid: uuid)
        
        sleep(1)
        
        callKit.reportNewIncomingCall(with: uuid, update: update, completion: { (error) in
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
                
            VialerSIPLib.sharedInstance().callManager.add(newCall)
        
            self.registerAndRespond(uuid: uuid)
            
            completion()
        })
    }
    
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
    
    private func callFailed(uuid: UUID) {
        VialerLogError("Incoming call failed to setup!")
        self.callKit.reportCall(with: uuid, endedAt: nil, reason: CXCallEndedReason.failed)
    }

    private func respondToMiddleware(available: Bool) {
        guard let url: String = payload.dictionaryPayload[PushedCall.MiddlewareAPNSPayloadKeyResponseAPI] as? String else { return }
        
        let middleware = MiddlewareRequestOperationManager(baseURLasString: url)
        
        middleware?.sentCallResponse(toMiddleware: payload.dictionaryPayload, isAvailable: available, withCompletion: { (error) in
            VialerLogInfo("Responded to middleware!")
        })
    }
    
    private func rejectCall(uuid: UUID, update: CXCallUpdate) {
        callKit.reportNewIncomingCall(with: uuid, update: update, completion: { (error) in
            self.callKit.reportCall(with: uuid, endedAt: nil, reason: CXCallEndedReason.failed)
        })
    }
}
