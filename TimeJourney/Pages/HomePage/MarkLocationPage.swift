//
//  MarkLocationPage.swift
//  TimeJourney
//
//  Created by 张峰 on 2025/12/25.
//

import SwiftUI

struct MarkLocationPage: View {
    @Environment(NavigationManager.self) private var navigationManager
    
    // 传出参数的回调
    let onResult: ((String) -> Void)?
    
    // 本地状态
    @State private var result: String = ""
    
    init(onResult: ((String) -> Void)? = nil) {
        self.onResult = onResult
    }
    
    var body: some View {
        Form {
            Section("标记当前位置") {
                Text("这里可以显示当前位置信息")
                    .foregroundStyle(.secondary)
                
                TextField("结果", text: $result, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            Section("操作") {
                Button("确认并返回（传出参数）") {
                    confirmAndReturn()
                }
                .buttonStyle(.borderedProminent)
                
                Button("取消") {
                    navigationManager.goBack()
                }
                .buttonStyle(.bordered)
            }
        }
        .navigationTitle("标记当前位置")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /// 确认并返回（传出参数）
    private func confirmAndReturn() {
        // 如果没有输入，使用默认值
        let finalResult = result.isEmpty ? "标记位置结果" : result
        
        // 调用回调函数传出参数
        onResult?(finalResult)
        
        // 返回上一页
        navigationManager.goBack()
    }
}

#Preview {
    NavigationStack {
        MarkLocationPage()
            .environment(NavigationManager())
    }
}

