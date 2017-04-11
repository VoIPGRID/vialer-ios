//
//  HandOff.swift
//  Vialer
//
//  Created by Redmer Loen on 4/7/17.
//  Copyright © 2017 VoIPGRID. All rights reserved.
//

import Foundation
import MapKit
import CoreLocation

struct GeoKey {
    static let latitude = "latitude"
    static let longitude = "longitude"
    static let radius = "radius"
    static let identifier = "identifier"
    static let note = "note"
    static let eventType = "eventType"
}

enum EventType: String {
    case onEntry = "On Entry"
    case onExit = "On Exit"
}

class HandOffs: NSObject, NSCoding, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var radius: CLLocationDistance
    var identifier: String
    var note: String
    var eventType: EventType
    
    var title: String? {
        if note.isEmpty {
            return "No Note"
        }
        return note
    }
    
    var subtitle: String? {
        let eventTypeString = eventType.rawValue
        return "Radius: \(radius)m - \(eventTypeString)"
    }
    
    init(coordinate: CLLocationCoordinate2D, radius: CLLocationDistance, identifier: String, note: String, eventType: EventType) {
        self.coordinate = coordinate
        self.radius = radius
        self.identifier = identifier
        self.note = note
        self.eventType = eventType
    }
    
    required init?(coder aDecoder: NSCoder) {
        let latitude = aDecoder.decodeDouble(forKey: GeoKey.latitude)
        let longitude = aDecoder.decodeDouble(forKey: GeoKey.longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        radius = aDecoder.decodeDouble(forKey: GeoKey.radius)
        identifier = aDecoder.decodeObject(forKey: GeoKey.identifier) as! String
        note = aDecoder.decodeObject(forKey: GeoKey.note) as! String
        eventType = EventType(rawValue: aDecoder.decodeObject(forKey: GeoKey.eventType) as! String)!
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(coordinate.latitude, forKey: GeoKey.latitude)
        aCoder.encode(coordinate.longitude, forKey: GeoKey.longitude)
        aCoder.encode(radius, forKey: GeoKey.radius)
        aCoder.encode(identifier, forKey: GeoKey.identifier)
        aCoder.encode(note, forKey: GeoKey.note)
        aCoder.encode(eventType.rawValue, forKey: GeoKey.eventType)
    }
}
