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
    var voipRegistry: PKPushRegistry
    
    var middleware: Middleware
    
    let tokenData: NSData = NSData()

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        <#code#>
    }


}
