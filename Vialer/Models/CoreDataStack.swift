//
//  CoreDataStack.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import CoreData
import Foundation


/// Wrapper around Core Data.
class CoreDataStack {

    /// The name of the model for Core Data.
    private let modelNamed: String

    init(modelNamed: String) {
        self.modelNamed = modelNamed
    }

    // Save the main UI if there are changes.
    func saveContext() {
        guard mainContext.hasChanges else { return }
        do {
            try mainContext.save()
        } catch let error as NSError {
            VialerLogError("Could not save rootContext, error: \(error) \(error.userInfo)")
        }
    }

    /// - Main Context on main queue for UI.
    lazy var mainContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        return context
    }()

    /// - Sync Context on private queue for a sync processes (merged into Main context on save).
    lazy var syncContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.persistentStoreCoordinator = self.storeCoordinator
        self.setupNotifcations()
        return context
    }()

    private lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: self.modelNamed, withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    /// The store coordinator that will load the SQLite store. If the model is changed, the previous one will be removed and a new one will be created.
    private lazy var storeCoordinator: NSPersistentStoreCoordinator = {
        let storeURL = FileManager.documentsDir.appendingPathComponent("\(self.modelNamed).sqlite")
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
        } catch let error as NSError {
            // Store has changed, delete old and try to open again.
            self.resetStore()
            do {
                try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
            } catch let error as NSError {
                // abort() causes the application to generate a crash log and terminate.
                VialerLogError("Could not create PersistentStoreCoordinator instance. Unresolved error:\(error) \(error.userInfo)")
                abort()
            }
        }
        return coordinator
    }()

    /// All sync context saves are merged into the main context.
    private func setupNotifcations() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSManagedObjectContextDidSave, object: nil, queue: nil) { notification in
            guard let otherContext = notification.object as? NSManagedObjectContext,
                otherContext.persistentStoreCoordinator == self.mainContext.persistentStoreCoordinator,
                otherContext != self.mainContext else { return }
            self.mainContext.perform {
                self.mainContext.mergeChanges(fromContextDidSave: notification)
            }
        }
    }

    /// Delete the old store by removing the old one from disk.
    private func resetStore() {
        let storeURL = FileManager.documentsDir.appendingPathComponent("\(modelNamed).sqlite")
        let storeShmURL = URL(string: "\(storeURL)-shm")!
        let storeWalURL = URL(string: "\(storeURL)-wal")!

        do {
            try FileManager.default.removeItem(at: storeURL)
            try FileManager.default.removeItem(at: storeShmURL)
            try FileManager.default.removeItem(at: storeWalURL)
        } catch let error as NSError {
            VialerLogError("Error deleting old files: \(error) \(error.userInfo)")
            abort()
        }
    }
}
