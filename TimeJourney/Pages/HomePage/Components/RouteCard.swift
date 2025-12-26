//
//  RouteCard.swift
//  TimeJourney
//
//  Created by 张峰 on 2025/12/25.
//

import SwiftUI

/// 路线数据模型
struct RouteData: Identifiable {
    let id: String
    let title: String
    let description: String
    let distance: String
    let duration: String
}

/// 路线卡片组件 - 用于水平滚动列表
struct RouteCard: View {
    let route: RouteData
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // 占位图片/图标
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.6), .blue.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 160, height: 120)
                    .overlay {
                        Image(systemName: "map.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                    }
                
                // 标题
                Text(route.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                
                // 描述
                Text(route.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                
                // 距离和时长
                HStack(spacing: 12) {
                    Label(route.distance, systemImage: "ruler")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    
                    Label(route.duration, systemImage: "clock")
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
        RouteCard(
            route: RouteData(
                id: "1",
                title: "示例路线",
                description: "这是一条示例路线的描述",
                distance: "5.2 km",
                duration: "1.5 h"
            ),
            onTap: {
                print("点击了路线卡片")
            }
        )
    }
    .padding()
}

