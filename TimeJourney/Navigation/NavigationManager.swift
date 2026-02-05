//
//  NavigationManager.swift
//  TimeJourney
//
//  Created by 张峰 on 2025/12/25.
//

import SwiftUI
import Observation

/// 导航目标枚举
enum NavigationDestination: Hashable {
    case search
    case user  // 用户页面
    case detail(id: String)  // 传入参数：详情页面的 ID
    case placeDetail(id: UUID) // 地点详情页
    case markLocation  // 标记当前位置
    case recordRoute  // 开始记录路线
    case importPhotoLocation  // 获取照片位置
    case exportData  // 数据导出
    case fullList(title: String, category: String)  // 完整列表页面（传入标题和分类）
    case guide(groupId: UUID?)  // 指南页面（当前分组）
    // 可以继续添加其他导航目标
    // case settings
}

/// 导航管理器 - 使用 Swift 6 的 @Observable 宏
@Observable
final class NavigationManager {
    var path = NavigationPath()
    
    /// 导航到指定目标
    func navigate(to destination: NavigationDestination) {
        path.append(destination)
    }
    
    /// 返回上一页
    func goBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }
    
    /// 返回根页面
    func popToRoot() {
        path.removeLast(path.count)
    }
}
