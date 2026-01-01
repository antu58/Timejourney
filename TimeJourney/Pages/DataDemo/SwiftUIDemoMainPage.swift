//
//  SwiftUIDemoMainPage.swift
//  TimeJourney
//
//  Created by 张峰 on 2025/12/25.
//

import SwiftUI

/// SwiftUI 组件演示主页面
/// 按分类组织所有演示页面，便于学习和查找
struct SwiftUIDemoMainPage: View {
    var body: some View {
        List {
            // 1. 基础布局
            Section {
                NavigationLink {
                    LayoutComponentsDemo()
                } label: {
                    demoRow(
                        title: "布局组件",
                        description: "VStack, HStack, ZStack, Grid 等基础布局",
                        icon: "square.stack.3d.up",
                        color: .blue
                    )
                }
            } header: {
                Text("基础组件")
            }
            
            // 2. 容器视图
            Section {
                NavigationLink {
                    ContainerViewsDemo()
                } label: {
                    demoRow(
                        title: "容器视图",
                        description: "ScrollView, TabView, GroupBox 等容器",
                        icon: "square.on.square",
                        color: .orange
                    )
                }
            } header: {
                Text("容器组件")
            }
            
            // 3. 列表与表单
            Section {
                NavigationLink {
                    ListAndFormDemo()
                } label: {
                    demoRow(
                        title: "列表与表单",
                        description: "List, Form, Section 及输入控件",
                        icon: "list.bullet.rectangle",
                        color: .green
                    )
                }
            } header: {
                Text("数据展示")
            }
            
            // 4. 交互组件
            Section {
                NavigationLink {
                    InteractiveComponentsDemo()
                } label: {
                    demoRow(
                        title: "交互组件",
                        description: "Button, Toggle, Picker, TextField 等",
                        icon: "hand.tap.fill",
                        color: .purple
                    )
                }
            } header: {
                Text("用户交互")
            }
            
            // 5. 视觉样式
            Section {
                NavigationLink {
                    VisualStylesDemo()
                } label: {
                    demoRow(
                        title: "视觉样式",
                        description: "颜色、文字、图标、修饰符",
                        icon: "paintbrush.fill",
                        color: .pink
                    )
                }
            } header: {
                Text("样式与主题")
            }
            
            // 提示信息
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        Text("使用提示")
                            .font(.headline)
                    }
                    Text("所有演示页面都包含 #Preview，可在 Xcode 预览中直接查看效果。建议使用预览功能学习。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("SwiftUI 组件库")
        .navigationBarTitleDisplayMode(.large)
    }
    
    @ViewBuilder
    private func demoRow(title: String, description: String, icon: String, color: Color) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(color)
        }
    }
}

#Preview {
    NavigationStack {
        SwiftUIDemoMainPage()
    }
}
