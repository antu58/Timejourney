//
//  RouteDetailPage.swift
//  TimeJourney
//
//  Created by Codex on 2026/03/08.
//

import SwiftUI
import SwiftData

struct RouteDetailPage: View {
    let routeId: UUID
    let groupId: UUID?

    @Query private var routes: [RouteItem]
    @Query(sort: \GroupItem.createdAt, order: .forward) private var groups: [GroupItem]
    @State private var isShowingDeleteSheet = false
    @State private var isShowingGuidePicker = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    init(routeId: UUID, groupId: UUID? = nil) {
        self.routeId = routeId
        self.groupId = groupId
        _routes = Query(filter: #Predicate<RouteItem> { $0.id == routeId })
    }

    var body: some View {
        if let route = routes.first {
            Form {
                Section("路线信息") {
                    infoRow(title: "名称", value: route.name)
                    infoRow(title: "描述", value: route.summary)
                    infoRow(title: "类型", value: route.sourceTypeRaw)
                    infoRow(title: "创建时间", value: formattedDate(route.createdAt))
                    if let distance = route.distanceMeters {
                        infoRow(title: "距离", value: formattedDistance(distance))
                    }
                    infoRow(title: "途经点", value: "\(route.sortedPoints.count) 个")
                }

                Section("到达时间") {
                    DatePicker(
                        "到达时间",
                        selection: Binding(
                            get: { route.arrivalAt },
                            set: { route.arrivalAt = $0 }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
            }
            .navigationTitle(route.name ?? "路线详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("添加到指南") {
                            isShowingGuidePicker = true
                        }
                        Button("删除路线", role: .destructive) {
                            isShowingDeleteSheet = true
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
            .sheet(isPresented: $isShowingGuidePicker) {
                RouteGuidePickerSheet(route: route, groups: groups)
            }
            .sheet(isPresented: $isShowingDeleteSheet) {
                DeleteRouteSheet(
                    hasGuides: groupId != nil,
                    onDelete: {
                        deleteRoute(route)
                    },
                    onRemoveFromGuide: {
                        removeRouteFromCurrentGuide(route)
                    }
                )
            }
        } else {
            ProgressView("加载中...")
        }
    }

    private func deleteRoute(_ route: RouteItem) {
        route.groupLinks.forEach { modelContext.delete($0) }
        route.contents.forEach { modelContext.delete($0) }
        route.points.forEach { modelContext.delete($0) }
        route.waypoints.forEach { modelContext.delete($0) }
        modelContext.delete(route)
        modelContext.processPendingChanges()
        dismiss()
    }

    private func removeRouteFromCurrentGuide(_ route: RouteItem) {
        guard let groupId else { return }
        let links = route.groupLinks.filter { $0.group?.id == groupId }
        links.forEach { modelContext.delete($0) }
        modelContext.processPendingChanges()
        dismiss()
    }

    @ViewBuilder
    private func infoRow(title: String, value: String?) -> some View {
        if let value, !value.isEmpty {
            HStack(alignment: .top) {
                Text(title)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func formattedDistance(_ meters: Double) -> String {
        if meters >= 1000 {
            return String(format: "%.2f km", meters / 1000)
        } else {
            return String(format: "%.0f m", meters)
        }
    }
}

// MARK: - 删除路线 Sheet

private struct DeleteRouteSheet: View {
    let hasGuides: Bool
    let onDelete: () -> Void
    let onRemoveFromGuide: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 12) {
            Text("删除路线")
                .font(.headline)
                .padding(.top, 8)

            if hasGuides {
                Button {
                    dismiss()
                    onRemoveFromGuide()
                } label: {
                    Text("移出指南")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(Color.red)
                        .background(Color.red.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Button(role: .destructive) {
                dismiss()
                onDelete()
            } label: {
                Text("彻底删除")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
                    .background(Color.red, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            Button("取消", role: .cancel) {
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(.primary)
            .background(Color.gray.opacity(0.2), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .buttonStyle(.plain)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .presentationDetents([.height(hasGuides ? 220 : 180)])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - 添加到指南 Sheet

private struct RouteGuidePickerSheet: View {
    let route: RouteItem
    let groups: [GroupItem]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var isShowingAddGuideSheet = false
    @State private var selectedGroupIds: Set<UUID> = []
    @State private var attachedGroupIds: Set<UUID> = []

    var body: some View {
        NavigationStack {
            List {
                if groups.isEmpty {
                    Text("暂无指南")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(groups, id: \.id) { group in
                        groupRow(group)
                    }
                }
            }
            .navigationTitle("添加到指南")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("新建") {
                        isShowingAddGuideSheet = true
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    Spacer()
                    Button(action: {
                        attachSelectedGroups()
                        dismiss()
                    }) {
                        Text("完成")
                            .font(.system(size: 16, weight: .semibold))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular, in: Capsule())
                    .disabled(selectedGroupIds.isEmpty)
                    .opacity(selectedGroupIds.isEmpty ? 0.5 : 1)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .onAppear {
            refreshAttachedIds()
        }
        .sheet(isPresented: $isShowingAddGuideSheet) {
            AddGuideSheet { group in
                selectedGroupIds.insert(group.id)
            }
        }
    }

    private func refreshAttachedIds() {
        let routeId = route.id
        let descriptor = FetchDescriptor<GroupRouteLink>(
            predicate: #Predicate<GroupRouteLink> { $0.route?.id == routeId }
        )
        let links = (try? modelContext.fetch(descriptor)) ?? []
        attachedGroupIds = Set(links.compactMap { $0.group?.id })
    }

    @ViewBuilder
    private func groupRow(_ group: GroupItem) -> some View {
        let isAttached = attachedGroupIds.contains(group.id)
        let isSelected = selectedGroupIds.contains(group.id)

        Button(action: {
            guard !isAttached else { return }
            if isSelected {
                selectedGroupIds.remove(group.id)
            } else {
                selectedGroupIds.insert(group.id)
            }
        }) {
            HStack {
                Text(group.name)
                    .foregroundStyle(.primary)
                Spacer()
                if isAttached {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.secondary)
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isAttached)
        .opacity(isAttached ? 0.6 : 1)
    }

    private func attachSelectedGroups() {
        let newIds = selectedGroupIds.subtracting(attachedGroupIds)
        guard !newIds.isEmpty else { return }

        for group in groups where newIds.contains(group.id) {
            let link = GroupRouteLink(group: group, route: route)
            modelContext.insert(link)
        }
        modelContext.processPendingChanges()
    }
}

#Preview {
    let sample = RouteItem(name: "示例路线")
    return NavigationStack {
        RouteDetailPage(routeId: sample.id)
    }
}
