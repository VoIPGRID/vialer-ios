//
// Created by Jeremy Norman on 27/07/2020.
// Copyright (c) 2020 VoIPGRID. All rights reserved.
//

import Foundation
import PhoneLib
import CallKit

@objc class Sip: NSObject, RegistrationStateDelegate  {

    @objc static public let shared = Sip()

    private var onRegister: ((Error?) -> ())?
    private var onIncomingCall: ((Call) -> ())?
    private var incomingUuid: UUID?
    lazy var phone: PhoneLib = PhoneLib.shared
    lazy var user = SystemUser.current()
    @objc var callKitProviderDelegate: VialerCallKitDelegate!

    var call: Call?
    var firstTransferCall: Call?
    var secondTransferCall: Call?

    @objc var hasActiveCall: Bool {
        get {
            self.call != nil
        }
    }

    override init() {
        super.init()
        callKitProviderDelegate = VialerCallKitDelegate(sip: self)
        phone.sessionDelegate = self
        phone.setAudioCodecs([Codec.OPUS])
    }

    /**
        Register with the currently logged in user.
    */
    func register(onRegister: ((Error?) -> ())? = nil) {
        PhoneLib.shared.registrationDelegate = self

        if phone.registrationStatus == .registered {
            onRegister?(nil)
            return
        }

        guard let username = user?.sipAccount,
              let password = user?.sipPassword else {
            return
        }

        self.onRegister = onRegister

        let port = 5060,
            user = SystemUser.current()!,
            domain = (user.useTLS ? "sip.encryptedsip.com" : "sipproxy.voipgrid.nl")
        
        VialerLogInfo("Registering with \(username) + \(password) encrypted:\(user.useTLS) at \(domain):\(port)")
        let success = phone.register(domain: domain, port: port, username: username, password: password, encrypted: user.useTLS)

        if !success {
            VialerLogError("Failed to register.")
        }
    }

    func unregister() {
        phone.unregister {
            VialerLogInfo("Unregistered.")
        }
    }

    @objc func call(number: String) -> Session? {
        var session : Session?
        register { error in
            if error != nil {
                VialerLogError("Unable to register.")
                return
            }

            VialerLogInfo("Attempting to call.")
            session = self.phone.call(to: number)
        }
        return session
    }
    
    func endCall(for session: Session) -> Bool {
        return phone.endCall(for: session)
    }

    func acceptIncomingCall(callback: @escaping () -> ()) {
        self.onIncomingCall = { call in
            _ = self.phone.acceptCall(for: call.session)
            callback()
        }

        if let call = self.call {
            VialerLogInfo("We have found the call already and can accept it.")
            self.onIncomingCall?(call)
            self.onIncomingCall = nil
            return
        }

        VialerLogInfo("We have no call yet, so we will queue to accept as soon as possible.")
    }

    func findCallByUuid(uuid: UUID) -> Call? {
        if call?.uuid == uuid {
            return call
        }

        return nil
    }

    func didChangeRegisterState(_ state: SipRegistrationStatus, message: String?) {
        VialerLogDebug("Reg state: \(String(reflecting: state)) with message \(String(describing: message))")

        if state == .registered {
            onRegister?(nil)
            onRegister = nil
        }

        if state == .failed {
            onRegister?(RegistrationError.failed)
            onRegister = nil
            if let uuid = incomingUuid {
                callKitProviderDelegate.provider.reportCall(with: uuid, endedAt: Date(), reason: CXCallEndedReason.failed)
            }
        }
    }

    func prepareForIncomingCall(uuid: UUID) {
        self.incomingUuid = uuid
    }
    
    func beginAttendedTransfer(session: Session, to number:String) -> AttendedTransferSession? {
        firstTransferCall = call
        return phone.beginAttendedTransfer(session: session, to: number)
    }
    
    func finishAttendedTransfer(attendedTransferSession: AttendedTransferSession) -> Bool {
        firstTransferCall = nil
        return phone.finishAttendedTransfer(attendedTransferSession: attendedTransferSession)
    }
}

// MARK: - SessionDelegate
extension Sip: SessionDelegate {

    public func didReceive(incomingSession: Session) {
        VialerLogDebug("Incoming session didReceive")

        guard let uuid = self.incomingUuid else {
            VialerLogError("No incoming uuid set, cannot accept incoming call")
            return
        }

        self.incomingUuid = nil

        VoIPPushHandler.incomingCallConfirmed = true

        DispatchQueue.main.async {
            VialerLogInfo("Incoming call block invoked, routing through CallKit.")
            self.call = Call(session: incomingSession, direction: Direction.inbound, uuid: uuid)
            self.callKitProviderDelegate.reportIncomingCall()
            self.onIncomingCall?(self.call!)
            self.onIncomingCall = nil
        }
    }

    public func outgoingDidInitialize(session: Session) {
        VialerLogDebug("On outgoingDidInitialize.")

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
                VialerLogError("Error on outgoing call.")
            } else {
                VialerLogInfo("Setup of outgoing call.")
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
            VialerLogDebug("Session ended with nil call object.")
            return
        }
        
        //WIP
//        if self.call?.simpleState != .finished {
//            VialerLogDebug("Session ended but state is not finished.")
//            return
//        }
            
        VialerLogInfo("Ending call with sessionId:\(call!.session.sessionId) because session ended with uuid:\(session.sessionId)")
        callKitProviderDelegate.provider.reportCall(with: call!.uuid, endedAt: Date(), reason: CXCallEndedReason.remoteEnded)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "call-update"), object: nil)
        self.call = nil
    }

    public func sessionReleased(_ session: Session) {
        VialerLogInfo("Session released..")
        
        // In case of transfer's second call was cancelled or declined. //WIP
        if firstTransferCall != nil && firstTransferCall?.session.sessionId != session.sessionId {
            VialerLogInfo("Transfer's second call was cancelled or declined.")
            self.call = firstTransferCall
            //firstTransferCall = nil
        }
        
        if let call = self.call {
            if call.session.state == .released {
                VialerLogInfo("Setting call with UUID: \(call.uuid) to nil because session has been released.")
                self.call = nil
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "call-update"), object: nil)
    }

    public func error(session: Session, message: String) {
        VialerLogDebug("Error: \(message) for call with sessionUUID: \(session.sessionId)")
    }
}

enum RegistrationError: Error {
    case failed
}
