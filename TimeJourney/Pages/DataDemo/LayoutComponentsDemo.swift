//
//  LayoutComponentsDemo.swift
//  TimeJourney
//
//  Created by 张峰 on 2025/12/25.
//

import SwiftUI

/// 基础布局组件演示
/// 展示 VStack, HStack, ZStack, LazyVStack, LazyHStack 等常用布局组件
struct LayoutComponentsDemo: View {
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("第一行")
                    Text("第二行")
                    Text("第三行")
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            } header: {
                Text("VStack (垂直堆叠)")
            }
            
            Section {
                HStack(spacing: 16) {
                    Circle().fill(Color.red).frame(width: 50, height: 50)
                    Circle().fill(Color.green).frame(width: 50, height: 50)
                    Circle().fill(Color.blue).frame(width: 50, height: 50)
                }
                .padding()
            } header: {
                Text("HStack (水平堆叠)")
            }
            
            Section {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: 200, height: 100)
                    Text("重叠内容")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            } header: {
                Text("ZStack (重叠堆叠)")
            }
            
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(1...5, id: \.self) { index in
                            VStack {
                                Circle()
                                    .fill(Color.purple.opacity(0.3))
                                    .frame(width: 60, height: 60)
                                Text("\(index)")
                                    .font(.caption)
                            }
                        }
                    }
                    .padding()
                }
            } header: {
                Text("LazyHStack (懒加载水平)")
            }
            
            Section {
                Grid(alignment: .center, horizontalSpacing: 12, verticalSpacing: 12) {
                    GridRow {
                        gridCell("1", color: .red)
                        gridCell("2", color: .green)
                        gridCell("3", color: .blue)
                    }
                    GridRow {
                        gridCell("4", color: .orange)
                        gridCell("5", color: .purple)
                        gridCell("6", color: .pink)
                    }
                }
                .padding()
            } header: {
                Text("Grid (网格布局)")
            }
            
            Section {
                HStack {
                    Text("左")
                    Spacer()
                    Text("中")
                    Spacer()
                    Text("右")
                }
                .padding()
            } header: {
                Text("Spacer (填充空间)")
            }
        }
        .navigationTitle("布局组件")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func gridCell(_ text: String, color: Color) -> some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(color.opacity(0.3))
            .frame(width: 80, height: 80)
            .overlay {
                Text(text)
                    .font(.title2)
                    .fontWeight(.bold)
            }
    }
}

#Preview {
    NavigationStack {
        LayoutComponentsDemo()
    }
}

#Preview {
    NavigationStack {
        LayoutComponentsDemo()
    }
}

