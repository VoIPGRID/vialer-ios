//
//  RecentCall.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import Foundation
import CoreData

/// Call instance object that represents a call in the call history of the client.
final class RecentCall: NSManagedObject {

    /// Date when the call took place.
    @NSManaged public fileprivate(set) var callDate: Date

    /// ID of the CNContact that has a number associated with this call.
    @NSManaged public fileprivate(set) var callerRecordID: String?

    /// Remote ID of the call.
    @NSManaged public fileprivate(set) var callID: Int64

    /// The number that received the call.
    @NSManaged public fileprivate(set) var destinationNumber: String?

    /// The number that was dialed.
    @NSManaged public fileprivate(set) var dialedNumber: String?

    /// When incoming: The name/number of the caller, when outgoing, the name/number of the person being called.
    @NSManaged public fileprivate(set) var displayName: String?

    /// The duration of the call.
    @NSManaged public fileprivate(set) var duration: Int16

    /// The direction of the call.
    @NSManaged public fileprivate(set) var inbound: Bool

    /// The phone number type fetched from the contact store.
    @NSManaged public fileprivate(set) var phoneType: String?

    /// The number where the call originated from.
    @NSManaged public fileprivate(set) var sourceNumber: String?


    /// Create or find a RecentCall based on the given dictionary in the context.
    ///
    /// - Parameters:
    ///   - dictionary: Dictionary with call data.
    ///   - context: The context where the call should be created in.
    /// - Returns: RecentCall instance.
    static func findOrCreate(for dictionary: JSONDictionary, in context: NSManagedObjectContext) -> RecentCall? {
        guard let sourceNumber = dictionary["src_number"] as? String,
            let callerID = dictionary["callerid"] as? String,
            let callDate = dictionary["call_date"] as? String,
            let direction = dictionary["direction"] as? String,
            let destinationNumber = dictionary["dst_number"] as? String,
            let dialedNumber = dictionary["dialed_number"] as? String,
            let duration = dictionary["atime"] as? Int16,
            let id = dictionary["id"] as? Int64
            else {
                return nil
            }

        // Check if there is already a call in Core Data given the id.
        let predicate = RecentCall.predicate(format: "%K == %lld", #keyPath(callID), id)
        return findOrCreate(in: context, matching: predicate) { call in

            // Populate the call.
            if let callDateFromString = callDate.date {
                call.callDate = callDateFromString
            }
            call.callID = id
            call.destinationNumber = destinationNumber
            call.dialedNumber = dialedNumber
            call.duration = duration
            call.inbound = direction == "inbound"
            call.sourceNumber = sourceNumber

            // Check if the phone number is in the addressbook and extract contact information.
            let phoneNumberToSearch = call.inbound ? sourceNumber : destinationNumber
            let digits = PhoneNumberUtils.removePrefix(fromPhoneNumber: phoneNumberToSearch)
            if let phoneNumber = ContactModel.defaultModel.phoneNumbersToContacts[digits] {
                call.displayName = phoneNumber.callerName
                call.callerRecordID = phoneNumber.contactIdentifier
                call.phoneType = phoneNumber.type
            } else if call.suppressed {
                call.displayName = NSLocalizedString("No Caller ID", comment: "No Caller ID")
            }
            
            if call.displayName == nil || call.displayName == "" {
                if let name = callerID.firstMatch(for: "\"(.*?)\""), name != ""  {
                    call.displayName = name
                } else {
                    call.displayName = phoneNumberToSearch
                }
            }
        }
    }
}

// MARK: Calculated properties
extension RecentCall {

    /// Is the call anonymous?
    var suppressed: Bool {
        get {
            if inbound {
                return sourceNumber!.range(of: "x") != nil
            }
            return false
        }
    }
}

// MARK: - Managed
extension RecentCall: Managed {
    public static var entityName: String {
        return "RecentCall"
    }

    /// Sort on callDate by default.
    public static var defaultSortDescriptors: [NSSortDescriptor] {
        return [NSSortDescriptor(key: "callDate", ascending: false)]
    }
}

// MARK: - Resource
extension RecentCall {

    /// Fetch all calls.
    static let allCalls = Resource<[JSONDictionary]>(path: "/cdr/record/", parameters: ["limit": 50], parseJSON: { json in
        guard let dictionaries = json["objects"] as? [JSONDictionary] else { return nil }
        return dictionaries
    })
    
    // Fetch personal calls.
    static let myCalls = Resource<[JSONDictionary]>(path: "/cdr/record/personalized/", parameters: ["limit": 50], parseJSON: { json in
        guard let dictionaries = json["objects"] as? [JSONDictionary] else { return nil }
        return dictionaries
    })
    

    /// Fetch all calls since a given date.
    ///
    /// - Parameter date: call need to be newer than this date.
    /// - Returns: RecentCall Resource.
    static func allCallsSince(date: Date) -> Resource<[JSONDictionary]> {
        var resource = RecentCall.allCalls
        resource.add(parameters: ["call_date__gte": date.apiFormatted24hCET])
        return resource
    }
    
    /// Fetch my calls since a given date.
    ///
    /// - Parameter date: call need to be newer than this date.
    /// - Returns: RecentCall Resource.
    static func myCallsSince(date: Date) -> Resource<[JSONDictionary]> {
        var resource = RecentCall.myCalls
        resource.add(parameters: ["call_date__gte": date.apiFormatted24hCET])
        return resource
    }
}

extension RecentCall {

    /// Get the newest RecentCall from Core Data.
    ///
    /// - Parameter managedContext: context where to search in.
    /// - Returns: optional Call instance.
    static func fetchLatest(in managedContext: NSManagedObjectContext) -> RecentCall? {
        let request = sortedFetchRequest
        request.fetchLimit = 1
        request.returnsObjectsAsFaults = false
        var call: RecentCall?
        managedContext.performAndWait {
            if let result = ((try? managedContext.fetch(request).first) as RecentCall??) {
                call = result
            }
        }
        return call
    }
}
