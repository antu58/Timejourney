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

    @Query private var routes: [RouteItem]

    init(routeId: UUID) {
        self.routeId = routeId
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
                        infoRow(title: "距离", value: String(format: "%.1f km", distance / 1000))
                    }
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
        } else {
            ProgressView("加载中...")
        }
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
}

#Preview {
    let sample = RouteItem(name: "示例路线")
    return NavigationStack {
        RouteDetailPage(routeId: sample.id)
    }
}
