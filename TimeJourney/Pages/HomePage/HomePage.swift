//
//  HomePage.swift
//  TimeJourney
//
//  Created by 张峰 on 2025/12/25.
//

import SwiftUI
import SwiftData
import MapKit

struct HomePage: View {
    @Environment(NavigationManager.self) private var navigationManager
    @Environment(HomePageDataManager.self) private var dataManager
    @State private var mapPosition = MapCameraPosition.automatic

    var body: some View {
        ScrollView {
            // 地图卡片 - 可滚动
            ZStack(alignment: .topLeading) {
                // 地图背景
                Map(position: $mapPosition)
                    .allowsHitTesting(false)
                    .mapStyle(.standard)
                
                // 黑色遮罩层
                Color.black.opacity(0.3)
                
                // 数据分析文本
                VStack(alignment: .leading, spacing: 12) {
                    Text("数据统计")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    HStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("地点")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                            Text("\(dataManager.locationCount)个")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("路线")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                            Text("\(dataManager.routeCount)条")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .frame(height: 240)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding()
            
            // 你的指南
            HorizontalScrollSection(
                title: "你的指南",
                items: Array(dataManager.items.prefix(5)),
                onTitleTap: {
                    navigateToFullList(title: "你的指南", category: "guide")
                }
            ) { item in
                LocationCard(item: item) {
                    navigateToDetail(id: item.id)
                }
            }
            
            // 你的路线
            HorizontalScrollSection(
                title: "你的路线",
                items: dataManager.popularRoutes,
                onTitleTap: {
                    navigateToFullList(title: "你的路线", category: "route")
                }
            ) { route in
                RouteCard(route: route) {
                    // 可以添加路线详情导航
                    print("点击了路线: \(route.title)")
                }
            }
            
            // 你的地点
            HorizontalScrollSection(
                title: "你的地点",
                items: Array(dataManager.items.suffix(5)),
                onTitleTap: {
                    navigateToFullList(title: "你的地点", category: "location")
                }
            ) { item in
                LocationCard(item: item) {
                    navigateToDetail(id: item.id)
                }
            }
        }
        .navigationDestination(for: NavigationDestination.self) { destination in
            homePageDestinationView(for: destination)
        }
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: navigateToSearch) {
                    Label("User", systemImage: "person.circle.fill")
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: navigateToSearch) {
                    Label("Search", systemImage: "magnifyingglass")
                }
                Menu {
                    Button(action: addNewItem) {
                        Label("标记当前位置", systemImage: "mappin.circle.fill")
                    }
                    Button(action: addFromTemplate) {
                        Label("开始记录路线", systemImage: "record.circle.fill")
                    }
                    Button(action: importData) {
                        Label("获取照片位置", systemImage: "photo")
                    }
                    Divider()
                    Button(action: exportData) {
                        Label("数据导出", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Label("添加", systemImage: "plus")
                }
            }
            #endif
        }
    }

    private func navigateToSearch() {
        navigationManager.navigate(to: NavigationDestination.search)
    }
    
    /// 导航到详情页面（传入参数：ID）
    private func navigateToDetail(id: String) {
        navigationManager.navigate(to: .detail(id: id))
    }
    
    /// 标记当前位置
    private func addNewItem() {
        navigationManager.navigate(to: .markLocation)
    }
    
    /// 开始记录路线
    private func addFromTemplate() {
        navigationManager.navigate(to: .recordRoute)
    }
    
    /// 获取照片位置
    private func importData() {
        navigationManager.navigate(to: .importPhotoLocation)
    }
    
    /// 数据导出
    private func exportData() {
        navigationManager.navigate(to: .exportData)
    }
    
    /// 导航到完整列表页面
    private func navigateToFullList(title: String, category: String) {
        navigationManager.navigate(to: .fullList(title: title, category: category))
    }
    
    /// HomePage 管理的导航目标视图
    @ViewBuilder
    private func homePageDestinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .search:
            SearchPage()
        case .detail(let id):
            // 根据 ID 查找数据（传入参数）
            if let data = dataManager.findItem(by: id) {
                DetailPage(
                    data: data,
                    onSave: { updatedData in
                        // 接收详情页传出的参数并更新数据
                        dataManager.updateItem(updatedData)
                    }
                )
            } else {
                Text("数据未找到")
                    .navigationTitle("错误")
            }
        case .markLocation:
            MarkLocationPage { result in
                // 接收标记位置页面传出的参数
                print("标记位置结果: \(result)")
            }
        case .recordRoute:
            RecordRoutePage { result in
                // 接收记录路线页面传出的参数
                print("路线记录结果: \(result)")
            }
        case .importPhotoLocation:
            ImportPhotoLocationPage { result in
                // 接收照片位置页面传出的参数
                print("照片位置结果: \(result)")
            }
        case .exportData:
            ExportDataPage { result in
                // 接收数据导出页面传出的参数
                print("导出结果: \(result)")
            }
        case .fullList(let title, let category):
            // 根据分类显示不同的列表页面
            if category == "guide" {
                // 指南页面 - 带 Tab 切换
                FullGuidePage(
                    title: title,
                    routes: dataManager.getRoutes(for: "route"),
                    locations: dataManager.getItems(for: category),
                    onRouteTap: { routeId in
                        // 可以添加路线详情导航
                        print("点击了路线: \(routeId)")
                    },
                    onLocationTap: { id in
                        navigateToDetail(id: id)
                    }
                )
            } else if category == "route" {
                // 路线列表
                FullRouteListPage(
                    title: title,
                    routes: dataManager.getRoutes(for: category),
                    onRouteTap: { routeId in
                        // 可以添加路线详情导航
                        print("点击了路线: \(routeId)")
                    }
                )
            } else {
                // 地点列表
                FullListPage(
                    title: title,
                    items: dataManager.getItems(for: category),
                    onItemTap: { id in
                        navigateToDetail(id: id)
                    }
                )
            }
        default:
            // 其他导航目标由 ContentView 处理
            EmptyView()
        }
    }
}

#Preview {
    NavigationStack {
        HomePage()
            .environment(NavigationManager())
            .environment(HomePageDataManager())
    }
}
