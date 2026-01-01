//
//  MapPage.swift
//  TimeJourney
//
//  Created by 张峰 on 2026/1/1.
//

import SwiftUI
import MapKit

struct MapPage: View {
    
    @State private var mapPosition = MapCameraPosition.automatic
    @State private var timelineState = TimelineState()
    
    var body: some View {
        ZStack {
            Map(position: $mapPosition)
                .mapStyle(.standard)
            
            VStack {
                Spacer()
                
                // 底部控制栏
                HStack(spacing: 16) {
                    // 指南按钮
                    Button(action: {
                        // TODO: 指南功能
                    }) {
                        Image(systemName: "compass.drawing")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .glassEffect(.regular, in: Circle())
                    }
                    .buttonStyle(.plain)
                    
                    // 时间线滚动条
                    TimelineScrollBar(state: timelineState)
                    
                    // 添加按钮
                    Button(action: {
                        // TODO: 添加功能
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .glassEffect(.regular, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding()

            }
        }
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {}) {
                    Label("User", systemImage: "person.circle.fill")
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: {  }) {
                    Label("Search", systemImage: "magnifyingglass")
                }
                Menu {
                    Button(action: {
                        
                    }) {
                        Label("标记当前位置", systemImage: "mappin.circle.fill")
                    }
                    Button(action: {
                        
                    }) {
                        Label("开始记录路线", systemImage: "record.circle.fill")
                    }
                    Button(action: {
                    }) {
                        Label("获取照片位置", systemImage: "photo")
                    }
                    Divider()
                    Button(action: { }) {
                        Label("数据导出", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Label("添加", systemImage: "plus")
                }
            }
            #endif
        }
    }
}

#Preview {
    NavigationStack {
        MapPage()
            .environment(NavigationManager())
    }
}
