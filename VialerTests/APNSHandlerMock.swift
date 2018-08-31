//
//  APNSHandlerMock.swift
//  VialerTests
//
//  Created by Redmer Loen on 8/31/18.
//  Copyright © 2018 VoIPGRID. All rights reserved.
//

import Foundation
import PushKit
@testable import Vialer


class APNSHandlerMock: APNSHandlerProtocol {
    static let shared = APNSHandlerMock()

    let tokenData: NSData = NSData()
    let registerForPushType: PKPushType = PKPushType.voIP

    func registerForVoIPNotifications() {

    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        <#code#>
    }

    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {

    }

}
