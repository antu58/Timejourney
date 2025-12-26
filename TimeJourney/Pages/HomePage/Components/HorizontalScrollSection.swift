//
//  HorizontalScrollSection.swift
//  TimeJourney
//
//  Created by 张峰 on 2025/12/25.
//

import SwiftUI

/// 水平滚动列表组件 - App Store 风格
/// 包含标题、箭头按钮和水平滚动的内容
struct HorizontalScrollSection<Content: View, Item: Identifiable>: View {
    let title: String
    let items: [Item]
    let onTitleTap: () -> Void
    let contentBuilder: (Item) -> Content
    
    init(
        title: String,
        items: [Item],
        onTitleTap: @escaping () -> Void,
        @ViewBuilder contentBuilder: @escaping (Item) -> Content
    ) {
        self.title = title
        self.items = items
        self.onTitleTap = onTitleTap
        self.contentBuilder = contentBuilder
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题栏 - 可点击
            Button(action: onTitleTap) {
                HStack {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            // 水平滚动内容
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(items) { item in
                        contentBuilder(item)
                    }
                }
                .padding(.horizontal)
            }
            .scrollTargetBehavior(.paging)
        }
        .padding()
    }
}

#Preview {
    struct PreviewItem: Identifiable {
        let id: String
        let title: String
    }
    
    let sampleItems = [
        PreviewItem(id: "1", title: "项目 1"),
        PreviewItem(id: "2", title: "项目 2"),
        PreviewItem(id: "3", title: "项目 3"),
        PreviewItem(id: "4", title: "项目 4"),
        PreviewItem(id: "5", title: "项目 5")
    ]
    
    return ScrollView {
        VStack(spacing: 24) {
            HorizontalScrollSection(
                title: "免费 App 排行",
                items: sampleItems,
                onTitleTap: {
                    print("点击了标题")
                }
            ) { item in
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 160, height: 200)
                        .overlay {
                            Text(item.title)
                                .font(.headline)
                        }
                }
            }
            
            HorizontalScrollSection(
                title: "60 款 iPhone 装机必备",
                items: sampleItems,
                onTitleTap: {
                    print("点击了标题")
                }
            ) { item in
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 160, height: 200)
                        .overlay {
                            Text(item.title)
                                .font(.headline)
                        }
                }
            }
        }
    }
    .padding()
}

