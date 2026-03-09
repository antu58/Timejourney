//
//  GuidePage.swift
//  TimeJourney
//
//  Created by 张峰 on 2026/1/2.
//

import SwiftUI
import SwiftData

private enum GuideTab {
    case places
    case routes
}

/// 指南页面 - 显示当前指南内的地点和路线
struct GuidePage: View {
    let groupId: UUID?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(NavigationManager.self) private var navigationManager
    @Query private var groups: [GroupItem]
    @Query(sort: \PlaceItem.arrivalAt, order: .reverse) private var places: [PlaceItem]
    @Query(sort: \RouteItem.arrivalAt, order: .reverse) private var routes: [RouteItem]

    @State private var isShowingEditSheet = false
    @State private var isShowingDeleteGuideSheet = false
    @State private var isShowingAddPlacePicker = false
    @State private var isShowingAddRoutePicker = false
    @State private var selectedTab: GuideTab = .places
    @State private var placeDetailItem: DetailSheetItem?
    @State private var routeDetailItem: DetailSheetItem?

    var body: some View {
        VStack(spacing: 0) {
            Picker("类型", selection: $selectedTab) {
                Text("地点").tag(GuideTab.places)
                Text("路线").tag(GuideTab.routes)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            List {
                switch selectedTab {
                case .places:
                    if displayPlaces.isEmpty {
                        Text("暂无地点")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(displayPlaces, id: \.id) { place in
                            Button(action: {
                                placeDetailItem = DetailSheetItem(id: place.id, groupId: selectedGroup?.id)
                            }) {
                                PlaceRow(place: place)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                case .routes:
                    if displayRoutes.isEmpty {
                        Text("暂无路线")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(displayRoutes, id: \.id) { route in
                            Button(action: {
                                routeDetailItem = DetailSheetItem(id: route.id, groupId: selectedGroup?.id)
                            }) {
                                RouteRow(route: route)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle(selectedGroup?.name ?? "全部指南")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("添加地点") {
                        isShowingAddPlacePicker = true
                    }
                    .disabled(selectedGroup == nil)

                    Button("添加路线") {
                        isShowingAddRoutePicker = true
                    }
                    .disabled(selectedGroup == nil)

                    Divider()

                    Button("编辑指南") {
                        isShowingEditSheet = true
                    }
                    .disabled(selectedGroup == nil)

                    Button("删除指南", role: .destructive) {
                        isShowingDeleteGuideSheet = true
                    }
                    .disabled(selectedGroup == nil)
                } label: {
                    Label("更多", systemImage: "ellipsis")
                }
            }
        }
        .sheet(isPresented: $isShowingEditSheet) {
            if let group = selectedGroup {
                EditGuideSheet(group: group)
            }
        }
        .sheet(isPresented: $isShowingDeleteGuideSheet) {
            if let group = selectedGroup {
                DeleteGuideSheet(
                    group: group,
                    onDelete: { purgeData in
                        deleteSelectedGuide(purgeData: purgeData)
                    }
                )
            }
        }
        .sheet(isPresented: $isShowingAddPlacePicker) {
            if let group = selectedGroup {
                AddPlaceToGuideSheet(group: group, allPlaces: places)
            }
        }
        .sheet(isPresented: $isShowingAddRoutePicker) {
            if let group = selectedGroup {
                AddRouteToGuideSheet(group: group, allRoutes: routes)
            }
        }
        .sheet(item: $placeDetailItem) { item in
            NavigationStack {
                PlaceDetailPage(placeId: item.id, groupId: item.groupId)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $routeDetailItem) { item in
            NavigationStack {
                RouteDetailPage(routeId: item.id, groupId: item.groupId)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private var selectedGroup: GroupItem? {
        guard let groupId else { return nil }
        return groups.first(where: { $0.id == groupId })
    }

    private var displayPlaces: [PlaceItem] {
        if let group = selectedGroup {
            return group.places.sorted { $0.arrivalAt > $1.arrivalAt }
        }
        return places
    }

    private var displayRoutes: [RouteItem] {
        if let group = selectedGroup {
            return group.routes.sorted { $0.arrivalAt > $1.arrivalAt }
        }
        return routes
    }

    private func deleteSelectedGuide(purgeData: Bool) {
        guard let group = selectedGroup else { return }

        if purgeData {
            for link in group.placeLinks {
                if let place = link.place {
                    place.groupLinks.forEach { modelContext.delete($0) }
                    place.contents.forEach { modelContext.delete($0) }
                    modelContext.delete(place)
                }
            }
            for link in group.routeLinks {
                if let route = link.route {
                    route.groupLinks.forEach { modelContext.delete($0) }
                    route.contents.forEach { modelContext.delete($0) }
                    route.points.forEach { modelContext.delete($0) }
                    route.waypoints.forEach { modelContext.delete($0) }
                    modelContext.delete(route)
                }
            }
        } else {
            group.placeLinks.forEach { modelContext.delete($0) }
            group.routeLinks.forEach { modelContext.delete($0) }
        }

        modelContext.delete(group)
        modelContext.processPendingChanges()
        dismiss()
    }
}

private struct EditGuideSheet: View {
    @Environment(\.dismiss) private var dismiss
    let group: GroupItem

    @State private var name: String

    init(group: GroupItem) {
        self.group = group
        _name = State(initialValue: group.name)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("指南名称")
                    .font(.headline)
                TextField("请输入名称", text: $name)
                    .textFieldStyle(.roundedBorder)
            }
            .padding()
            .navigationTitle("编辑指南")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                    }
                    .disabled(!isSaveEnabled)
                }
            }
            .presentationDetents([.height(220)])
            .presentationDragIndicator(.visible)
        }
    }

    private var isSaveEnabled: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        group.name = trimmed
        dismiss()
    }
}

private struct DeleteGuideSheet: View {
    let group: GroupItem
    let onDelete: (Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var purgeData = false

    private var placeCount: Int { group.placeLinks.count }
    private var routeCount: Int { group.routeLinks.count }

    var body: some View {
        VStack(spacing: 16) {
            Text("删除指南")
                .font(.headline)
                .padding(.top, 12)

            Text("确定要删除「\(group.name)」吗？")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Toggle(isOn: $purgeData) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("彻底删除数据")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("同时删除指南内的 \(placeCount) 个地点和 \(routeCount) 条路线，其他指南中的关联也会被移除")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.red)
            .padding(.horizontal, 20)

            Button(role: .destructive) {
                dismiss()
                onDelete(purgeData)
            } label: {
                Text(purgeData ? "删除指南和数据" : "仅删除指南")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
                    .background(Color.red, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            Button("取消", role: .cancel) {
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(.primary)
            .background(Color.gray.opacity(0.2), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .presentationDetents([.height(310)])
        .presentationDragIndicator(.visible)
    }
}

private struct PlaceRow: View {
    let place: PlaceItem

    var body: some View {
        HStack(spacing: 12) {
            PlaceMarkerView(iconName: place.mapIconName, fallbackColor: .red, size: 20)
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name ?? "未命名地点")
                    .font(.headline)
                Text(place.addressShort ?? place.addressFull ?? "未知地址")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(formattedDate(place.arrivalAt))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

private struct RouteRow: View {
    let route: RouteItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "map")
                .font(.system(size: 16))
                .foregroundStyle(.blue)
                .frame(width: 20, height: 20)
            VStack(alignment: .leading, spacing: 4) {
                Text(route.name ?? "未命名路线")
                    .font(.headline)
                if let distance = route.distanceMeters {
                    Text(formattedDistance(distance))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text(formattedDate(route.arrivalAt))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func formattedDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.2f km", meters / 1000)
        } else {
            return String(format: "%.0f m", meters)
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

// MARK: - 添加地点到指南

private struct AddPlaceToGuideSheet: View {
    let group: GroupItem
    let allPlaces: [PlaceItem]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var selectedIds: Set<UUID> = []

    private var existingPlaceIds: Set<UUID> {
        Set(group.placeLinks.compactMap { $0.place?.id })
    }

    var body: some View {
        NavigationStack {
            List {
                if allPlaces.isEmpty {
                    Text("暂无地点")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(allPlaces, id: \.id) { place in
                        let isExisting = existingPlaceIds.contains(place.id)
                        let isSelected = selectedIds.contains(place.id)

                        Button(action: {
                            guard !isExisting else { return }
                            if isSelected {
                                selectedIds.remove(place.id)
                            } else {
                                selectedIds.insert(place.id)
                            }
                        }) {
                            HStack(spacing: 12) {
                                PlaceMarkerView(iconName: place.mapIconName, fallbackColor: .red, size: 20)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(place.name ?? "未命名地点")
                                        .font(.subheadline)
                                    Text(place.addressShort ?? place.addressFull ?? "未知地址")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                if isExisting {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.secondary)
                                } else if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(isExisting)
                        .opacity(isExisting ? 0.5 : 1)
                    }
                }
            }
            .navigationTitle("添加地点")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        addSelectedPlaces()
                        dismiss()
                    }
                    .disabled(selectedIds.isEmpty)
                }
            }
        }
    }

    private func addSelectedPlaces() {
        for place in allPlaces where selectedIds.contains(place.id) {
            let link = GroupPlaceLink(group: group, place: place)
            modelContext.insert(link)
        }
        modelContext.processPendingChanges()
    }
}

// MARK: - 添加路线到指南

private struct AddRouteToGuideSheet: View {
    let group: GroupItem
    let allRoutes: [RouteItem]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var selectedIds: Set<UUID> = []

    private var existingRouteIds: Set<UUID> {
        Set(group.routeLinks.compactMap { $0.route?.id })
    }

    var body: some View {
        NavigationStack {
            List {
                if allRoutes.isEmpty {
                    Text("暂无路线")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(allRoutes, id: \.id) { route in
                        let isExisting = existingRouteIds.contains(route.id)
                        let isSelected = selectedIds.contains(route.id)

                        Button(action: {
                            guard !isExisting else { return }
                            if isSelected {
                                selectedIds.remove(route.id)
                            } else {
                                selectedIds.insert(route.id)
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "map")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.blue)
                                    .frame(width: 20, height: 20)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(route.name ?? "未命名路线")
                                        .font(.subheadline)
                                    if let distance = route.distanceMeters {
                                        Text(formattedDistance(distance))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if isExisting {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.secondary)
                                } else if isSelected {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(isExisting)
                        .opacity(isExisting ? 0.5 : 1)
                    }
                }
            }
            .navigationTitle("添加路线")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        addSelectedRoutes()
                        dismiss()
                    }
                    .disabled(selectedIds.isEmpty)
                }
            }
        }
    }

    private func addSelectedRoutes() {
        for route in allRoutes where selectedIds.contains(route.id) {
            let link = GroupRouteLink(group: group, route: route)
            modelContext.insert(link)
        }
        modelContext.processPendingChanges()
    }

    private func formattedDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.2f km", meters / 1000)
        } else {
            return String(format: "%.0f m", meters)
        }
    }
}

#Preview {
    NavigationStack {
        GuidePage(groupId: nil)
            .environment(NavigationManager())
    }
}
