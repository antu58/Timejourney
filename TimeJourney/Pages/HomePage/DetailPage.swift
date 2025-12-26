//
//  DetailPage.swift
//  TimeJourney
//
//  Created by 张峰 on 2025/12/25.
//

import SwiftUI
import SwiftData

/// 详情页面数据模型（用于演示传入参数）
struct DetailPageData: Identifiable {
    let id: String
    var title: String
    var description: String
    var count: Int
}

struct DetailPage: View {
    // 传入的参数
    let data: DetailPageData
    
    // 传出参数的回调（可选）
    let onSave: ((DetailPageData) -> Void)?
    
    // 本地状态（用于演示修改数据并传出）
    @State private var editedTitle: String
    @State private var editedDescription: String
    @State private var editedCount: Int
    
    // 获取导航管理器（用于返回）
    @Environment(NavigationManager.self) private var navigationManager
    
    init(data: DetailPageData, onSave: ((DetailPageData) -> Void)? = nil) {
        self.data = data
        self.onSave = onSave
        // 初始化本地状态为传入的数据
        _editedTitle = State(initialValue: data.title)
        _editedDescription = State(initialValue: data.description)
        _editedCount = State(initialValue: data.count)
    }
    
    var body: some View {
        Form {
            Section("基本信息") {
                Text("ID: \(data.id)")
                    .foregroundStyle(.secondary)
            }
            
            Section("可编辑内容") {
                TextField("标题", text: $editedTitle)
                TextField("描述", text: $editedDescription, axis: .vertical)
                    .lineLimit(3...6)
                Stepper("计数: \(editedCount)", value: $editedCount, in: 0...100)
            }
            
            Section("操作") {
                Button("保存并返回（传出参数）") {
                    saveAndReturn()
                }
                .buttonStyle(.borderedProminent)
                
                Button("仅返回") {
                    navigationManager.goBack()
                }
                .buttonStyle(.bordered)
            }
        }
        .navigationTitle("详情页面")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    /// 保存数据并返回（演示传出参数）
    private func saveAndReturn() {
        // 创建更新后的数据
        let updatedData = DetailPageData(
            id: data.id,
            title: editedTitle,
            description: editedDescription,
            count: editedCount
        )
        
        // 调用回调函数传出参数
        onSave?(updatedData)
        
        // 返回上一页
        navigationManager.goBack()
    }
}

#Preview {
    NavigationStack {
        DetailPage(
            data: DetailPageData(
                id: "1",
                title: "示例标题",
                description: "这是一个示例描述",
                count: 5
            )
        )
        .environment(NavigationManager())
    }
}

