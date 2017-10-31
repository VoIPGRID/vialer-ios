//
//  CoreDataStackHelper.swift
//  Vialer
//
//  Created by Redmer Loen on 10/16/17.
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStackHelper : NSObject {
    static let instance = CoreDataStackHelper()

    // Core Data
    lazy var coreDataStack: CoreDataStack = {
        return CoreDataStack(modelNamed: "Vialer")
    }()

    var managedObjectContext: NSManagedObjectContext {
        get {
            return coreDataStack.mainContext
        }
    }

    @objc var syncContext: NSManagedObjectContext {
        get {
            return coreDataStack.syncContext
        }
    }

    @objc class func sharedInstance() -> CoreDataStackHelper {
        return CoreDataStackHelper.instance
    }
}
