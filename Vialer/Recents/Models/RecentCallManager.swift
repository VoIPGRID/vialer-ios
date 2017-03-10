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

    private struct Configuration {

        /// What is the minimum time between 2 fetches.
        static let refreshInterval = 60.0
    }

    /// Context that is used to fetch and store RecentCalls in.
    private let managedContext: NSManagedObjectContext

    /// Last time the recents where fetched.
    private var previousRefresh: Date?

    /// observer that listens to logout actions
    private var userLogout: NotificationToken

    /// Initializer
    ///
    /// - Parameter managedContext: Context that is used to fetch and store RecentCalls in.
    required init(managedContext: NSManagedObjectContext) {
        self.managedContext = managedContext

        // When users does a logout, remove all calls.
        userLogout = NotificationCenter.default.addObserver(descriptor: SystemUser.logoutNotification) { _ in
            let request = NSBatchDeleteRequest(fetchRequest: RecentCall.sortedFetchRequest as! NSFetchRequest<NSFetchRequestResult>)
            managedContext.perform {
                _ = try? managedContext.execute(request)
            }
        }
    }

    /// Fetch the latest calls and store them in the context.
    ///
    /// - Parameter completion: Completionblock that is called when completed.
    public func getLatestRecentCalls(completion: @escaping (RecentCallManagerError?)->()) {
        // Check if already reloading or fetch took place recently.
        guard !reloading, previousRefresh?.timeIntervalSinceNow ?? -Configuration.refreshInterval-1 < -Configuration.refreshInterval else {
            completion(nil)
            return
        }

        let fetchDate: Date
        // Fetch latest call 
        if let call = RecentCall.fetchLatest(in: managedContext) {
            fetchDate = Calendar.current.date(byAdding: .hour, value: -1, to: call.callDate)!
        } else {
            // Retrieve calls not older than 1 month
            fetchDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        }
        reloading = true

        // Fetch calls from remote.
        Webservice(authentication: SystemUser.current()).load(resource: RecentCall.allSince(date: fetchDate)) { result in
            self.reloading = false
            switch result {
            case .failure(WebserviceError.forbidden):
                self.recentsFetchErrorCode = .fetchNotAllowed
                completion(.fetchNotAllowed)
            case .failure:
                self.recentsFetchErrorCode = .fetchFailed
                completion(.fetchFailed)
            case let .success(calls):
                guard let calls = calls else {
                    completion(nil)
                    return
                }
                // Set last fetch date to now.
                self.previousRefresh = Date()
                self.recentsFetchErrorCode = nil

                // Create and store the calls in the context.
                self.managedContext.perform {
                    for call in calls {
                        _ = RecentCall.findOrCreate(for: call, in: self.managedContext)
                        try? self.managedContext.save()
                    }
                    completion(nil)
                }
            }
        }
    }
}
