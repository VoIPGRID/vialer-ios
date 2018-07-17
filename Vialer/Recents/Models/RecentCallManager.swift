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

    private var webservice: WebserviceProtocol!

    /// Initializer
    ///
    /// - Parameter managedContext: Context that is used to fetch and store RecentCalls in.
    required init(managedContext: NSManagedObjectContext, webservice: WebserviceProtocol? = nil) {
        self.managedContext = managedContext
        self.webservice = webservice ?? Webservice(authentication: SystemUser.current())

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

        var fetchDate: Date =  Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        // Get the latest call and check if it is smaller then a month ago.
        if let call = RecentCall.fetchLatest(in: managedContext) {
            if call.callDate > fetchDate {
                // Fetch the latest calls minus an hour
                fetchDate = Calendar.current.date(byAdding: .hour, value: -1, to: call.callDate)!
            }
        }
        reloading = true

        // Fetch calls from remote.
        webservice.load(resource: RecentCall.allSince(date: fetchDate)) { result in
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
                // Set last fetch date to now.
                self.previousRefresh = Date()
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
}
