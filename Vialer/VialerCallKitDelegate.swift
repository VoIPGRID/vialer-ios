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

class VialerCallKitDelegate: NSObject {

    private let callManager: VSLCallManager
    public let provider: CXProvider
    private let notifications = NotificationCenter.default

    init(callManager: VSLCallManager) {
        self.callManager = callManager
        self.provider = CXProvider(configuration: VialerCallKitDelegate.self.createConfiguration())
        super.init()
        self.provider.setDelegate(self, queue: nil)
        NotificationCenter.default.addObserver(self,
                selector: #selector(callStateChanged(_:)),
                name: NSNotification.Name.VSLCallStateChanged,
                object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private static func createConfiguration() -> CXProviderConfiguration {
        let providerConfiguration = CXProviderConfiguration(
                localizedName: Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
        )

        providerConfiguration.maximumCallGroups = 2
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportsVideo = false

        if !SystemUser.current().usePhoneRingtone {
            if let ringtoneFileName = Bundle.main.path(forResource: "ringtone", ofType: "wav") {
                providerConfiguration.ringtoneSound = "ringtone.wav"
            }
        }

        providerConfiguration.supportedHandleTypes = [CXHandle.HandleType.phoneNumber]
        return providerConfiguration
    }

    @objc fileprivate func callStateChanged(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let call     = userInfo[VSLNotificationUserInfoCallKey] as? VSLCall else {
            return;
        }

        switch (call.callState) {
        case .calling:
            if (!call.isIncoming) {
                VialerLogDebug("Outgoing call, in CALLING state, with UUID \(call.uuid)")
                self.provider.reportOutgoingCall(with: call.uuid, connectedAt: Date())
            }
        case .early:
            if (!call.isIncoming) {
                VialerLogDebug("Outgoing call, in EARLY state, with UUID: \(call.uuid)")
                self.provider.reportOutgoingCall(with: call.uuid, startedConnectingAt: Date())
            }
        case .connecting:
            if (!call.isIncoming) {
                VialerLogDebug("Outgoing call, in CONNECTING state, with UUID: \(call.uuid)")
                self.provider.reportOutgoingCall(with: call.uuid, startedConnectingAt: Date())
            }
        case .confirmed:
            if (!call.isIncoming) {
                VialerLogDebug("Outgoing call, in CONFIRMED state, with UUID: \(call.uuid)")
                self.provider.reportOutgoingCall(with: call.uuid, startedConnectingAt: Date())
            }
        case .disconnected:
            if (!call.connected) {
                VialerLogDebug("Call never connected, in DISCONNECTED state, with UUID: \(call.uuid)")
                self.provider.reportOutgoingCall(with: call.uuid, connectedAt: Date())
                self.provider.reportCall(with: call.uuid, endedAt: Date(), reason: CXCallEndedReason.unanswered)
            } else if (!call.userDidHangUp) {
                VialerLogDebug("Call remotly ended, in DISCONNECTED state, with UUID: \(call.uuid)")
                self.provider.reportCall(with: call.uuid, endedAt: Date(), reason: CXCallEndedReason.remoteEnded)
            }
        case .null:
            break
        case .incoming:
            break
        @unknown default:
            VialerLogDebug("Default call state")
        }
    }

    func reportIncomingCall(call: VSLCall) {
        let update = CXCallUpdate()
        update.localizedCallerName = call.callerName

        var handleValue = update.localizedCallerName!

        if (handleValue.isEmpty) {
            handleValue = call.callerNumber!
        }

        let handle = CXHandle(
                type: CXHandle.HandleType.phoneNumber,
                value: handleValue
        )

        VialerLogInfo("Updating CallKit provider with UUID: \(call.uuid.uuidString)")
        provider.reportCall(with: call.uuid, updated: update)
    }

}

extension VialerCallKitDelegate: CXProviderDelegate {

    func providerDidReset(_ provider: CXProvider) {
        VialerLogDebug("Provider reset, end all the calls")
        callManager.endAllCalls()
    }

    public func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        guard let call = findCallOrFail(action: action) else { return }


        if (!waitForCallConfirmation(call: call)) {
            VialerLogError("Unable to confirm call: \(call.uuid.uuidString)")
            action.fail()
            return
        }

        callManager.audioController.configureAudioSession()

        call.answer { error in

            if (error != nil) {
                self.logError(error: error, call: call)
                return
            }

            VialerLogInfo("Answering call \(call.uuid.uuidString)")

            NotificationCenter.default.post(
                    name: NSNotification.Name.CallKitProviderDelegateInboundCallAccepted,
                    object: self,
                    userInfo: [VSLNotificationUserInfoCallKey : call]
            )

            action.fulfill()
        }

    }

    public func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        guard let call = findCallOrFail(action: action) else {
            action.fulfill()
            return
        }

        do {
            if call.isIncoming && call.callState != VSLCallState.confirmed {
                if (!waitForCallConfirmation(call: call)) {
                    VialerLogError("Unable to confirm call: \(call.uuid.uuidString)")
                    action.fulfill()
                    return
                }

                try call.decline()

                notifications.post(name: Notification.Name.teardownSip, object: self)
            } else {
                try call.hangup()
            }

            action.fulfill()

        } catch {
            VialerLogError("Failed to decline call \(error.localizedDescription)")
            action.fail()
        }
    }

