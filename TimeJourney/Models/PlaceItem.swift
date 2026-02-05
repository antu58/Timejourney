//
//  PlaceItem.swift
//  TimeJourney
//
//  Created by Codex on 2026/02/05.
//

import Foundation
import SwiftData
import MapKit
import CoreLocation

@Model
final class PlaceItem {
    @Attribute(.unique) var id: UUID

    var createdAt: Date

    // Core identity
    var name: String?
    var addressFull: String?
    var addressShort: String?
    var addressCityName: String?
    var addressCityWithContext: String?
    var addressRegionName: String?

    // Custom map icon (asset name in Assets.xcassets/MapIcons)
    var mapIconName: String?

    // Coordinates
    var latitude: Double
    var longitude: Double

    // Location quality / movement
    var horizontalAccuracy: Double?
    var verticalAccuracy: Double?
    var altitude: Double?
    var speed: Double?
    var course: Double?
    var timestamp: Date?

    // Time fields
    var arrivalAt: Date

    // MapKit details
    var phoneNumber: String?
    var url: URL?
    var pointOfInterestCategory: String?
    var timeZoneIdentifier: String?

    // Separate favorite flag; adding a place does not mean it is a favorite.
    var isFavorite: Bool

    @Relationship(inverse: \GroupPlaceLink.place) var groupLinks: [GroupPlaceLink] = []
    @Relationship(inverse: \ContentItem.place) var contents: [ContentItem] = []

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        name: String? = nil,
        addressFull: String? = nil,
        addressShort: String? = nil,
        addressCityName: String? = nil,
        addressCityWithContext: String? = nil,
        addressRegionName: String? = nil,
        mapIconName: String? = nil,
        latitude: Double,
        longitude: Double,
        horizontalAccuracy: Double? = nil,
        verticalAccuracy: Double? = nil,
        altitude: Double? = nil,
        speed: Double? = nil,
        course: Double? = nil,
        timestamp: Date? = nil,
        arrivalAt: Date? = nil,
        phoneNumber: String? = nil,
        url: URL? = nil,
        pointOfInterestCategory: String? = nil,
        timeZoneIdentifier: String? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.createdAt = createdAt
        self.name = name
        self.addressFull = addressFull
        self.addressShort = addressShort
        self.addressCityName = addressCityName
        self.addressCityWithContext = addressCityWithContext
        self.addressRegionName = addressRegionName
        self.mapIconName = mapIconName
        self.latitude = latitude
        self.longitude = longitude
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.altitude = altitude
        self.speed = speed
        self.course = course
        self.timestamp = timestamp
        self.arrivalAt = arrivalAt ?? createdAt
        self.phoneNumber = phoneNumber
        self.url = url
        self.pointOfInterestCategory = pointOfInterestCategory
        self.timeZoneIdentifier = timeZoneIdentifier
        self.isFavorite = isFavorite
    }

    convenience init(mapItem: MKMapItem, isFavorite: Bool = false) {
        let location = mapItem.location
        let address = mapItem.address
        let representations = mapItem.addressRepresentations

        self.init(
            name: mapItem.name,
            addressFull: address?.fullAddress
                ?? representations?.fullAddress(includingRegion: true, singleLine: true),
            addressShort: address?.shortAddress,
            addressCityName: representations?.cityName,
            addressCityWithContext: representations?.cityWithContext,
            addressRegionName: representations?.regionName,
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            horizontalAccuracy: PlaceItem.validAccuracy(location.horizontalAccuracy),
            verticalAccuracy: PlaceItem.validAccuracy(location.verticalAccuracy),
            altitude: location.altitude,
            speed: PlaceItem.validSpeed(location.speed),
            course: PlaceItem.validCourse(location.course),
            timestamp: location.timestamp,
            phoneNumber: mapItem.phoneNumber,
            url: mapItem.url,
            pointOfInterestCategory: mapItem.pointOfInterestCategory?.rawValue,
            timeZoneIdentifier: mapItem.timeZone?.identifier,
            isFavorite: isFavorite
        )
    }

    convenience init(location: CLLocation, name: String? = nil, isFavorite: Bool = false) {
        let coordinate = location.coordinate
        self.init(
            name: name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            horizontalAccuracy: PlaceItem.validAccuracy(location.horizontalAccuracy),
            verticalAccuracy: PlaceItem.validAccuracy(location.verticalAccuracy),
            altitude: location.altitude,
            speed: PlaceItem.validSpeed(location.speed),
            course: PlaceItem.validCourse(location.course),
            timestamp: location.timestamp,
            isFavorite: isFavorite
        )
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    private static func validAccuracy(_ value: CLLocationAccuracy?) -> Double? {
        guard let value, value >= 0 else { return nil }
        return value
    }

    private static func validSpeed(_ value: CLLocationSpeed?) -> Double? {
        guard let value, value >= 0 else { return nil }
        return value
    }

    private static func validCourse(_ value: CLLocationDirection?) -> Double? {
        guard let value, value >= 0 else { return nil }
        return value
    }

    
}
