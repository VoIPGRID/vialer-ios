//
//  NSManagedObjectContext.swift
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import CoreData

extension NSManagedObjectContext {

    /// Easy implementation of inserting new object into the context.
    ///
    /// The type of the ManagedObject is deferred from the resulting object type, example:
    /// let newObject: TestingObject = managedContext.insertObject()
    ///
    /// - Returns: new instance.
    public func insertObject<A: NSManagedObject>() -> A where A: Managed {
        guard let obj = NSEntityDescription.insertNewObject(forEntityName: A.entityName, into: self) as? A else { fatalError("Wrong object type") }
        return obj
    }
}
