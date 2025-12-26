//
//  LocationCard.swift
//  TimeJourney
//
//  Created by 张峰 on 2025/12/25.
//

import SwiftUI

/// 地点卡片组件 - 用于水平滚动列表
struct LocationCard: View {
    let item: DetailPageData
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // 占位图片/图标
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 120)
                    .overlay {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                    }
                
                // 标题
                Text(item.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                // 描述
                Text(item.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                // 计数
                HStack {
                    Image(systemName: "number.circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Text("\(item.count)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(width: 160)
            .padding(12)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        LocationCard(
            item: DetailPageData(
                id: "1",
                title: "示例地点",
                description: "这是一个示例地点的描述信息",
                count: 10
            ),
            onTap: {
                print("点击了卡片")
            }
        )
    }
    .padding()
}

