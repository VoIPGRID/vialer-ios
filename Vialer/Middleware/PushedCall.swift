//
//  PushedCall.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import Foundation
import CoreData

final class PushedCall: NSManagedObject {
    @NSManaged public fileprivate(set) var accepted: Bool
    @NSManaged public fileprivate(set) var callDate: Date
    @NSManaged public fileprivate(set) var displayName: String?
    @NSManaged public fileprivate(set) var connectionType: String
    @NSManaged public fileprivate(set) var sourceNumber: String
    @NSManaged public fileprivate(set) var uniqueKey: String
}

extension PushedCall {
    static func findOrCreate(for dictionary: JSONDictionary, accepted: Bool, connectionType: String, in context: NSManagedObjectContext) -> PushedCall? {
        guard let key = dictionary["unique_key"] as? String,
            let number = dictionary["phonenumber"] as? String,
            let name = dictionary["caller_id"] as? String
            else {
                return nil
        }

        let predicate = PushedCall.predicate(format: "%K == %@", #keyPath(uniqueKey), key)
        return findOrCreate(in: context, matching: predicate) { call in
            call.accepted = accepted
            call.callDate = Date()
            call.displayName = name
            call.connectionType = connectionType
            call.sourceNumber = number
            call.uniqueKey = key
        }
    }
}

extension PushedCall: Managed {
    public static var entityName: String {
        return "PushedCall"
    }

    /// Sort on callDate by default.
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "callDate", ascending: false)]
    }
}
