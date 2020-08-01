//
// Created by Jeremy Norman on 27/07/2020.
// Copyright (c) 2020 VoIPGRID. All rights reserved.
//

import Foundation
import PhoneLib
import CallKit

class Sip: RegistrationStateDelegate {

    lazy var phone: PhoneLib = PhoneLib.shared
    lazy var user = SystemUser.current()
    @objc var callKitProviderDelegate: VialerCallKitDelegate!

    var call: Call?

    var hasActiveCall: Bool {
        get {
            self.call != nil
        }
    }

    init() {
        callKitProviderDelegate = VialerCallKitDelegate(sip: self)
        PhoneLib.shared.sessionDelegate = self
        PhoneLib.shared.setAudioCodecs([Codec.OPUS])
    }

    /**
        Register with the currently logged in user.
    */
    func register() -> Bool {
        PhoneLib.shared.registrationDelegate = self

        guard let username = user?.sipAccount,
              let password = user?.sipPassword else {
            return false
        }

        let domain = "sipproxy.voipgrid.nl", port = "5060"

        VialerLogInfo("Registering with \(username) + \(password) at \(domain):\(port)")

        let success = phone.register(domain: domain, port: port, username: username, password: password)

        if !success {
            VialerLogError("Failed to register")
            return false
        }

        return true
    }

    func unregister() {
        phone.unregister {
            VialerLogInfo("Unregistered...")
        }
    }

    func call(number: String) {
        let success = phone.call(to: number)

        if success {
            VialerLogInfo("Call to \(number) setup")
        } else {
            VialerLogError("Unable to setup call to \(number)")
        }
    }

    func findCallByUuid(uuid: UUID) -> Call? {
        if call?.uuid == uuid {
            return call
        }

        return nil
    }

    func didChangeRegisterState(_ state: SipRegistrationStatus, message: String?) {
        VialerLogDebug("Reg state: \(String(reflecting: state)) with message \(message)")
    }
}

// MARK: - SessionDelegate
extension Sip: SessionDelegate {

    public func didReceive(incomingSession: Session) {
        VialerLogDebug("Incoming session didReceive")

        VoIPPushHandler.incomingCallConfirmed = true

        DispatchQueue.main.async {
            VialerLogInfo("Incoming call block invoked, routing through CallKit.")
            self.call = Call(session: incomingSession, direction: Direction.inbound)
            self.callKitProviderDelegate.reportIncomingCall()
        }
    }

    public func outgoingDidInitialize(session: Session) {
        VialerLogDebug("outgoingDidInitialize")

        self.call = Call(session: session, direction: Direction.outbound)

        guard let call = self.call else {
            VialerLogError("Unable to find call setup...")
            return
        }

        let controller = CXCallController()
        let handle = CXHandle(type: .phoneNumber, value: call.session.remoteNumber)
        let startCallAction = CXStartCallAction(call: call.uuid, handle: handle)

        let transaction = CXTransaction(action: startCallAction)
        controller.request(transaction) { error in
            if error != nil {
                VialerLogError("ERRROR")
            } else {
                VialerLogInfo("SEtup!")
            }
        }
    }

    public func sessionUpdated(_ session: Session, message: String) {
        VialerLogDebug("sessionUpdated: \(message)")
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "call-update"), object: nil)
    }

    public func sessionConnected(_ session: Session) {
        VialerLogDebug("sessionConnected")
    }

    public func sessionEnded(_ session: Session) {
        if self.call == nil {
            VialerLogError("No call...")
            return
        }

        VialerLogInfo("Ending call with uuid \(call!.uuid)")
        callKitProviderDelegate.provider.reportCall(with: call!.uuid, endedAt: Date(), reason: CXCallEndedReason.remoteEnded)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "call-update"), object: nil)
        self.call = nil
    }

    public func sessionReleased(_ session: Session) {
        VialerLogInfo("Session released..")
        if let call = self.call {
            if call.session.state == .released {
                self.call = nil
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "call-update"), object: nil)
    }

    public func error(session: Session, message: String) {
        VialerLogDebug("Error: \(message)")
    }
}