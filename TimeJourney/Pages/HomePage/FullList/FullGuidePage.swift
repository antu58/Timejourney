//
//  FullGuidePage.swift
//  TimeJourney
//
//  Created by 张峰 on 2025/12/25.
//

import SwiftUI

/// 指南页面的 Tab 类型
enum GuideTabType: String, CaseIterable {
    case route = "路线"
    case location = "地点"
}

/// 完整指南页面 - 带顶部 Tab 切换（路线/地点）
struct FullGuidePage: View {
    let title: String
    let routes: [RouteData]
    let locations: [DetailPageData]
    let onRouteTap: ((String) -> Void)?
    let onLocationTap: ((String) -> Void)?
    
    @State private var selectedTab: GuideTabType = .route
    @Environment(NavigationManager.self) private var navigationManager
    
    init(
        title: String,
        routes: [RouteData],
        locations: [DetailPageData],
        onRouteTap: ((String) -> Void)? = nil,
        onLocationTap: ((String) -> Void)? = nil
    ) {
        self.title = title
        self.routes = routes
        self.locations = locations
        self.onRouteTap = onRouteTap
        self.onLocationTap = onLocationTap
    }
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 0) {
                // 顶部 Tab 选择器
                Picker("选择类型", selection: $selectedTab) {
                    ForEach(GuideTabType.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // 根据选中的 Tab 显示对应内容
                Group {
                    switch selectedTab {
                    case .route:
                        routeListView
                    case .location:
                        locationListView
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            #if os(iOS)
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: navigateToSearch) {
                    Label("Search", systemImage: "magnifyingglass")
                }
                Menu {
                    Button(action: addNewItem) {
                        Label("添加地点", systemImage: "mappin.circle.fill")
                    }
                    Button(action: addFromTemplate) {
                        Label("添加路线", systemImage: "record.circle.fill")
                    }
                    Button(action: importData) {
                        Label("选择", systemImage: "photo")
                    }
                } label: {
                    Label("更多", systemImage: "ellipsis.circle")
                }
            }
            #endif
        }
    }
    
    // 路线列表视图
    private var routeListView: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal)
    }
    
    // 地点列表视图
    private var locationListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(locations) { location in
                Button(action: {
                    if let onLocationTap = onLocationTap {
                        onLocationTap(location.id)
                    } else {
                        // 默认导航到详情页
                        navigationManager.navigate(to: .detail(id: location.id))
                    }
                }) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(location.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(location.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("计数: \(location.count)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Toolbar Actions
    
    /// 导航到用户页面
    private func navigateToUser() {
        // TODO: 实现用户页面导航
        print("导航到用户页面")
    }
    
    /// 导航到搜索页面
    private func navigateToSearch() {
        // TODO: 实现搜索页面导航
        print("导航到搜索页面")
    }
    
    /// 添加新地点
    private func addNewItem() {
        // TODO: 实现添加地点功能
        print("添加新地点")
    }
    
    /// 从模板添加路线
    private func addFromTemplate() {
        // TODO: 实现从模板添加路线功能
        print("从模板添加路线")
    }
    
    /// 导入数据（选择照片）
    private func importData() {
        // TODO: 实现导入数据功能
        print("导入数据")
    }
}

#Preview {
    NavigationStack {
        FullGuidePage(
            title: "你的指南",
            routes: [
                RouteData(id: "1", title: "路线 1", description: "描述 1", distance: "5.2 km", duration: "1.5 h"),
                RouteData(id: "2", title: "路线 2", description: "描述 2", distance: "8.3 km", duration: "2.0 h"),
                RouteData(id: "3", title: "路线 3", description: "描述 3", distance: "12.1 km", duration: "3.0 h")
            ],
            locations: [
                DetailPageData(id: "1", title: "地点 1", description: "描述 1", count: 10),
                DetailPageData(id: "2", title: "地点 2", description: "描述 2", count: 20),
                DetailPageData(id: "3", title: "地点 3", description: "描述 3", count: 30)
            ],
            onRouteTap: { id in
                print("点击了路线: \(id)")
            },
            onLocationTap: { id in
                print("点击了地点: \(id)")
            }
        )
        .environment(NavigationManager())
    }
}