    public func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        callManager.audioController.configureAudioSession()

        guard let call = findCall(action: action) else { return }

        call.start { error in
            if (error != nil) {
                self.logError(error: error, call: call)
                action.fail()
                return
            }

            VialerLogInfo("Call started: \(call.uuid.uuidString)")

            self.sendCallNotification(name: NSNotification.Name.CallKitProviderDelegateOutboundCallStarted, call: call)

            action.fulfill()
        }
    }

    public func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        guard let call = findCallOrFail(action: action) else { return }

        do {
            try call.toggleMute()
            action.fulfill()
        } catch {
            logError(error: error, call: call)
            action.fail()
        }
    }

    public func provider(_ provider: CXProvider, perform action: CXSetHeldCallAction) {
        guard let call = findCallOrFail(action: action) else { return }

        do {
            try call.toggleHold()

            if (call.onHold) {
                callManager.audioController.deactivateAudioSession()
            } else {
                callManager.audioController.activateAudioSession()
            }

            action.fulfill()
        } catch {
            logError(error: error, call: call)
            action.fail()
        }
    }

    public func provider(_ provider: CXProvider, perform action: CXPlayDTMFCallAction) {
        guard let call = findCallOrFail(action: action) else { return }

        do {
            try call.sendDTMF(action.digits)
            action.fulfill()
        } catch {
            logError(error: error, call: call)
            action.fail()
        }
    }

    public func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        callManager.audioController.activateAudioSession()
    }

    public func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        callManager.audioController.deactivateAudioSession()
        notifications.post(name: Notification.Name.teardownSip, object: self)
    }
}

extension VialerCallKitDelegate {

    private func sendCallNotification(name: NSNotification.Name, call: VSLCall) {
        self.notifications.post(
                name: name,
                object: self,
                userInfo: [VSLNotificationUserInfoCallKey : call]
        )
    }

    /**
        Attempts to find the call, if is not find, will automatically fail the action.
    */
    private func findCall(action: CXCallAction) -> VSLCall? {
        VialerLogInfo("Attempting to perform \(String(describing: type(of: action))).")

        guard let call = callManager.call(with: action.callUUID) else {
            VialerLogError("Unable to find call.")
            return nil
        }

        return call
    }

    /**
        Attempts to find the call, if is not find, will automatically fail the action.
    */
    private func findCallOrFail(action: CXCallAction) -> VSLCall? {
        guard let call = findCall(action: action) else {
            VialerLogError("Failed to executed action \(String(describing: type(of: action))), call not found.")
            action.fail()
            return nil
        }

        return call
    }

    private func logError(error: Error?, call: VSLCall) {
        VialerLogError("Unable to perform action on call (\(call.uuid.uuidString)), error: \(error!.localizedDescription)")
    }

    private func waitForCallConfirmation(call: VSLCall) -> Bool {
        if !call.isIncoming {
            return true
        }

        if isCallConfirmed() {
            return true
        }

        VialerLogInfo("Awaiting the incoming call to be confirmed")

        VoipTaskSynchronizer.wait(timeoutInMilliseconds: 5000) { isCallConfirmed() }

        VialerLogInfo("Finished waiting with result: \(isCallConfirmed())")

        return isCallConfirmed()
    }

    private func isCallConfirmed() -> Bool {
        APNSCallHandler.incomingCallConfirmed
    }
}

extension Notification.Name {
    static let teardownSip = Notification.Name("destroy-sip")
}
