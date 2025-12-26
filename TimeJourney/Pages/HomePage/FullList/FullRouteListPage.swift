//
//  FullRouteListPage.swift
//  TimeJourney
//
//  Created by 张峰 on 2025/12/25.
//

import SwiftUI

/// 完整路线列表页面 - 显示所有路线
struct FullRouteListPage: View {
    let title: String
    let routes: [RouteData]
    let onRouteTap: ((String) -> Void)?
    
    @Environment(NavigationManager.self) private var navigationManager
    
    init(title: String, routes: [RouteData], onRouteTap: ((String) -> Void)? = nil) {
        self.title = title
        self.routes = routes
        self.onRouteTap = onRouteTap
    }
    
    var body: some View {
        List {
            ForEach(routes) { route in
                Button(action: {
                    if let onRouteTap = onRouteTap {
                        onRouteTap(route.id)
                    } else {
                        // 可以添加路线详情导航
                        print("点击了路线: \(route.id)")
                    }
                }) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(route.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(route.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 16) {
                            Label(route.distance, systemImage: "ruler")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Label(route.duration, systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        FullRouteListPage(
            title: "你的路线",
            routes: [
                RouteData(id: "1", title: "路线 1", description: "描述 1", distance: "5.2 km", duration: "1.5 h"),
                RouteData(id: "2", title: "路线 2", description: "描述 2", distance: "8.3 km", duration: "2.0 h"),
                RouteData(id: "3", title: "路线 3", description: "描述 3", distance: "12.1 km", duration: "3.0 h")
            ],
            onRouteTap: { id in
                print("点击了路线: \(id)")
            }
        )
        .environment(NavigationManager())
    }
}

