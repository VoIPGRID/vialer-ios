//
//  VialerCallKitDelegate.swift
//  Vialer
//
//  Created by Jeremy Norman on 06/06/2020.
//  Copyright © 2020 VoIPGRID. All rights reserved.
//

import Foundation
import CallKit
import UserNotifications
import AVKit
import PhoneLib

class VialerCallKitDelegate: NSObject {

    public let provider: CXProvider
    private let notifications = NotificationCenter.default
    private let sip: Sip

    init(sip: Sip) {
        self.sip = sip
        self.provider = CXProvider(configuration: VialerCallKitDelegate.self.createConfiguration())
        super.init()
        self.provider.setDelegate(self, queue: nil)
    }

    func refresh() {
        self.provider.configuration = VialerCallKitDelegate.self.createConfiguration()
    }

    private static func createConfiguration() -> CXProviderConfiguration {
        let providerConfiguration = CXProviderConfiguration(
                localizedName: Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        )

        providerConfiguration.maximumCallGroups = 2
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportsVideo = false
        providerConfiguration.supportedHandleTypes = [CXHandle.HandleType.phoneNumber]

        if !SystemUser.current().usePhoneRingtone {
            if Bundle.main.path(forResource: "ringtone", ofType: "wav") != nil {
                providerConfiguration.ringtoneSound = "ringtone.wav"
            }
        }

        return providerConfiguration
    }

//    @objc fileprivate func callStateChanged(_ notification: NSNotification) {
//        guard let userInfo = notification.userInfo,
//              let call     = userInfo[VSLNotificationUserInfoCallKey] as? VSLCall else {
//            return;
//        }
//
//        switch (call.callState) {
//        case .calling:
//            if (!call.isIncoming) {
//                VialerLogDebug("Outgoing call, in CALLING state, with UUID \(call.uuid)")
//                self.provider.reportOutgoingCall(with: call.uuid, connectedAt: Date())
//            }
//        case .early:
//            if (!call.isIncoming) {
//                VialerLogDebug("Outgoing call, in EARLY state, with UUID: \(call.uuid)")
//                self.provider.reportOutgoingCall(with: call.uuid, startedConnectingAt: Date())
//            }
//        case .connecting:
//            if (!call.isIncoming) {
//                VialerLogDebug("Outgoing call, in CONNECTING state, with UUID: \(call.uuid)")
//                self.provider.reportOutgoingCall(with: call.uuid, startedConnectingAt: Date())
//            }
//        case .confirmed:
//            if (!call.isIncoming) {
//                VialerLogDebug("Outgoing call, in CONFIRMED state, with UUID: \(call.uuid)")
//                self.provider.reportOutgoingCall(with: call.uuid, startedConnectingAt: Date())
//            }
//        case .disconnected:
//            if (!call.connected) {
//                VialerLogDebug("Call never connected, in DISCONNECTED state, with UUID: \(call.uuid)")
//                self.provider.reportOutgoingCall(with: call.uuid, connectedAt: Date())
//                self.provider.reportCall(with: call.uuid, endedAt: Date(), reason: CXCallEndedReason.unanswered)
//            } else if (!call.userDidHangUp) {
//                VialerLogDebug("Call remotly ended, in DISCONNECTED state, with UUID: \(call.uuid)")
//                self.provider.reportCall(with: call.uuid, endedAt: Date(), reason: CXCallEndedReason.remoteEnded)
//            }
//        case .null:
//            break
//        case .incoming:
//            break
//        @unknown default:
//            VialerLogDebug("Default call state")
//        }
//    }

    func reportIncomingCall() {
        guard let call = sip.call else {
            VialerLogError("Reported incoming call with no active session")
            return
        }

        let update = CXCallUpdate()
        update.localizedCallerName = call.displayName

        _ = CXHandle(
                type: CXHandle.HandleType.phoneNumber,
                value: call.displayName ?? call.remoteNumber
        )
        VialerLogInfo("Reporting call with uuid \(call.uuid)")
        provider.reportCall(with: call.uuid, updated: update)
    }

}

