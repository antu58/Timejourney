//
//  ContainerViewsDemo.swift
//  TimeJourney
//
//  Created by 张峰 on 2025/12/25.
//

import SwiftUI

/// 容器视图演示
/// 展示 ScrollView, NavigationStack, TabView, Group, GroupBox 等容器组件
struct ContainerViewsDemo: View {
    @State private var selectedTab = 0
    
    var body: some View {
        List {
            Section {
                ScrollView(.horizontal, showsIndicators: true) {
                    HStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .overlay {
                                    Text("\(index)")
                                        .font(.title2)
                                }
                        }
                    }
                    .padding()
                }
                .frame(height: 120)
            } header: {
                Text("ScrollView (滚动视图)")
            }
            
            Section {
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("GroupBox 内容")
                        Text("自动带有背景和边框")
                    }
                } label: {
                    Label("分组标题", systemImage: "folder.fill")
                }
            } header: {
                Text("GroupBox (分组框)")
            }
            
            Section {
                DisclosureGroup("点击展开/收起") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("展开的内容")
                        Text("支持嵌套使用")
                    }
                    .padding(.top, 8)
                }
                .padding()
            } header: {
                Text("DisclosureGroup (可展开分组)")
            }
            
            Section {
                TabView {
                    ForEach(0..<3) { index in
                        VStack {
                            Text("标签页 \(index + 1)")
                                .font(.title2)
                            Text("可以左右滑动")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(index)
                    }
                }
                .frame(height: 200)
                .tabViewStyle(.page)
            } header: {
                Text("TabView (标签页)")
            }
            
            Section {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(1...6, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.green.opacity(0.3))
                            .frame(height: 80)
                            .overlay {
                                Text("\(index)")
                                    .font(.title3)
                            }
                    }
                }
                .padding()
            } header: {
                Text("LazyVGrid (懒加载网格)")
            }
            
            Section {
                GeometryReader { geometry in
                    VStack {
                        Text("宽度: \(Int(geometry.size.width))")
                        Text("高度: \(Int(geometry.size.height))")
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(8)
                }
                .frame(height: 100)
            } header: {
                Text("GeometryReader (几何读取器)")
            }
        }
        .navigationTitle("容器视图")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ContainerViewsDemo()
    }
}

