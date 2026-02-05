//
//  ContentItem.swift
//  TimeJourney
//
//  Created by Codex on 2026/02/05.
//

import Foundation
import SwiftData

@Model
final class ContentItem {
    @Attribute(.unique) var id: UUID
    var createdAt: Date

    var typeRaw: String

    // Display / notes
    var title: String?
    var note: String?

    // Text / URL payload
    var text: String?
    var url: URL?

    // File payload (path in app sandbox)
    var filePath: String?
    var fileName: String?
    var mimeType: String?
    var fileSizeBytes: Int64?

    // Media metadata
    var duration: TimeInterval?
    var width: Double?
    var height: Double?

    // Associations
    var place: PlaceItem?
    var route: RouteItem?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        typeRaw: String,
        title: String? = nil,
        note: String? = nil,
        text: String? = nil,
        url: URL? = nil,
        filePath: String? = nil,
        fileName: String? = nil,
        mimeType: String? = nil,
        fileSizeBytes: Int64? = nil,
        duration: TimeInterval? = nil,
        width: Double? = nil,
        height: Double? = nil,
        place: PlaceItem? = nil,
        route: RouteItem? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.typeRaw = typeRaw
        self.title = title
        self.note = note
        self.text = text
        self.url = url
        self.filePath = filePath
        self.fileName = fileName
        self.mimeType = mimeType
        self.fileSizeBytes = fileSizeBytes
        self.duration = duration
        self.width = width
        self.height = height
        self.place = place
        self.route = route
    }

    var type: ContentType {
        get { ContentType(rawValue: typeRaw) ?? .file }
        set { typeRaw = newValue.rawValue }
    }
}

enum ContentType: String, Codable {
    case text
    case url
    case image
    case video
    case audio
    case file
}
