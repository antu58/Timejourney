//
//  VisualStylesDemo.swift
//  TimeJourney
//
//  Created by 张峰 on 2025/12/25.
//

import SwiftUI

/// 视觉样式演示
/// 展示颜色、文字、图标、修饰符等视觉样式
struct VisualStylesDemo: View {
    @State private var selectedLayout: LayoutStyle = .grid
    
    enum LayoutStyle: String, CaseIterable {
        case grid = "九宫格"
        case list = "列表"
    }
    
    // 简单的图标结构，仅用于展示
    struct SimpleIcon: Identifiable {
        let id = UUID()
        let name: String
    }
    
    var body: some View {
        List {
            // 系统主题色
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Primary - 主要内容")
                        .foregroundStyle(.primary)
                    Text("Secondary - 次要内容")
                        .foregroundStyle(.secondary)
                    Text("Tertiary - 第三级内容")
                        .foregroundStyle(.tertiary)
                    Text("Quaternary - 最浅内容")
                        .foregroundStyle(.quaternary)
                }
                .font(.body)
            } header: {
                Text("系统主题色")
            } footer: {
                Text("自动适配深色/浅色模式")
                    .font(.caption)
            }
            
            // 文字样式
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Large Title").font(.largeTitle)
                    Text("Title").font(.title)
                    Text("Title 2").font(.title2)
                    Text("Title 3").font(.title3)
                    Text("Headline").font(.headline)
                    Text("Body").font(.body)
                    Text("Callout").font(.callout)
                    Text("Subheadline").font(.subheadline)
                    Text("Footnote").font(.footnote)
                    Text("Caption").font(.caption)
                    Text("Caption 2").font(.caption2)
                }
            } header: {
                Text("文字样式")
            }
            
            // 常用修饰符
            Section {
                VStack(spacing: 12) {
                    Text("圆角 + 背景")
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(12)
                    
                    Text("阴影效果")
                        .padding()
                        .background(Color.white)
                        .shadow(radius: 5)
                    
                    Text("渐变背景")
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                }
            } header: {
                Text("修饰符示例")
            }
            
            // 系统图标
            Section {
                Picker("布局", selection: $selectedLayout) {
                    ForEach(LayoutStyle.allCases, id: \.self) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                
                if selectedLayout == .grid {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(sampleIcons.prefix(9)) { icon in
                            VStack(spacing: 8) {
                                Image(systemName: icon.name)
                                    .font(.title2)
                                    .foregroundStyle(.blue)
                                Text(icon.name)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                } else {
                    ForEach(sampleIcons.prefix(6)) { icon in
                        HStack {
                            Image(systemName: icon.name)
                                .foregroundStyle(.blue)
                                .frame(width: 30)
                            Text(icon.name)
                                .font(.caption)
                        }
                    }
                }
            } header: {
                Text("系统图标 (SF Symbols)")
            } footer: {
                NavigationLink {
                    SystemIconsDemo()
                } label: {
                    Text("查看完整图标库 →")
                        .font(.caption)
                }
            }
        }
        .navigationTitle("视觉样式")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var sampleIcons: [SimpleIcon] {
        [
            SimpleIcon(name: "heart.fill"),
            SimpleIcon(name: "star.fill"),
            SimpleIcon(name: "share"),
            SimpleIcon(name: "trash.fill"),
            SimpleIcon(name: "pencil"),
            SimpleIcon(name: "magnifyingglass"),
            SimpleIcon(name: "location.fill"),
            SimpleIcon(name: "map.fill"),
            SimpleIcon(name: "person.fill"),
        ]
    }
}

#Preview {
    NavigationStack {
        VisualStylesDemo()
    }
}

