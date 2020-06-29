//
// Created by Jeremy Norman on 27/06/2020.
// Copyright (c) 2020 VoIPGRID. All rights reserved.
//

import Foundation
import PushKit

class VoIPPushPayloadTransformer {

    /**
        Transforms the PushKit payload into a standard structure we can work with
        easily.
    */
    func transform(payload: PKPushPayload) -> VoIPPushPayload? {
        let dictionaryPayload = payload.dictionaryPayload

        if let phoneNumber = dictionaryPayload[PayloadLookup.phoneNumber] as? String,
           let uuid = NSUUID.uuidFixer(uuidString: dictionaryPayload[PayloadLookup.uniqueKey] as! String) as UUID?,
           let responseUrl = dictionaryPayload[PayloadLookup.responseUrl] as? String {

            return VoIPPushPayload(
                    phoneNumber: phoneNumber,
                    uuid: uuid,
                    responseUrl: responseUrl,
                    callerId: dictionaryPayload[PayloadLookup.callerId] as? String,
                    payload: payload
            )
        }

        return nil
    }

    private struct PayloadLookup {
        static let uniqueKey = "unique_key"
        static let phoneNumber = "phonenumber"
        static let responseUrl = "response_api"
        static let callerId = "caller_id"
    }
}
