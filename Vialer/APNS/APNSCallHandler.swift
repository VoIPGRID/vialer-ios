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

    struct PayloadLookup {
        static let uniqueKey = "unique_key"
        static let phoneNumber = "phonenumber"
        static let responseUrl = "response_api"
        static let callerId = "caller_id"
    }

    let callKit = (UIApplication.shared.delegate as! AppDelegate).callKitProviderDelegate.provider
    let payload: PKPushPayload
    let vsl = VialerSIPLib.sharedInstance()
    let sip = SIPUtils.self

    // This will be updated and set to TRUE when we have confirmation that we have received a call via SIP.
    // If we do not get this confirmation we can assume the call has failed and cancel the ringing.
    // However, it must always be set to false when a new call is coming in.
    static var incomingCallConfirmed = false

    init(payload: PKPushPayload) {
        self.payload = payload
    }
    
    /**
        Process an incoming VoIP notification, launching the Call UI and connecting to the back-end.
     */
    func handle(completion: @escaping () -> Void, uuid: UUID, number: String, update: CXCallUpdate) {
        APNSCallHandler.self.incomingCallConfirmed = false

        let middleware = MiddlewareRequestOperationManager(baseURLasString: payload.dictionaryPayload[PayloadLookup.responseUrl] as! String)!

        callKit.reportNewIncomingCall(with: uuid, update: update, completion: { (error) in
            if error == nil {
                if self.vsl.hasActiveCall() {
                    middleware.sentCallResponse(toMiddleware: self.payload.dictionaryPayload, isAvailable: false)
                    self.rejectCall(uuid: uuid, description: "Rejecting call as there is already one in progress")
                    return
                }

                guard let call = VSLCall(inboundCallWith: uuid, number: number, name: update.localizedCallerName ?? "") else {
                    self.rejectCall(uuid: uuid, description: "Unable to create call with the uuid \(uuid.uuidString)")
                    return
                }

                self.vsl.callManager.add(call)
            }

            completion()
        })

        establishConnection(for: uuid, middleware: middleware)
    }

    private func establishConnection(for uuid: UUID, middleware: MiddlewareRequestOperationManager) {
        if vsl.hasActiveCall() {
            return
        }

        sip.setupSIPEndpoint()

        sip.registerSIPAccountWithEndpoint { (success, account) in
            if (!success) {
                self.rejectCall(uuid: uuid, description: "Failed to register with SIP, rejecting the call...")
                return;
            }

            self.vsl.callManager.call(with: uuid)?.account = account

            middleware.sentCallResponse(toMiddleware: self.payload.dictionaryPayload, isAvailable: true) { error in
                if (error != nil) {
                    self.rejectCall(uuid: uuid, description: "Unable to contact middleware")
                    return
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if (!APNSCallHandler.incomingCallConfirmed) {
                        self.rejectCall(uuid: uuid, description: "Unable to get call confirmation...")
                    }
                }
            }
        }
    }
    
    /**
        To reject a call we have to momentarily show the UI and then immediately report it as failed. The user will still see/hear
        the incoming call briefly.
     */
    private func rejectCall(uuid: UUID, reason: CXCallEndedReason = CXCallEndedReason.failed, description: String) {
        VialerLogError(description)
        self.callKit.reportCall(with: uuid, endedAt: nil, reason: reason)
    }
}
