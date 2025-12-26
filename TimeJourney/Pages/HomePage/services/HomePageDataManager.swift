//
//  HomePageDataManager.swift
//  TimeJourney
//
//  Created by 张峰 on 2025/12/25.
//

import Foundation
import Observation

/// 首页数据管理器 - 使用 @Observable 管理数据状态
@Observable
final class HomePageDataManager {
    var items: [DetailPageData] = [
        DetailPageData(id: "1", title: "第一个数据", description: "这是第一个数据的描述", count: 10),
        DetailPageData(id: "2", title: "第二个数据", description: "这是第二个数据的描述", count: 20),
        DetailPageData(id: "3", title: "第三个数据", description: "这是第三个数据的描述", count: 30),
        DetailPageData(id: "4", title: "第四个数据", description: "这是第四个数据的描述", count: 40),
        DetailPageData(id: "5", title: "第五个数据", description: "这是第五个数据的描述", count: 50),
        DetailPageData(id: "6", title: "第六个数据", description: "这是第六个数据的描述", count: 60),
        DetailPageData(id: "7", title: "第七个数据", description: "这是第七个数据的描述", count: 70),
        DetailPageData(id: "8", title: "第八个数据", description: "这是第八个数据的描述", count: 80)
    ]
    
    // 热门路线数据
    var popularRoutes: [RouteData] = [
        RouteData(id: "route1", title: "城市探索路线", description: "探索城市的主要景点和地标", distance: "8.5 km", duration: "2.5 h"),
        RouteData(id: "route2", title: "自然风光路线", description: "欣赏自然美景和户外风光", distance: "12.3 km", duration: "3.5 h"),
        RouteData(id: "route3", title: "历史文化路线", description: "了解当地的历史文化背景", distance: "6.8 km", duration: "2.0 h"),
        RouteData(id: "route4", title: "美食之旅路线", description: "品尝当地特色美食和小吃", distance: "4.2 km", duration: "1.5 h"),
        RouteData(id: "route5", title: "夜景观光路线", description: "欣赏城市的夜景和灯光", distance: "9.1 km", duration: "2.8 h")
    ]
    
    /// 根据 ID 查找数据
    func findItem(by id: String) -> DetailPageData? {
        items.first { $0.id == id }
    }
    
    /// 更新数据（用于接收详情页传出的参数）
    func updateItem(_ updatedData: DetailPageData) {
        if let index = items.firstIndex(where: { $0.id == updatedData.id }) {
            items[index] = updatedData
        }
    }
    
    /// 根据分类获取地点数据
    func getItems(for category: String) -> [DetailPageData] {
        switch category {
        case "guide":
            // 你的指南 - 返回所有指南数据
            return items
        case "location":
            // 你的地点 - 返回所有地点数据
            return items
        default:
            return items
        }
    }
    
    /// 根据分类获取路线数据
    func getRoutes(for category: String) -> [RouteData] {
        switch category {
        case "route":
            // 你的路线 - 返回所有路线数据
            return popularRoutes
        default:
            return popularRoutes
        }
    }
    
    /// 获取地点数量
    var locationCount: Int {
        items.count
    }
    
    /// 获取路线数量
    var routeCount: Int {
        popularRoutes.count
    }
}

