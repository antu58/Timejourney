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

    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            MapPage()
                .navigationDestination(for: NavigationDestination.self) { destination in
                    destinationView(for: destination)
                }
                .toolbarTitleDisplayMode(.inline)
        }
        .environment(navigationManager)
    }
    
    @ViewBuilder
    private func destinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .guide(let groupId):
            GuidePage(groupId: groupId)
        case .search:
            SearchPage()
        case .user:
            UserPage()
        case .placeDetail(let id, let groupId):
            PlaceDetailPage(placeId: id, groupId: groupId)
        case .routeDetail(let id, let groupId):
            RouteDetailPage(routeId: id, groupId: groupId)
        }
    }
}

#Preview {
    ContentView()
}
