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
        DetailPageData(id: "3", title: "第三个数据", description: "这是第三个数据的描述", count: 30)
    ]
    
    // 路线数据（示例）
    var routes: [String] = ["路线1", "路线2"]
    
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
    
    /// 获取地点数量
    var locationCount: Int {
        items.count
    }
    
    /// 获取路线数量
    var routeCount: Int {
        routes.count
    }
}

