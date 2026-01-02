//
//  GuidePage.swift
//  TimeJourney
//
//  Created by 张峰 on 2026/1/2.
//

import SwiftUI

/// 指南页面 - 使用 NavigationManager 导航进入
struct GuidePage: View {
    @Environment(NavigationManager.self) private var navigationManager

    // 模拟数据 - 在实际应用中可以从数据管理器获取
    @State private var routes: [RouteData] = [
        RouteData(id: "guide_1", title: "城市探索", description: "发现城市隐藏的角落", distance: "4.5 km", duration: "1.8 h"),
        RouteData(id: "guide_2", title: "历史之旅", description: "追溯城市历史足迹", distance: "6.2 km", duration: "2.5 h"),
        RouteData(id: "guide_3", title: "美食路线", description: "品尝地道美食", distance: "3.8 km", duration: "2.0 h")
    ]

    @State private var locations: [DetailPageData] = [
        DetailPageData(id: "guide_loc_1", title: "观景台", description: "俯瞰城市全景", count: 25),
        DetailPageData(id: "guide_loc_2", title: "老街区", description: "感受历史氛围", count: 18),
        DetailPageData(id: "guide_loc_3", title: "艺术中心", description: "现代艺术展览", count: 12),
        DetailPageData(id: "guide_loc_4", title: "中央公园", description: "城市绿肺", count: 8)
    ]

    @State private var selectedTab: GuideTabType = .route

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
        .navigationTitle("指南")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: NavigationDestination.self) { destination in
            switch destination {
            case .detail(let id):
                // 查找对应的数据并显示详情页
                if let location = locations.first(where: { $0.id == id }) {
                    DetailPage(data: location) { updatedData in
                        // 更新数据的逻辑
                        if let index = locations.firstIndex(where: { $0.id == updatedData.id }) {
                            locations[index] = updatedData
                        }
                    }
                } else {
                    Text("未找到详情数据")
                }
            default:
                EmptyView()
            }
        }
        .toolbar {
            #if os(iOS)
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: navigateToSearch) {
                    Label("Search", systemImage: "magnifyingglass")
                }
                Menu {
                    Button(action: addNewLocation) {
                        Label("添加地点", systemImage: "mappin.circle.fill")
                    }
                    Button(action: addNewRoute) {
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
                    // 点击路线的处理逻辑
                    print("点击了路线: \(route.id)")
                    // 可以在这里添加路线详情导航
                }) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "map.fill")
                                .foregroundStyle(.blue)
                            Text(route.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Spacer()
                        }

                        Text(route.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)

                        HStack(spacing: 16) {
                            Label(route.distance, systemImage: "ruler")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Label(route.duration, systemImage: "clock")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    // 地点列表视图
    private var locationListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(locations) { location in
                Button(action: {
                    // 导航到详情页
                    navigationManager.navigate(to: .detail(id: location.id))
                }) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.red)
                            Text(location.title)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Spacer()
                        }

                        Text(location.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("标记次数: \(location.count)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Toolbar Actions

    /// 导航到搜索页面
    private func navigateToSearch() {
        navigationManager.navigate(to: .search)
    }

    /// 添加新地点
    private func addNewLocation() {
        navigationManager.navigate(to: .markLocation)
    }

    /// 添加新路线
    private func addNewRoute() {
        navigationManager.navigate(to: .recordRoute)
    }

    /// 导入数据（选择照片）
    private func importData() {
        navigationManager.navigate(to: .importPhotoLocation)
    }
}

#Preview {
    NavigationStack {
        GuidePage()
            .environment(NavigationManager())
    }
}