//
//  SystemIconsDemo.swift
//  TimeJourney
//
//  Created by 张峰 on 2025/12/25.
//

import SwiftUI

/// 系统图标（SF Symbols）演示
/// 展示常用的系统图标，支持分类、九宫格和列表布局
struct SystemIconsDemo: View {
    @State private var selectedLayout: LayoutStyle = .grid
    @State private var selectedCategory: IconCategory = .all
    @State private var searchText = ""
    
    enum LayoutStyle: String, CaseIterable {
        case grid = "九宫格"
        case list = "列表"
    }
    
    var filteredIcons: [IconItem] {
        let categoryIcons = selectedCategory == .all 
            ? allIcons 
            : allIcons.filter { $0.category == selectedCategory }
        
        if searchText.isEmpty {
            return categoryIcons
        } else {
            return categoryIcons.filter { 
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏和布局切换
            headerView
            
            // 分类选择
            categoryPicker
            
            // 内容区域
            if selectedLayout == .grid {
                gridView
            } else {
                listView
            }
        }
        .navigationTitle("系统图标")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索图标...", text: $searchText)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // 布局切换
            Picker("布局", selection: $selectedLayout) {
                ForEach(LayoutStyle.allCases, id: \.self) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Category Picker
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(IconCategory.allCases, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: category.iconName)
                                .font(.caption)
                            Text(category.displayName)
                                .font(.caption)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            selectedCategory == category 
                                ? Color.blue 
                                : Color(.systemGray5)
                        )
                        .foregroundStyle(
                            selectedCategory == category 
                                ? .white 
                                : .primary
                        )
                        .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Grid View (九宫格)
    private var gridView: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ],
                spacing: 20
            ) {
                ForEach(filteredIcons) { icon in
                    iconGridItem(icon)
                }
            }
            .padding()
        }
    }
    
    // MARK: - List View
    private var listView: some View {
        List {
            ForEach(filteredIcons) { icon in
                iconListItem(icon)
            }
        }
        .listStyle(.insetGrouped)
    }
    
    // MARK: - Icon Grid Item
    @ViewBuilder
    private func iconGridItem(_ icon: IconItem) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon.name)
                .font(.system(size: 40))
                .foregroundStyle(.blue)
                .frame(height: 60)
            
            VStack(spacing: 4) {
                Text(icon.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                
                Text(icon.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Icon List Item
    @ViewBuilder
    private func iconListItem(_ icon: IconItem) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon.name)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(icon.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(icon.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            // 可以添加点击操作，比如复制图标名称
            print("点击了图标: \(icon.name)")
        }
    }
}

// MARK: - Icon Category
enum IconCategory: String, CaseIterable {
    case all = "全部"
    case communication = "通信"
    case media = "媒体"
    case navigation = "导航"
    case actions = "操作"
    case objects = "对象"
    case weather = "天气"
    case people = "人物"
    case symbols = "符号"
    
    var displayName: String {
        rawValue
    }
    
    var iconName: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .communication: return "message.fill"
        case .media: return "play.circle.fill"
        case .navigation: return "location.fill"
        case .actions: return "hand.tap.fill"
        case .objects: return "cube.fill"
        case .weather: return "cloud.sun.fill"
        case .people: return "person.fill"
        case .symbols: return "star.fill"
        }
    }
}

// MARK: - Icon Item
struct IconItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let category: IconCategory
}

