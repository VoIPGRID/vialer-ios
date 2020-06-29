//
// Created by Jeremy Norman on 27/06/2020.
// Copyright (c) 2020 VoIPGRID. All rights reserved.
//

import Foundation
import PushKit

struct VoIPPushPayload {
    let phoneNumber: String
    let uuid: UUID
    let responseUrl: String
    let callerId: String?
    var callerName: String {
        get {
            callerId ?? phoneNumber
        }
    }
    let payload: PKPushPayload
}
