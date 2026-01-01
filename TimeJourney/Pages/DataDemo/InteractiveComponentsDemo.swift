//
//  InteractiveComponentsDemo.swift
//  TimeJourney
//
//  Created by 张峰 on 2025/12/25.
//

import SwiftUI

/// 交互组件演示
/// 展示按钮、输入控件、选择器等交互组件
struct InteractiveComponentsDemo: View {
    @State private var toggleValue = false
    @State private var textValue = ""
    @State private var pickerValue = "选项1"
    @State private var sliderValue = 50.0
    
    var body: some View {
        List {
            // 按钮样式
            Section {
                Button("主要按钮") { }
                    .buttonStyle(.borderedProminent)
                
                Button("次要按钮") { }
                    .buttonStyle(.bordered)
                
                Button("文本按钮") { }
                    .buttonStyle(.plain)
                
                HStack {
                    Button(action: {}) {
                        Image(systemName: "heart.fill")
                    }
                    .buttonStyle(.borderless)
                    
                    Button(action: {}) {
                        Image(systemName: "share")
                    }
                    .buttonStyle(.borderless)
                }
            } header: {
                Text("按钮样式")
            } footer: {
                Text(".borderedProminent / .bordered / .plain / .borderless")
                    .font(.caption)
            }
            
            // 输入控件
            Section {
                TextField("单行输入", text: $textValue)
                
                TextField("多行输入", text: .constant(""), axis: .vertical)
                    .lineLimit(3...6)
                
                SecureField("密码输入", text: .constant(""))
            } header: {
                Text("文本输入")
            }
            
            // 选择控件
            Section {
                Toggle("开关", isOn: $toggleValue)
                
                Picker("选择器", selection: $pickerValue) {
                    Text("选项1").tag("选项1")
                    Text("选项2").tag("选项2")
                    Text("选项3").tag("选项3")
                }
                
                DatePicker("日期", selection: .constant(Date()), displayedComponents: .date)
                
                Slider(value: $sliderValue, in: 0...100)
                Text("当前值: \(Int(sliderValue))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Stepper("数量: \(Int(sliderValue))", value: $sliderValue, in: 0...100)
            } header: {
                Text("选择控件")
            }
            
            // 导航链接
            Section {
                NavigationLink {
                    Text("详情页面")
                        .navigationTitle("详情")
                } label: {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text("导航链接")
                    }
                }
            } header: {
                Text("导航")
            }
        }
        .navigationTitle("交互组件")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        InteractiveComponentsDemo()
    }
}

