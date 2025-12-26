//
//  FullListPage.swift
//  TimeJourney
//
//  Created by 张峰 on 2025/12/25.
//

import SwiftUI

/// 完整列表页面 - 显示某个分类的所有项目
struct FullListPage: View {
    let title: String
    let items: [DetailPageData]
    let onItemTap: ((String) -> Void)?
    
    @Environment(NavigationManager.self) private var navigationManager
    
    init(title: String, items: [DetailPageData], onItemTap: ((String) -> Void)? = nil) {
        self.title = title
        self.items = items
        self.onItemTap = onItemTap
    }
    
    var body: some View {
        List {
            ForEach(items, id: \.id) { item in
                Button(action: {
                    if let onItemTap = onItemTap {
                        onItemTap(item.id)
                    } else {
                        // 默认导航到详情页
                        navigationManager.navigate(to: .detail(id: item.id))
                    }
                }) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(item.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("计数: \(item.count)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
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
        FullListPage(
            title: "完整列表",
            items: [
                DetailPageData(id: "1", title: "项目 1", description: "描述 1", count: 10),
                DetailPageData(id: "2", title: "项目 2", description: "描述 2", count: 20),
                DetailPageData(id: "3", title: "项目 3", description: "描述 3", count: 30)
            ],
            onItemTap: { id in
                print("点击了项目: \(id)")
            }
        )
        .environment(NavigationManager())
    }
}