extension VialerCallKitDelegate: CXProviderDelegate {

    func providerDidReset(_ provider: CXProvider) {
        VialerLogDebug("Provider reset, end all the calls")
    }

    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        Sip.shared.acceptIncomingCall {
            action.fulfill()
        }
    }

    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        guard let call = findCallOrFail(action: action) else {
            action.fulfill()
            return
        }
        
        VialerLogInfo("Call is ending with average rating: \(call.session.getAverageRating())/5.")
        let success = PhoneLib.shared.endCall(for: call.session)

        if success {
            action.fulfill(withDateEnded: Date())
        } else {
            action.fail()
        }
    }

    public func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
//        guard let call = findCall(action: action) else { return }

        action.fulfill()
    }

    public func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        guard let call = findCallOrFail(action: action) else { return }

        PhoneLib.shared.setMicrophone(muted: action.isMuted)

        action.fulfill()
    }

    public func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        guard let call = findCallOrFail(action: action) else { return }

        let success = PhoneLib.shared.setHold(session: call.session, onHold: action.isOnHold)

        if success {
            action.fulfill()
        } else {
            action.fail()
        }
    }

    public func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
//        guard let call = findCallOrFail(action: action) else { return }

        VialerLogError("DTMF's sound is not supported yet") //wip
        action.fail()
    }

    public func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        PhoneLib.shared.setAudio(enabled: true)
    }

    public func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        PhoneLib.shared.setAudio(enabled: false)
    }
}

extension VialerCallKitDelegate {

    /**
        Attempts to find the call, if is not find, will automatically fail the action.
    */
    private func findCall(action: CXCallAction) -> Call? {
        VialerLogInfo("Attempting to perform \(String(describing: type(of: action))).")

        guard let call = sip.findCallByUuid(uuid: action.callUUID) else {
            return nil
        }

        return call
    }

    /**
        Attempts to find the call, if is not find, will automatically fail the action.
    */
    private func findCallOrFail(action: CXCallAction) -> Call? {
        guard let call = findCall(action: action) else {
            VialerLogError("Failed to execute action \(String(describing: type(of: action))), call not found.")
            action.fail()
            return nil
        }

        return call
    }

    private func logError(error: Error?, call: Call) {
        VialerLogError("Unable to perform action on call (\(call.uuid.uuidString)), error: \(error!.localizedDescription)")
    }

    private func waitForCallConfirmation(call: Call) -> Bool {
        if call.direction == Direction.outbound {
            return true
        }

        if isCallConfirmed() {
            return true
        }

        VialerLogInfo("Awaiting the incoming call to be confirmed")

        VialerCallKitDelegate.wait(timeoutInMilliseconds: 5000) { isCallConfirmed() }

        VialerLogInfo("Finished waiting with result: \(isCallConfirmed())")

        return isCallConfirmed()
    }

    private func isCallConfirmed() -> Bool {
        return VoIPPushHandler.incomingCallConfirmed
    }
}

extension Notification.Name {
    static let teardownSip = Notification.Name("destroy-sip")
}

extension VialerCallKitDelegate {

    /**
        Wait for a given condition or until a certain timeout has been reached.
    */
    public static func wait(timeoutInMilliseconds: Int = 10000, until: () -> Bool) -> Bool {
        let TIMEOUT_MILLISECONDS = timeoutInMilliseconds
        let MILLISECONDS_BETWEEN_ITERATION = 5
        var millisecondsTrying = 0

        while (!until() && millisecondsTrying < TIMEOUT_MILLISECONDS) {
            millisecondsTrying += MILLISECONDS_BETWEEN_ITERATION
            usleep(useconds_t(MILLISECONDS_BETWEEN_ITERATION * 1000))
        }

        return until()
    }
}
