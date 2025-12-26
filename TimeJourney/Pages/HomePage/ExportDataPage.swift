//
//  ExportDataPage.swift
//  TimeJourney
//
//  Created by 张峰 on 2025/12/25.
//

import SwiftUI

struct ExportDataPage: View {
    @Environment(NavigationManager.self) private var navigationManager
    
    // 传出参数的回调
    let onResult: ((String) -> Void)?
    
    // 本地状态
    @State private var result: String = ""
    @State private var exportFormat: ExportFormat = .json
    
    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"
        case xml = "XML"
    }
    
    init(onResult: ((String) -> Void)? = nil) {
        self.onResult = onResult
    }
    
    var body: some View {
        Form {
            Section("数据导出") {
                Text("选择导出格式和选项")
                    .foregroundStyle(.secondary)
                
                Picker("导出格式", selection: $exportFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                
                TextField("结果", text: $result, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            Section("操作") {
                Button("导出并返回（传出参数）") {
                    exportAndReturn()
                }
                .buttonStyle(.borderedProminent)
                
                Button("取消") {
                    navigationManager.goBack()
                }
                .buttonStyle(.bordered)
            }
        }
        .navigationTitle("数据导出")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /// 导出并返回（传出参数）
    private func exportAndReturn() {
        // 如果没有输入，使用默认值
        let finalResult = result.isEmpty ? "导出结果: \(exportFormat.rawValue)" : result
        
        // 调用回调函数传出参数
        onResult?(finalResult)
        
        // 返回上一页
        navigationManager.goBack()
    }
}

#Preview {
    NavigationStack {
        ExportDataPage()
            .environment(NavigationManager())
    }
}

