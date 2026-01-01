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
                HStack {
                    Spacer()
                    VStack {
                        Button(action: {
                            // TODO: 定位功能
                        }) {
                            Image(systemName: "location")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.primary)
                                .frame(width: 36, height: 36)
                                .glassEffect(.regular, in: Circle())
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            // TODO: 路线选择功能
                        }) {
                            Image(systemName: "hand.tap")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.primary)
                                .frame(width: 36, height: 36)
                                .glassEffect(.regular, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.trailing, 10)
                }
                .padding(.bottom)
                HStack(spacing: 16) {
                    // 指南按钮
                    Button(action: {
                        // TODO: 指南功能
                    }) {
                        Image(systemName: "tray")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                            .glassEffect(.regular, in: Circle())
                    }
                    .buttonStyle(.plain)
                    
                    // 时间线滚动条
                    TimelineScrollBar(state: timelineState)
                    
                    // 添加按钮
                    Menu {
                        Button(action: {
                            
                        }) {
                            Label("标记当前位置", systemImage: "mappin")
                        }
                        Divider()
                        Button(action: {
                            
                        }) {
                            Label("开始记录路线", systemImage: "record.circle")
                        }
                        Divider()
                        Button(action: {
                        }) {
                            Label("获取照片位置", systemImage: "photo")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.black)
                            .frame(width: 44, height: 44)
                            .glassEffect(.regular, in: Circle())
                    }
                }
                .padding()

            }
        }
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {}) {
                    Label("User", systemImage: "person")
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: {  }) {
                    Label("Search", systemImage: "magnifyingglass")
                }
                Menu {
                    Button(action: {
                        
                    }) {
                        Label("分享", systemImage: "mappin")
                    }
                    Divider()
                    Button(action: { }) {
                        Label("数据导出", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Label("更多", systemImage: "ellipsis")
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
