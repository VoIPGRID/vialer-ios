//
//  NotificationToken.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import Foundation


/// Wrapper around an observer, for easy init and deinit of observer.
class NotificationToken {
    let token: NSObjectProtocol
    let center: NotificationCenter

    init(token: NSObjectProtocol, center: NotificationCenter) {
        self.token = token
        self.center = center
    }

    deinit {
        // Remove the observer from the NotificationCenter if this instance is deinitialized.
        center.removeObserver(token)
    }
}


/// Simple wrapper around a Notification Name, so that it can be used in NotificationToken.
/// For every notification, there should be one of these descriptors.
struct NotificationDescriptor<A> {
    let name: Notification.Name
}

extension NotificationCenter {

    /// Add an observer
    ///
    /// - Parameters:
    ///   - descriptor: The notification descriptor.
    ///   - queue: The queue used when getting the callback.
    ///   - block: The block that is called when notification is fired.
    /// - Returns: NotificationToken instance. As long there is a reference to this intance, the observer will be active. When dereferenced, the observer is removed.
    func addObserver<A>(descriptor: NotificationDescriptor<A>, queue: OperationQueue? = nil, using block: @escaping (A?) -> ()) -> NotificationToken {
        let token = addObserver(forName: descriptor.name, object: nil, queue: queue) { note in
            block(note.object as? A)
        }
        return NotificationToken(token: token, center: self)
    }

    func post<A>(descriptor: NotificationDescriptor<A>, object: A) {
        post(name: descriptor.name, object: object)
    }
}

extension SystemUser {

    static var logoutNotification = NotificationDescriptor<Any>(name: Notification.Name.SystemUserLogout)
    static var sipChangedNotification = NotificationDescriptor<Any>(name: Notification.Name.SystemUserSIPDisabled)
    static var sipDisabledNotification = NotificationDescriptor<Any>(name: Notification.Name.SystemUserSIPCredentialsChanged)
    static var use3GPlusNotification = NotificationDescriptor<Any>(name: Notification.Name.SystemUserUse3GPlus)
}
