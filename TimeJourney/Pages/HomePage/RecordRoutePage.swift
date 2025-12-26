//
//  RecordRoutePage.swift
//  TimeJourney
//
//  Created by 张峰 on 2025/12/25.
//

import SwiftUI

struct RecordRoutePage: View {
    @Environment(NavigationManager.self) private var navigationManager
    
    // 传出参数的回调
    let onResult: ((String) -> Void)?
    
    // 本地状态
    @State private var result: String = ""
    @State private var isRecording: Bool = false
    
    init(onResult: ((String) -> Void)? = nil) {
        self.onResult = onResult
    }
    
    var body: some View {
        Form {
            Section("记录路线") {
                Text("这里可以显示路线记录功能")
                    .foregroundStyle(.secondary)
                
                Toggle("正在记录", isOn: $isRecording)
                
                TextField("结果", text: $result, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            Section("操作") {
                Button("保存并返回（传出参数）") {
                    saveAndReturn()
                }
                .buttonStyle(.borderedProminent)
                
                Button("取消") {
                    navigationManager.goBack()
                }
                .buttonStyle(.bordered)
            }
        }
        .navigationTitle("开始记录路线")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /// 保存并返回（传出参数）
    private func saveAndReturn() {
        // 如果没有输入，使用默认值
        let finalResult = result.isEmpty ? "路线记录结果" : result
        
        // 调用回调函数传出参数
        onResult?(finalResult)
        
        // 返回上一页
        navigationManager.goBack()
    }
}

#Preview {
    NavigationStack {
        RecordRoutePage()
            .environment(NavigationManager())
    }
}

