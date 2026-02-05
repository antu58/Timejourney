//
//  GroupItem.swift
//  TimeJourney
//
//  Created by Codex on 2026/02/05.
//

import Foundation
import SwiftData

@Model
final class GroupItem {
    @Attribute(.unique) var id: UUID
    var createdAt: Date

    var name: String
    var note: String?

    @Relationship(inverse: \GroupPlaceLink.group) var placeLinks: [GroupPlaceLink] = []
    @Relationship(inverse: \GroupRouteLink.group) var routeLinks: [GroupRouteLink] = []

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        name: String,
        note: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.name = name
        self.note = note
    }

    var places: [PlaceItem] {
        placeLinks.compactMap { $0.place }
    }

    var routes: [RouteItem] {
        routeLinks.compactMap { $0.route }
    }
}

@Model
final class GroupPlaceLink {
    @Attribute(.unique) var key: String
    @Attribute(.unique) var id: UUID
    var addedAt: Date

    var group: GroupItem?
    var place: PlaceItem?

    init(
        id: UUID = UUID(),
        addedAt: Date = Date(),
        group: GroupItem,
        place: PlaceItem
    ) {
        self.id = id
        self.addedAt = addedAt
        self.group = group
        self.place = place
        self.key = GroupPlaceLink.makeKey(groupId: group.id, placeId: place.id)
    }

    static func makeKey(groupId: UUID, placeId: UUID) -> String {
        "g:\(groupId.uuidString.lowercased())|p:\(placeId.uuidString.lowercased())"
    }
}

@Model
final class GroupRouteLink {
    @Attribute(.unique) var key: String
    @Attribute(.unique) var id: UUID
    var addedAt: Date

    var group: GroupItem?
    var route: RouteItem?

    init(
        id: UUID = UUID(),
        addedAt: Date = Date(),
        group: GroupItem,
        route: RouteItem
    ) {
        self.id = id
        self.addedAt = addedAt
        self.group = group
        self.route = route
        self.key = GroupRouteLink.makeKey(groupId: group.id, routeId: route.id)
    }

    static func makeKey(groupId: UUID, routeId: UUID) -> String {
        "g:\(groupId.uuidString.lowercased())|r:\(routeId.uuidString.lowercased())"
    }
}
