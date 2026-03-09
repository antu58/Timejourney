//
//  NavigationManager.swift
//  TimeJourney
//
//  Created by 张峰 on 2025/12/25.
//

import SwiftUI
import Observation

enum NavigationDestination: Hashable {
    case search
    case user
    case placeDetail(id: UUID, groupId: UUID?)
    case routeDetail(id: UUID)
    case guide(groupId: UUID?)
}

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