// MARK: - Icon Data
extension SystemIconsDemo {
    var allIcons: [IconItem] {
        [
            // 通信类
            IconItem(name: "message.fill", description: "消息", category: .communication),
            IconItem(name: "message.circle.fill", description: "消息圆圈", category: .communication),
            IconItem(name: "envelope.fill", description: "邮件", category: .communication),
            IconItem(name: "envelope.circle.fill", description: "邮件圆圈", category: .communication),
            IconItem(name: "phone.fill", description: "电话", category: .communication),
            IconItem(name: "phone.circle.fill", description: "电话圆圈", category: .communication),
            IconItem(name: "video.fill", description: "视频通话", category: .communication),
            IconItem(name: "bell.fill", description: "通知", category: .communication),
            IconItem(name: "bell.badge.fill", description: "通知徽章", category: .communication),
            
            // 媒体类
            IconItem(name: "play.fill", description: "播放", category: .media),
            IconItem(name: "play.circle.fill", description: "播放圆圈", category: .media),
            IconItem(name: "pause.fill", description: "暂停", category: .media),
            IconItem(name: "stop.fill", description: "停止", category: .media),
            IconItem(name: "forward.fill", description: "前进", category: .media),
            IconItem(name: "backward.fill", description: "后退", category: .media),
            IconItem(name: "music.note", description: "音乐", category: .media),
            IconItem(name: "music.mic", description: "麦克风", category: .media),
            IconItem(name: "photo.fill", description: "照片", category: .media),
            IconItem(name: "camera.fill", description: "相机", category: .media),
            IconItem(name: "video.fill", description: "视频", category: .media),
            
            // 导航类
            IconItem(name: "location.fill", description: "位置", category: .navigation),
            IconItem(name: "location.circle.fill", description: "位置圆圈", category: .navigation),
            IconItem(name: "map.fill", description: "地图", category: .navigation),
            IconItem(name: "mappin.circle.fill", description: "图钉", category: .navigation),
            IconItem(name: "arrow.up", description: "向上", category: .navigation),
            IconItem(name: "arrow.down", description: "向下", category: .navigation),
            IconItem(name: "arrow.left", description: "向左", category: .navigation),
            IconItem(name: "arrow.right", description: "向右", category: .navigation),
            IconItem(name: "chevron.up", description: "向上箭头", category: .navigation),
            IconItem(name: "chevron.down", description: "向下箭头", category: .navigation),
            IconItem(name: "chevron.left", description: "向左箭头", category: .navigation),
            IconItem(name: "chevron.right", description: "向右箭头", category: .navigation),
            
            // 操作类
            IconItem(name: "hand.tap.fill", description: "点击", category: .actions),
            IconItem(name: "hand.point.up.fill", description: "指向", category: .actions),
            IconItem(name: "share", description: "分享", category: .actions),
            IconItem(name: "square.and.arrow.up", description: "分享", category: .actions),
            IconItem(name: "square.and.arrow.down", description: "下载", category: .actions),
            IconItem(name: "heart.fill", description: "喜欢", category: .actions),
            IconItem(name: "star.fill", description: "收藏", category: .actions),
            IconItem(name: "bookmark.fill", description: "书签", category: .actions),
            IconItem(name: "trash.fill", description: "删除", category: .actions),
            IconItem(name: "pencil", description: "编辑", category: .actions),
            IconItem(name: "plus", description: "添加", category: .actions),
            IconItem(name: "minus", description: "减少", category: .actions),
            IconItem(name: "xmark", description: "关闭", category: .actions),
            IconItem(name: "checkmark", description: "确认", category: .actions),
            IconItem(name: "magnifyingglass", description: "搜索", category: .actions),
            IconItem(name: "slider.horizontal.3", description: "设置", category: .actions),
            
            // 对象类
            IconItem(name: "cube.fill", description: "立方体", category: .objects),
            IconItem(name: "folder.fill", description: "文件夹", category: .objects),
            IconItem(name: "doc.fill", description: "文档", category: .objects),
            IconItem(name: "doc.text.fill", description: "文本", category: .objects),
            IconItem(name: "book.fill", description: "书籍", category: .objects),
            IconItem(name: "calendar", description: "日历", category: .objects),
            IconItem(name: "clock.fill", description: "时钟", category: .objects),
            IconItem(name: "timer", description: "计时器", category: .objects),
            IconItem(name: "key.fill", description: "钥匙", category: .objects),
            IconItem(name: "lock.fill", description: "锁定", category: .objects),
            IconItem(name: "lock.open.fill", description: "解锁", category: .objects),
            IconItem(name: "house.fill", description: "房屋", category: .objects),
            IconItem(name: "car.fill", description: "汽车", category: .objects),
            
            // 天气类
            IconItem(name: "sun.max.fill", description: "太阳", category: .weather),
            IconItem(name: "moon.fill", description: "月亮", category: .weather),
            IconItem(name: "cloud.fill", description: "云", category: .weather),
            IconItem(name: "cloud.sun.fill", description: "多云", category: .weather),
            IconItem(name: "cloud.rain.fill", description: "雨", category: .weather),
            IconItem(name: "cloud.snow.fill", description: "雪", category: .weather),
            IconItem(name: "bolt.fill", description: "闪电", category: .weather),
            IconItem(name: "drop.fill", description: "水滴", category: .weather),
            
            // 人物类
            IconItem(name: "person.fill", description: "人物", category: .people),
            IconItem(name: "person.circle.fill", description: "人物圆圈", category: .people),
            IconItem(name: "person.2.fill", description: "多人", category: .people),
            IconItem(name: "person.3.fill", description: "团队", category: .people),
            IconItem(name: "face.smiling.fill", description: "笑脸", category: .people),
            
            // 符号类
            IconItem(name: "star.fill", description: "星星", category: .symbols),
            IconItem(name: "heart.fill", description: "心形", category: .symbols),
            IconItem(name: "flag.fill", description: "旗帜", category: .symbols),
            IconItem(name: "tag.fill", description: "标签", category: .symbols),
            IconItem(name: "exclamationmark.triangle.fill", description: "警告", category: .symbols),
            IconItem(name: "info.circle.fill", description: "信息", category: .symbols),
            IconItem(name: "questionmark.circle.fill", description: "问号", category: .symbols),
            IconItem(name: "checkmark.circle.fill", description: "确认圆圈", category: .symbols),
            IconItem(name: "xmark.circle.fill", description: "关闭圆圈", category: .symbols),
        ]
    }
}

#Preview {
    NavigationStack {
        SystemIconsDemo()
    }
}

