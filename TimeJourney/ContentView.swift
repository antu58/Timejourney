//
//  ContentView.swift
//  TimeJourney
//
//  Created by 张峰 on 2025/12/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var navigationManager = NavigationManager()
    @State private var dataManager = HomePageDataManager()

    var body: some View {
        NavigationSplitView {
            NavigationStack(path: $navigationManager.path) {
                MapPage()
                    .navigationDestination(for: NavigationDestination.self) { destination in
                        destinationView(for: destination)
                    }
                    .toolbarTitleDisplayMode(.inline)
            }
        } detail: {
            Text("Detail")
        }
        .environment(navigationManager)
        .environment(dataManager)
    }
    
    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .guide:
            GuidePage()
        case .search:
            SearchPage()
        case .user:
            UserPage()
        default:
            // 其他导航目标由各自页面处理
            EmptyView()
        }
    }
}

#Preview {
    ContentView()
}
