//
//  RouteItem.swift
//  TimeJourney
//
//  Created by Codex on 2026/02/05.
//

import Foundation
import SwiftData
import MapKit
import CoreLocation

@Model
final class RouteItem {
    @Attribute(.unique) var id: UUID
    var createdAt: Date

    var name: String?
    var summary: String?

    // Source and geometry
    var sourceTypeRaw: String
    var geometryTypeRaw: String
    var transportTypeRaw: String?

    // Metrics
    var distanceMeters: Double?
    var expectedTravelTime: TimeInterval?

    // Recorded track info
    var recordedStart: Date?
    var recordedEnd: Date?

    // Quick bounds / endpoints
    var startLatitude: Double?
    var startLongitude: Double?
    var endLatitude: Double?
    var endLongitude: Double?

    // Favorite flag is independent of creation
    var isFavorite: Bool

    @Relationship(inverse: \RoutePoint.route) var points: [RoutePoint] = []
    @Relationship(inverse: \RouteWaypoint.route) var waypoints: [RouteWaypoint] = []
    @Relationship(inverse: \GroupRouteLink.route) var groupLinks: [GroupRouteLink] = []
    @Relationship(inverse: \ContentItem.route) var contents: [ContentItem] = []

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        name: String? = nil,
        summary: String? = nil,
        sourceTypeRaw: String = RouteSourceType.planned.rawValue,
        geometryTypeRaw: String = RouteGeometryType.mapKit.rawValue,
        transportTypeRaw: String? = nil,
        distanceMeters: Double? = nil,
        expectedTravelTime: TimeInterval? = nil,
        recordedStart: Date? = nil,
        recordedEnd: Date? = nil,
        startLatitude: Double? = nil,
        startLongitude: Double? = nil,
        endLatitude: Double? = nil,
        endLongitude: Double? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.createdAt = createdAt
        self.name = name
        self.summary = summary
        self.sourceTypeRaw = sourceTypeRaw
        self.geometryTypeRaw = geometryTypeRaw
        self.transportTypeRaw = transportTypeRaw
        self.distanceMeters = distanceMeters
        self.expectedTravelTime = expectedTravelTime
        self.recordedStart = recordedStart
        self.recordedEnd = recordedEnd
        self.startLatitude = startLatitude
        self.startLongitude = startLongitude
        self.endLatitude = endLatitude
        self.endLongitude = endLongitude
        self.isFavorite = isFavorite
    }

    var sourceType: RouteSourceType {
        get { RouteSourceType(rawValue: sourceTypeRaw) ?? .planned }
        set { sourceTypeRaw = newValue.rawValue }
    }

    var geometryType: RouteGeometryType {
        get { RouteGeometryType(rawValue: geometryTypeRaw) ?? .mapKit }
        set { geometryTypeRaw = newValue.rawValue }
    }

    var transportType: RouteTransportType? {
        get {
            guard let transportTypeRaw else { return nil }
            return RouteTransportType(rawValue: transportTypeRaw)
        }
        set { transportTypeRaw = newValue?.rawValue }
    }

    var startCoordinate: CLLocationCoordinate2D? {
        guard let startLatitude, let startLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: startLatitude, longitude: startLongitude)
    }

    var endCoordinate: CLLocationCoordinate2D? {
        guard let endLatitude, let endLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: endLatitude, longitude: endLongitude)
    }

    var sortedPoints: [RoutePoint] {
        points.sorted { $0.index < $1.index }
    }

    var sortedWaypoints: [RouteWaypoint] {
        waypoints.sorted { $0.index < $1.index }
    }

    convenience init(
        mkRoute: MKRoute,
        waypoints: [RouteWaypoint] = [],
        transportType: RouteTransportType,
        name: String? = nil,
        isFavorite: Bool = false
    ) {
        self.init(
            name: name,
            sourceTypeRaw: RouteSourceType.planned.rawValue,
            geometryTypeRaw: RouteGeometryType.mapKit.rawValue,
            transportTypeRaw: transportType.rawValue,
            distanceMeters: mkRoute.distance,
            expectedTravelTime: mkRoute.expectedTravelTime,
            startLatitude: mkRoute.polyline.coordinates.first?.latitude,
            startLongitude: mkRoute.polyline.coordinates.first?.longitude,
            endLatitude: mkRoute.polyline.coordinates.last?.latitude,
            endLongitude: mkRoute.polyline.coordinates.last?.longitude,
            isFavorite: isFavorite
        )
        self.points = mkRoute.polyline.coordinates.enumerated().map { index, coordinate in
            RoutePoint(index: index, latitude: coordinate.latitude, longitude: coordinate.longitude)
        }
        self.waypoints = waypoints
    }

    convenience init(
        straightLineFrom start: CLLocationCoordinate2D,
        to end: CLLocationCoordinate2D,
        waypoints: [RouteWaypoint] = [],
        name: String? = nil,
        isFavorite: Bool = false
    ) {
        self.init(
            name: name,
            sourceTypeRaw: RouteSourceType.planned.rawValue,
            geometryTypeRaw: RouteGeometryType.straightLine.rawValue,
            distanceMeters: CLLocation(latitude: start.latitude, longitude: start.longitude)
                .distance(from: CLLocation(latitude: end.latitude, longitude: end.longitude)),
            startLatitude: start.latitude,
            startLongitude: start.longitude,
            endLatitude: end.latitude,
            endLongitude: end.longitude,
            isFavorite: isFavorite
        )
        self.points = [
            RoutePoint(index: 0, latitude: start.latitude, longitude: start.longitude),
            RoutePoint(index: 1, latitude: end.latitude, longitude: end.longitude)
        ]
        self.waypoints = waypoints
    }

    convenience init(
        recordedLocations: [CLLocation],
        name: String? = nil,
        isFavorite: Bool = false
    ) {
        let sorted = recordedLocations.sorted { $0.timestamp < $1.timestamp }
        let start = sorted.first
        let end = sorted.last
        self.init(
            name: name,
            sourceTypeRaw: RouteSourceType.recorded.rawValue,
            geometryTypeRaw: RouteGeometryType.track.rawValue,
            distanceMeters: nil,
            expectedTravelTime: nil,
            recordedStart: start?.timestamp,
            recordedEnd: end?.timestamp,
            startLatitude: start?.coordinate.latitude,
            startLongitude: start?.coordinate.longitude,
            endLatitude: end?.coordinate.latitude,
            endLongitude: end?.coordinate.longitude,
            isFavorite: isFavorite
        )
        self.points = sorted.enumerated().map { index, location in
            RoutePoint(
                index: index,
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                timestamp: location.timestamp,
                altitude: location.altitude,
                horizontalAccuracy: RoutePoint.validAccuracy(location.horizontalAccuracy),
                verticalAccuracy: RoutePoint.validAccuracy(location.verticalAccuracy),
                speed: RoutePoint.validSpeed(location.speed),
                course: RoutePoint.validCourse(location.course)
            )
        }
    }
}

