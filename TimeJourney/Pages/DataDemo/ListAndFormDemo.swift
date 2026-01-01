//
//  ListAndFormDemo.swift
//  TimeJourney
//
//  Created by 张峰 on 2025/12/25.
//

import SwiftUI

/// 列表与表单演示
/// 展示 List、Form、Section 的用法和样式差异
struct ListAndFormDemo: View {
    @State private var toggleValue = false
    @State private var textValue = ""
    
    var body: some View {
        List {
            // List 基础
            Section {
                Text("List 用于显示可滚动的内容列表")
                Text("支持分组、分隔线、背景等样式")
            } header: {
                Text("List 基础")
            }
            
            // Form 基础
            Section {
                Text("Form 用于创建表单，通常包含输入控件")
                Text("默认使用分组样式，有卡片包裹")
            } header: {
                Text("Form 基础")
            }
            
            // Section 样式对比
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Section 在不同容器中的样式：")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("• Form: 默认分组样式（卡片）")
                    Text("• List (.grouped): 分组样式（卡片）")
                    Text("• List (.plain): 无卡片，只有分隔线")
                    Text("• List (.insetGrouped): 内嵌分组样式")
                }
                .font(.caption)
            } header: {
                Text("Section 样式")
            }
            
            // Section Header/Footer
            Section {
                Text("Section 可以设置 header 和 footer")
            } header: {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("自定义 Header")
                }
            } footer: {
                Text("这是 Footer 文本，用于提供额外说明")
                    .font(.caption)
            }
            .headerProminence(.increased)
            
            // 水平滚动列表（经典 iOS 样式）
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(1...5, id: \.self) { index in
                            VStack {
                                Circle()
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(width: 60, height: 60)
                                Text("项目 \(index)")
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                .listRowInsets(EdgeInsets())
            } header: {
                Button(action: {}) {
                    HStack {
                        Text("水平滚动列表")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("列表与表单")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ListAndFormDemo()
    }
}

