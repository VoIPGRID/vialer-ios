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
        
        if (!reachabilityHelper.connectionFastEnoughForVoIP()) {
            VialerLogInfo("Rejecting the call because our connection is not fast enough")
            respondToMiddleware(available: false)
            rejectCall(uuid: uuid, update: update)
            return
        }
        
        SIPUtils.setupSIPEndpoint()
        
        callKit.reportNewIncomingCall(with: uuid, update: update, completion: { (error) in
            if error != nil {
                VialerLogDebug("ERRROR!")
                completion()
                return
            }
                
            guard let newCall = VSLCall(inboundCallWith: uuid, number: number, name:update.localizedCallerName ?? "") else {
                VialerLogError("FAILED TO CREATE CALL, ABORT!")
                completion()
                return
            }
                
            VialerSIPLib.sharedInstance().callManager.add(newCall)
        
            completion()
        })
        
        SIPUtils.registerSIPAccountWithEndpoint { (success, account) in
            if (!success) {
                self.callKit.reportCall(with: uuid, endedAt: nil, reason: CXCallEndedReason.failed)
                VialerLogError("FAILED TO REGISTER!")
                return
            }
            
            VialerSIPLib.sharedInstance().callManager.call(with: uuid)?.account = account
            
            self.respondToMiddleware(available: true)
        }
    }

    func respondToMiddleware(available: Bool) {
        guard let url: String = payload.dictionaryPayload[PushedCall.MiddlewareAPNSPayloadKeyResponseAPI] as? String else { return }
        
        let middleware = MiddlewareRequestOperationManager(baseURLasString: url)
        
        middleware?.sentCallResponse(toMiddleware: payload.dictionaryPayload, isAvailable: available, withCompletion: { (error) in
            VialerLogInfo("Responded to middleware!")
        })
    }
    
    func rejectCall(uuid: UUID, update: CXCallUpdate) {
        callKit.reportNewIncomingCall(with: uuid, update: update, completion: { (error) in
            self.callKit.reportCall(with: uuid, endedAt: nil, reason: CXCallEndedReason.failed)
        })
    }
}
