//
//  GuidePage.swift
//  TimeJourney
//
//  Created by 张峰 on 2026/1/2.
//

import SwiftUI
import SwiftData

/// 指南页面 - 显示当前指南内的地点和路线
struct GuidePage: View {
    let groupId: UUID?

    @Environment(\.modelContext) private var modelContext
    @Environment(NavigationManager.self) private var navigationManager
    @Query private var groups: [GroupItem]
    @Query(sort: \PlaceItem.arrivalAt, order: .reverse) private var places: [PlaceItem]
    @Query(sort: \RouteItem.createdAt, order: .reverse) private var routes: [RouteItem]

    @State private var selectedTab: GuideTab = .places
    @State private var isShowingEditSheet = false
    @State private var isShowingDeleteConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            tabBar

            List {
                switch selectedTab {
                case .places:
                    if displayPlaces.isEmpty {
                        Text("暂无地点")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(displayPlaces, id: \.id) { place in
                            Button(action: {
                                navigationManager.navigate(to: .placeDetail(id: place.id))
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
                            RouteRow(route: route)
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
                    Button("编辑指南") {
                        isShowingEditSheet = true
                    }
                    .disabled(selectedGroup == nil)

                    Button("删除指南", role: .destructive) {
                        isShowingDeleteConfirm = true
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
        .confirmationDialog("删除指南？", isPresented: $isShowingDeleteConfirm, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                deleteSelectedGuide()
            }
        } message: {
            Text("删除后，该指南下的地点/路线仍保留，只移除分组。")
        }
    }

    private var tabBar: some View {
        Picker("类型", selection: $selectedTab) {
            ForEach(GuideTab.allCases, id: \.self) { tab in
                Text(tab.title).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
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
            return group.routes.sorted { $0.createdAt > $1.createdAt }
        }
        return routes
    }

    private func deleteSelectedGuide() {
        guard let group = selectedGroup else { return }
        group.placeLinks.forEach { modelContext.delete($0) }
        group.routeLinks.forEach { modelContext.delete($0) }
        modelContext.delete(group)
        navigationManager.goBack()
    }
}

private enum GuideTab: String, CaseIterable {
    case places
    case routes

    var title: String {
        switch self {
        case .places:
            return "地点"
        case .routes:
            return "路线"
        }
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

private struct PlaceRow: View {
    let place: PlaceItem

    var body: some View {
        HStack(spacing: 12) {
            PlaceMarkerView(iconName: place.mapIconName, fallbackColor: .red, size: 18)
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
                .foregroundStyle(.blue)
            VStack(alignment: .leading, spacing: 4) {
                Text(route.name ?? "未命名路线")
                    .font(.headline)
                if let summary = route.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text(route.sourceTypeRaw == RouteSourceType.recorded.rawValue ? "轨迹记录" : "路线规划")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let distance = route.distanceMeters {
                Text(String(format: "%.1f km", distance / 1000))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        GuidePage(groupId: nil)
            .environment(NavigationManager())
    }
}
