//
// Created by Jeremy Norman on 26/06/2020.
// Copyright (c) 2020 VoIPGRID. All rights reserved.
//

import Foundation
import PushKit

class PushRegistryDelegate: NSObject, PKPushRegistryDelegate {

    private let voipRegistry: PKPushRegistry = PKPushRegistry(queue: nil)
    private let middleware: Middleware = Middleware()
    private let callHandler = APNSCallHandler()
    private let callKit: CXProvider

    init(cxProvider: CXProvider) {
        callKit = cxProvider
        super.init()
    }

    func registerForVoIPPushes() {
        self.voipRegistry.delegate = self
        self.voipRegistry.desiredPushTypes = [PKPushType.voIP]
    }

    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        if let token = String(data: pushCredentials.token, encoding: String.Encoding.utf8) {
            VialerLogDebug("Sending token to server \(token)")
            middleware.sentAPNSToken(token)
        }
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> ()) {

    }
}