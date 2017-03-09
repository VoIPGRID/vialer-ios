//
//  Call.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import Foundation

struct Call {
    let id: Int
    let originalCallerId: String
    let callerId: String
    let sourceNumber: String
    let callDate: Date
    let inbound: Bool
    let callerNumber: String
    let destinationNumber: String
    let dialedNumber: String
    let destinationCode: String
    let duration: Int
}

extension Call {
    /// Create a Call based on JSON from the API.
    init?(dictionary: JSONDictionary) {
        guard let originalCallerid = dictionary["orig_callerid"] as? String,
            let sourceNumber = dictionary["src_number"] as? String,
            let callerId = dictionary["callerid"] as? String,
            let callDate = dictionary["call_date"] as? String,
            let direction = dictionary["direction"] as? String,
            let callerNumber = dictionary["caller_num"] as? String,
            let destinationNumber = dictionary["dst_number"] as? String,
            let dialedNumber = dictionary["dialed_number"] as? String,
            let destinationCode = dictionary["dst_code"] as? String,
            let duration = dictionary["atime"] as? Int,
            let id = dictionary["id"] as? Int
            else {
                return nil
        }
        self.id = id
        self.originalCallerId = originalCallerid
        self.callerId = callerId
        self.sourceNumber = sourceNumber

        self.callDate = callDate.date!
        self.inbound = direction == "inbound"
        self.callerNumber = callerNumber
        self.destinationNumber = destinationNumber
        self.dialedNumber = dialedNumber
        self.destinationCode = destinationCode
        self.duration = duration
    }
}

// MARK: - Resources
extension Call {
    static let all = Resource<[Call]>(path: "/cdr/record/", parameters: ["limit": 50], parseJSON: { json in
        guard let dictionaries = json["objects"] as? [JSONDictionary] else { return nil }
        return dictionaries.flatMap(Call.init)
    })

    static func allSince(date: Date) -> Resource<[Call]> {
        var resource = Call.all
        resource.add(parameters: ["call_date__gte": date.apiFormatted24hCET])
        return resource
    }
}

// MARK: - Helper functions
extension Call: CustomStringConvertible {
    var description: String {
        return "Call: \(originalCallerId) at \(callDate) \(sourceNumber) -> \(destinationNumber) (\(duration))"
    }
}
