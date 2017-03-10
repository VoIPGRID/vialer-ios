//
//  Managed.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import CoreData


/// Protocol where every NSManagedObject needs to comply to.
public protocol Managed: class, NSFetchRequestResult {

    /// Name in Core Data of the model.
    static var entityName: String { get }

    /// Standard sorting of the model.
    static var defaultSortDescriptors: [NSSortDescriptor] { get }

    /// Default predicate/filtering of the model.
    static var defaultPredicate: NSPredicate { get }
}

extension Managed {

    /// By default, there is no predicate/filtering.
    public static var defaultPredicate: NSPredicate { return NSPredicate(value: true) }

    /// By default, there is no sorting.
    public static var defaultSortDescriptors: [NSSortDescriptor] { return [] }

    /// Add predicate to default predicate for the model.
    ///
    /// - Parameters:
    ///   - format: String with format of predicate.
    ///   - args: Strings with arguments for the format.
    /// - Returns: NSPredicate instance.
    public static func predicate(format: String, _ args: CVarArg...) -> NSPredicate {
        let p = withVaList(args) { NSPredicate(format: format, arguments: $0) }
        return predicate(p)
    }

    /// Create combine default predicate with given predicate.
    ///
    /// - Parameter predicate: The new predicate.
    /// - Returns: new predicate.
    public static func predicate(_ predicate: NSPredicate) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [defaultPredicate, predicate])
    }

    /// Default sorted fetchrequest for the model.
    public static var sortedFetchRequest: NSFetchRequest<Self> {
        let request = NSFetchRequest<Self>(entityName: entityName)
        request.sortDescriptors = defaultSortDescriptors
        request.predicate = defaultPredicate
        return request
    }
}

extension Managed where Self: NSManagedObject {

    /// Name of the model.
    public static var entityName: String {
        if #available(iOS 10.0, *) {
            return entity().name!
        } else {
            fatalError("Please provide an entityName for your NSManagedObjects!")
        }
    }

    /// Search for model instance given the predicate. If none found, create a new object.
    ///
    /// - Parameters:
    ///   - context: The context where to search and create in.
    ///   - predicate: Search parameter for finding existing object.
    ///   - configure: Callback block for configuring new object.
    /// - Returns: found or created object.
    public static func findOrCreate(in context: NSManagedObjectContext, matching predicate: NSPredicate, configure: (Self) -> ()) -> Self {
        guard let object = findOrFetch(in: context, matching: predicate) else {
            let newObject: Self = context.insertObject()
            configure(newObject)
            return newObject
        }
        return object
    }

    /// Search for model instance in the given context, if none found, fetch from store.
    ///
    /// - Parameters:
    ///   - context: The context where to search in.
    ///   - predicate: Search parameter for finding object.
    /// - Returns: Found object or nil.
    public static func findOrFetch(in context: NSManagedObjectContext, matching predicate: NSPredicate) -> Self? {
        guard let object = materializedObject(in: context, matching: predicate) else {
            return fetch(in: context) { request in
                request.predicate = predicate
                request.returnsObjectsAsFaults = false
                request.fetchLimit = 1
                }.first
        }
        return object
    }

    /// Search for model instance in the store.
    ///
    /// - Returns: Found object or nil.
    public static func fetch(in context: NSManagedObjectContext, configurationBlock: (NSFetchRequest<Self>) -> () = { _ in }) -> [Self] {
        let request = NSFetchRequest<Self>(entityName: Self.entityName)
        configurationBlock(request)
        return try! context.fetch(request)
    }

    /// Search for model instance in current context.
    ///
    /// - Parameters:
    ///   - context: The context where to search in.
    ///   - predicate: Search parameter for finding object.
    /// - Returns: Found object or nil.
    public static func materializedObject(in context: NSManagedObjectContext, matching predicate: NSPredicate) -> Self? {
        for object in context.registeredObjects where !object.isFault {
            guard let result = object as? Self, predicate.evaluate(with: result) else { continue }
            return result
        }
        return nil
    }
}
