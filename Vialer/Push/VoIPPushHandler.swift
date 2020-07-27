//
// Created by Jeremy Norman on 27/06/2020.
// Copyright (c) 2020 VoIPGRID. All rights reserved.
//

import Foundation
import PushKit
import PhoneLib

class VoIPPushHandler: SessionDelegate {

    private let middleware = Middleware()
    private let voIPPushPayloadTransformer = VoIPPushPayloadTransformer()
    private let vsl = VialerSIPLib.sharedInstance()
    private let sip = SIPUtils.self

    private lazy var callKit: CXProvider = {
        (UIApplication.shared.delegate as! AppDelegate).callKitProviderDelegate.provider
    }()

    // This will be updated and set to TRUE when we have confirmation that we have received a call via SIP.
    // If we do not get this confirmation we can assume the call has failed and cancel the ringing.
    // However, it must always be set to false when a new call is coming in.
    static var incomingCallConfirmed = false


    func handle(payload: PKPushPayload, completion: @escaping () -> ()) {
        VoIPPushHandler.self.incomingCallConfirmed = false

        PhoneLib.shared.sessionDelegate = self
        guard let payload = voIPPushPayloadTransformer.transform(payload: payload) else {
            VialerLogError("Unable to properly extract call information from payload. Not handling call.")
            return
        }

        callKit.reportNewIncomingCall(with: payload.uuid, update: createCxCallUpdate(from: payload)) { error in
            if (error != nil) {
                VialerLogError("Failed to create incoming call: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            self.createLocalCallObject(from: payload)

            completion()
        }

        establishConnection(for: payload)
    }

    /**
        Process an incoming VoIP notification, launching the Call UI and connecting to the back-end.
     */
    func createLocalCallObject(from payload: VoIPPushPayload) {
        let uuid = payload.uuid,
                phoneNumber = payload.phoneNumber,
                callerId = payload.callerId

        if self.vsl.hasActiveCall() {
            respond(with: payload, available: false)
            self.rejectCall(uuid: uuid, description: "Rejecting call as there is already one in progress")
            return
        }

        guard let call = VSLCall(inboundCallWith: uuid, number: phoneNumber, name: callerId ?? "") else {
            self.rejectCall(uuid: uuid, description: "Unable to create call with the uuid \(uuid.uuidString)")
            return
        }

        self.vsl.callManager.add(call)
    }

    /**
        Attempts to asynchronously create a VoIP connection, if this fails we must report the call as failed to hide
        the now ringing UI.
    */
    func establishConnection(for payload: VoIPPushPayload) {
        if vsl.hasActiveCall() {
            return
        }

        let uuid = payload.uuid

        sip.setupSIPEndpoint()

        sip.registerSIPAccountWithEndpoint { (success, account) in
            if (!success) {
                self.rejectCall(uuid: uuid, description: "Failed to register with SIP, rejecting the call...")
                return;
            }

            self.vsl.callManager.call(with: uuid)?.account = account

            self.respond(with: payload, available: true) { error in
                if (error != nil) {
                    self.rejectCall(uuid: uuid, description: "Unable to contact middleware")
                    return
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    if (!VoIPPushHandler.self.incomingCallConfirmed) {
                        self.rejectCall(uuid: uuid, description: "Unable to get call confirmation...")
                    }
                }
            }
        }
    }

    /**
        Respond to the middleware, this will determine if we receive the call or not.
    */
    private func respond(with payload: VoIPPushPayload, available: Bool, completion: ((Error?) -> ())? = nil) {
        if (completion == nil) {
            MiddlewareRequestOperationManager(baseURLasString: payload.responseUrl)!
                    .sentCallResponse(toMiddleware: payload.payload.dictionaryPayload, isAvailable: available)
        } else {
            MiddlewareRequestOperationManager(baseURLasString: payload.responseUrl)!
                    .sentCallResponse(toMiddleware: payload.payload.dictionaryPayload, isAvailable: available, withCompletion: completion)
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

    /**
        Creates the CXCallUpdate object with the relevant information from the payload.
    */
    private func createCxCallUpdate(from payload: VoIPPushPayload) -> CXCallUpdate {
        let callUpdate = CXCallUpdate()
        callUpdate.remoteHandle = CXHandle(type: .phoneNumber, value: payload.phoneNumber)
        callUpdate.localizedCallerName = payload.callerName
        return callUpdate
    }
}