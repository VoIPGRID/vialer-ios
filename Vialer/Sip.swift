//
// Created by Jeremy Norman on 27/07/2020.
// Copyright (c) 2020 VoIPGRID. All rights reserved.
//

import Foundation
import PhoneLib

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
        PhoneLib.shared.registrationDelegate = self
    }

    /**
        Register with the currently logged in user.
    */
    func register() -> Bool {
        guard let username = user?.username,
              let password = user?.password else {
            return false
        }

        let domain = "sip.encryptedsip.com", port = "5060"

        VialerLogInfo("Registering with \(username) + \(password) at \(domain):\(port)")

        let success = phone.register(domain: domain, port: port, username: username, password: password)

        if !success {
            VialerLogError("Failed to register")
            return false
        }

        return true
    }

    func call(number: String) {
        let success = register()

        if !success {
            return
        }

        guard let session = phone.call(to: number) else {
            VialerLogError("Did not get session")
            return
        }

        VialerLogInfo("Started session with \(session.remoteNumber) - \(session.displayName ?? "")")
    }

    func findCallByUuid(uuid: UUID) -> Call? {
        if call?.uuid == uuid {
            return call
        }

        return nil
    }

    public func didChangeRegisterState(_ state: SipRegistrationStatus) {
        VialerLogDebug("Reg state: \(state.rawValue)")
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
    }

    public func sessionUpdated(_ session: Session, message: String) {
        VialerLogDebug("sessionUpdated")
    }

    public func sessionConnected(_ session: Session) {
        VialerLogDebug("sessionConnected")
    }

    public func sessionEnded(_ session: Session) {
        VialerLogDebug("sessionEnded")
    }

    public func sessionReleased(_ session: Session) {
        VialerLogDebug("esessionReleased")
    }

    public func error(session: Session, message: String) {
        VialerLogDebug("Error session \(message)")
    }
}