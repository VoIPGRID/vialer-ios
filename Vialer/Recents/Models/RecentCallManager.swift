//
//  RecentCallManager.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import Foundation
import CoreData


/// Manager that handles the fetching and storing of RecentCalls.
class RecentCallManager {

    /// Possible errors returned by the manager.
    ///
    /// - fetchFailed: Unable to fetch calls from remote (possbile network connection issue).
    /// - fetchNotAllowed: User is not allowed to fetch calls.
    enum RecentCallManagerError: Error {
        case fetchFailed
        case fetchNotAllowed
    }

    /// Is the manager reloading new calls.
    public var reloading = false

    /// Did the last fetch failed?
    public var recentsFetchFailed = false

    /// Why did the last fetch failed?
    public var recentsFetchErrorCode: RecentCallManagerError?

    /// Context that is used to fetch and store RecentCalls in.
    private let managedContext: NSManagedObjectContext

    private var webservice: WebserviceProtocol!

    /// Initializer
    ///
    /// - Parameter managedContext: Context that is used to fetch and store RecentCalls in.
    required init(managedContext: NSManagedObjectContext, webservice: WebserviceProtocol? = nil) {
        self.managedContext = managedContext
        self.webservice = webservice ?? Webservice(authentication: SystemUser.current())
    }

    /// Fetch the latest calls and store them in the context.
    ///
    /// - Parameter completion: Completionblock that is called when completed.
    public func getLatestRecentCalls(onlyMine: Bool = false, completion: @escaping (RecentCallManagerError?)->()) {
        var fetchDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        reloading = true

        var resource: Resource<[JSONDictionary]>
        if onlyMine {
            resource = RecentCall.myCallsSince(date: fetchDate)
        } else {
            resource = RecentCall.allCallsSince(date: fetchDate)
        }

        // Fetch calls from remote.
        webservice.load(resource: resource) { result in
            defer {
                completion(self.recentsFetchErrorCode)
            }
            self.reloading = false
            
            switch result {
            case .failure(WebserviceError.forbidden):
                self.recentsFetchErrorCode = .fetchNotAllowed
            case .failure:
                self.recentsFetchErrorCode = .fetchFailed
            case let .success(calls):
                guard let calls = calls else {
                    return
                }
                self.recentsFetchErrorCode = nil

                // Create and store the calls in the context.
                self.managedContext.performAndWait {
                    for call in calls {
                        _ = RecentCall.findOrCreate(for: call, in: self.managedContext)
                        try? self.managedContext.save()
                    }
                }
            }
        }
    }
    
    public func deleteRecentCalls() {
        let fetchRequest = RecentCall.sortedFetchRequest as! NSFetchRequest<NSFetchRequestResult>
        fetchRequest.entity = NSEntityDescription.entity(forEntityName: RecentCall.entityName, in: managedContext)
        fetchRequest.predicate = nil // Make sure you're not delete a subset but indeed all recent calls.
        fetchRequest.includesPropertyValues = false // Don't load unnecessary data in memory.
        do {
            if let calls = try managedContext.fetch(fetchRequest) as? [NSManagedObject] {
                // Delete every object.
                for call in calls {
                    managedContext.delete(call)
                }

                try managedContext.save()
            }
        } catch {
            let deleteError = error as NSError
            print("\(deleteError), \(deleteError.userInfo)")
        }
    }
}