enum RouteSourceType: String, Codable {
    case planned
    case recorded
}

enum RouteGeometryType: String, Codable {
    case mapKit
    case straightLine
    case track
}

enum RouteTransportType: String, Codable {
    case automobile
    case walking
    case transit
    case cycling
    case any
    case unknown
}

@Model
final class RoutePoint {
    @Attribute(.unique) var id: UUID
    var index: Int
    var latitude: Double
    var longitude: Double
    var timestamp: Date?
    var altitude: Double?
    var horizontalAccuracy: Double?
    var verticalAccuracy: Double?
    var speed: Double?
    var course: Double?

    var route: RouteItem?

    init(
        id: UUID = UUID(),
        index: Int,
        latitude: Double,
        longitude: Double,
        timestamp: Date? = nil,
        altitude: Double? = nil,
        horizontalAccuracy: Double? = nil,
        verticalAccuracy: Double? = nil,
        speed: Double? = nil,
        course: Double? = nil
    ) {
        self.id = id
        self.index = index
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.speed = speed
        self.course = course
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    static func validAccuracy(_ value: CLLocationAccuracy?) -> Double? {
        guard let value, value >= 0 else { return nil }
        return value
    }

    static func validSpeed(_ value: CLLocationSpeed?) -> Double? {
        guard let value, value >= 0 else { return nil }
        return value
    }

    static func validCourse(_ value: CLLocationDirection?) -> Double? {
        guard let value, value >= 0 else { return nil }
        return value
    }
}

@Model
final class RouteWaypoint {
    @Attribute(.unique) var id: UUID
    var index: Int
    var name: String?
    var latitude: Double
    var longitude: Double

    var place: PlaceItem?
    var route: RouteItem?

    init(
        id: UUID = UUID(),
        index: Int,
        name: String? = nil,
        latitude: Double,
        longitude: Double,
        place: PlaceItem? = nil
    ) {
        self.id = id
        self.index = index
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.place = place
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

private extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = Array(repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}
