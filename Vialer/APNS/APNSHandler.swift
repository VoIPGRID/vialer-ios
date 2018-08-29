//
//  APNSHandler.swift
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

import Foundation
import PushKit

@objc class APNSHandler: NSObject, PKPushRegistryDelegate {
    @objc static let shared = APNSHandler()

    let middleware: Middleware
    let voipRegistry: PKPushRegistry

    private override init() {
        middleware = Middleware()
        voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
    }

    func registerForVoIPNotifications() {
        if voipRegistry.delegate == nil {
            VialerLogVerbose("Initiating VoIP push registration")
            voipRegistry.delegate = self

            voipRegistry.desiredPushTypes = [PKPushType.voIP]
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        VialerLogWarning("APNS VoIP token became invalid")
    }

    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        let token: String = tokenDataToString(token: pushCredentials.token)

        VialerLogInfo("Type: \(type.rawValue). APNS registration successful. Token: \(token)")

        middleware.sentAPNSToken(token)
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        VialerLogInfo("Incoming push notification of type: \(type.rawValue)")
        middleware.handleReceivedAPSNPayload(payload.dictionaryPayload)
    }

    @objc func storedAPNSToken() -> String {
        let token = voipRegistry.pushToken(for: PKPushType.voIP)
        return tokenDataToString(token: token!)
    }

    fileprivate func tokenDataToString(token: Data) -> String {
        return token.map { String(format: "%02.2hhx", $0) }.joined()
    }
}
