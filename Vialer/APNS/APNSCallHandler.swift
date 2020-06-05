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
    let synchronously: VoipTaskSynchronizer
    let vsl = VialerSIPLib.sharedInstance()

    // This will be updated and set to TRUE when we have confirmation that we have received a call via SIP.
    // If we do not get this confirmation we can assume the call has failed and cancel the ringing.
    // However, it must always be set to false when a new call is coming in.
    static var incomingCallConfirmed = false

    init(payload: PKPushPayload) {
        self.payload = payload
        self.synchronously = VoipTaskSynchronizer()
    }
    
    /**
        Process an incoming VoIP notification, launching the Call UI and connecting to the back-end.
     */
    func handle(completion: @escaping () -> Void, uuid: UUID, number: String, update: CXCallUpdate) {
        // We must set this back to false before an incoming call so we can confirm the call later.
        APNSCallHandler.self.incomingCallConfirmed = false

        // If SIP is not enabled, we don't want to ring. This is a strange situation but we are covering it incase.
        if (!(SystemUser.current()?.sipEnabled ?? false)) {
            rejectCall(uuid: uuid, update: update, description: "There is no user, we are rejecting the call, the user will still hear this notification so this should not be happening..")
            return
        }

        // While we don't want to ring without a proper connection, this is apple policy to do so. We will just let the user
        // make the call rather than rejecting it as we would have to display the incoming call screen regardless.
        if (!reachabilityHelper.connectionFastEnoughForVoIP()) {
            VialerLogWarning("The connection is not fast enough for VoIP but we can no longer decline the call.")
        }

        // We will now WAIT synchronously to register with SIP.
        let (registered, account) = synchronously.registerWithSip()

        // If registration was not successful, then we reject the call.
        if (!registered) {
            rejectCall(uuid: uuid, update: update, description: "Failed to register with SIP, rejecting the call...")
            return
        }

        // We are going to make the incoming call before we respond to the middleware as the library expects
        // a call to exist before it will be accepted. This will prevent the race condition where the call has
        // yet to be created when we receive the call via SIP.
        guard let call = VSLCall(inboundCallWith: uuid, number: number, name: update.localizedCallerName ?? "") else {
            rejectCall(uuid: uuid, update: update, description: "Unable to create call with the uuid \(uuid.uuidString)")
            return
        }

        // Now we have a call, we have to connect it to an account and add it to the call manager so it
        // can be accessed by VSL.
        call.account = account
        self.vsl.callManager.add(call)

        // We have created a call object, so respond to the middleware so we can receive the actual SIP call.
        if (!synchronously.respondToMiddleware(payload: self.payload)) {
            rejectCall(uuid: uuid, update: update, description: "Failed to respond to middleware, rejecting the call.")
            return
        }

        // We are going to now wait for a few seconds to make sure an actual call comes through via SIP. If we don't
        // receive one then we will reject the call. The mostly likely situation here is that the call has been answered
        // elsewhere.
        if (!synchronously.waitForCallConfirmation()) {
            rejectCall(uuid: uuid, update: update, reason: CXCallEndedReason.answeredElsewhere, description: "Unable to confirm call in-time, failing the call.")
            return
        }

        // This will trigger the call to start ringing, we MUST ALWAYS trigger this for every VoIP push notification
        // as this is Apple's policy and we will no longer receive push notifications if we do not do this.
        callKit.reportNewIncomingCall(with: uuid, update: update, completion: { (error) in
            if error != nil {
                VialerLogError("Incoming call failed to setup!")
                self.callKit.reportCall(with: uuid, endedAt: nil, reason: CXCallEndedReason.failed)
                completion()
                return
            }

            completion()
        })
    }
    
    /**
        To reject a call we have to momentarily show the UI and then immediately report it as failed. The user will still see/hear
        the incoming call briefly.
     */
    private func rejectCall(uuid: UUID, update: CXCallUpdate, reason: CXCallEndedReason = CXCallEndedReason.failed, description: String) {
        VialerLogError(description)
        callKit.reportNewIncomingCall(with: uuid, update: update, completion: { (error) in
            self.callKit.reportCall(with: uuid, endedAt: nil, reason: reason)
        })
    }
}
