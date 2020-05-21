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
    let synchronousSip: SynchronousSipRegistration
    let vsl = VialerSIPLib.sharedInstance()

    var call: VSLCall?

    init(payload: PKPushPayload) {
        self.payload = payload
        self.synchronousSip = SynchronousSipRegistration()
    }
    
    /**
        Process an incoming VoIP notification, launching the Call UI and connecting to the back-end.
     */
    func handle(completion: @escaping () -> Void, uuid: UUID, number: String, update: CXCallUpdate) {
        if (!(SystemUser.current()?.sipEnabled ?? false)) {
            VialerLogError("There is no user, we are rejecting the call, the user will still hear this notification so this should not be happening..")
            rejectCall(uuid: uuid, update: update)
            return
        }

        if (!reachabilityHelper.connectionFastEnoughForVoIP()) {
            VialerLogWarning("The connection is not fast enough for VoIP but we can no longer decline the call.")
        }

        if (!synchronousSip.register()) {
            self.callFailed(uuid: uuid)
            return
        }

        respondToMiddleware(available: true)

        callKit.reportNewIncomingCall(with: uuid, update: update, completion: { (error) in
            if error != nil {
                self.callFailed(uuid: uuid)
                completion()
                return
            }

            self.call = VSLCall(inboundCallWith: uuid, number: number, name: update.localizedCallerName ?? "")

            if let call = self.call {
                call.account = self.synchronousSip.account ?? nil
                self.vsl.callManager.add(call)
            }

            completion()
        })


        stopRingingIfInvalidCall(uuid: uuid)
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

    /**
        We are going to wait a short amount of time and then check to see if our incoming call has
        an actual invite, this should validate that it is a valid call.
     */
    private func stopRingingIfInvalidCall(uuid: UUID) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let hasInvite = self.call?.invite != nil
            if (!hasInvite) {
                VialerLogError("Call does not have an invite, therefore stopping ringing and marking as failed")
                self.callFailed(uuid: uuid)
            }
        }
    }
}
