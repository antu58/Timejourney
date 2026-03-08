//
//  TimelineScrollBar.swift
//  TimeJourney
//
//  Created by 张峰 on 2026/1/1.
//

import SwiftUI

/// 滚动几何信息
private struct ScrollGeometryInfo: Equatable {
    let offset: CGFloat
    let contentWidth: CGFloat
    let containerWidth: CGFloat
}

/// 时间线滚动条组件
/// 默认显示从当前时间向前 20 年到当前时间的时间线，支持左右滚动选择日期
struct TimelineScrollBar: View {
    
    /// 时间线状态（与父组件同步）
    @Bindable var state: TimelineState
    
    /// 滚动目标 ID（用于初始滚动和程序化滚动）
    @State private var scrollTargetID: String?
    
    /// 是否已完成初始滚动
    @State private var hasInitialScrolled = false
    
    /// 初始滚动目标 ID（基于结束日期，即当前时间）
    private var initialScrollID: String {
        let calendar = Calendar.current
        // 使用 endDate（当前时间）而不是 selectedDate，因为 selectedDate 可能被提前修改
        let year = calendar.component(.year, from: state.endDate)
        let month = calendar.component(.month, from: state.endDate)
        return yearMonthID(year: year, month: month)
    }
    
    /// 当前选中日期对应的滚动目标 ID
    private var selectedScrollID: String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: state.selectedDate)
        let month = calendar.component(.month, from: state.selectedDate)
        return yearMonthID(year: year, month: month)
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text(formattedYearMonth(state.selectedDate))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
   

                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .bottom, spacing: 0) {
                            ForEach(state.startYear...state.endYear, id: \.self) { year in
                                yearView(year: year, isLastYear: year == state.endYear)
                            }
                        }
                        .padding(.leading, geometry.size.width)
                        .opacity(0.5)
                    }
                    .scrollClipDisabled(false)
                    .onScrollGeometryChange(for: ScrollGeometryInfo.self) { geometry in
                        ScrollGeometryInfo(
                            offset: geometry.contentOffset.x,
                            contentWidth: geometry.contentSize.width,
                            containerWidth: geometry.containerSize.width
                        )
                    } action: { oldValue, newValue in
                        // 只有在初始滚动完成后才更新选中日期
                        if hasInitialScrolled {
                            // 当容器宽度变化时（屏幕缩放/旋转），保持当前选中日期右侧对齐
                            if oldValue.containerWidth != newValue.containerWidth {
                                let targetID = selectedScrollID
                                DispatchQueue.main.async {
                                    proxy.scrollTo(targetID, anchor: .trailing)
                                }
                                return
                            }
                            
                            // 计算最大有效偏移量（最右侧对齐）
                            let maxValidOffset = max(0, newValue.contentWidth - newValue.containerWidth)
                            
                            // 超出右边界（未来时间）时，不更新数据，交给系统弹性回弹
                            if newValue.offset <= maxValidOffset {
                                updateSelectedDate(scrollOffset: newValue.offset, containerWidth: newValue.containerWidth)
                            }
                        }
                    }
                    .task {
                        // 等待布局完成后执行初始滚动
                        if !hasInitialScrolled {
                            await Task.yield()
                            proxy.scrollTo(initialScrollID, anchor: .trailing)
                            hasInitialScrolled = true
                        }
                    }
                    .onChange(of: scrollTargetID) { oldValue, newValue in
                        // 响应程序化滚动请求
                        if let targetID = newValue {
                            if hasInitialScrolled {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    proxy.scrollTo(targetID, anchor: .trailing)
                                }
                            } else {
                                proxy.scrollTo(targetID, anchor: .trailing)
                            }
                            scrollTargetID = nil
                        }
                    }
                    .onChange(of: state.selectedDate) { _, _ in
                        guard hasInitialScrolled else { return }
                        let targetID = selectedScrollID
                        proxy.scrollTo(targetID, anchor: .trailing)
                    }
                    .onChange(of: state.startYear) { _, _ in
                        guard hasInitialScrolled else { return }
                        proxy.scrollTo(selectedScrollID, anchor: .trailing)
                    }
                }
                
            }
            .frame(height: geometry.size.height, alignment: .center)
        }
        .frame(height: 44)
    }
    
    /// 生成年月唯一标识
    private func yearMonthID(year: Int, month: Int) -> String {
        "\(year)-\(month)"
    }
    
    /// 年份视图
    @ViewBuilder
    private func yearView(year: Int, isLastYear: Bool) -> some View {
        HStack(alignment: .bottom, spacing: 0) {
            // 月份刻度
            let monthCount = isLastYear ? state.currentMonth : 12
            ForEach(1...monthCount, id: \.self) { month in
                monthTick(month: month, year: year)
                    .id(yearMonthID(year: year, month: month))
            }
        }
    }
    
    /// 月份刻度视图
    @ViewBuilder
    private func monthTick(month: Int, year: Int) -> some View {
        VStack(spacing: 2) {
            // 刻度线
            Rectangle()
                .fill(tickColor(for: month))
                .frame(width: tickWidth(for: month), height: tickHeight(for: month))
        }
        .frame(width: state.monthWidth)
    }
    
    /// 根据滚动偏移更新选中日期（按月份区间更新）
    private func updateSelectedDate(scrollOffset: CGFloat, containerWidth: CGFloat) {
        // 计算右侧对齐位置对应的月份区间（区间内不触发更新）
        // 将精确落在刻度线时视为前一个月份区间
        let epsilon: CGFloat = 0.001
        let adjustedOffset = max(0, scrollOffset + containerWidth - epsilon - containerWidth)
        let totalMonthWidth = state.monthWidth
        let totalMonths = max(0, Int(adjustedOffset / totalMonthWidth))

        let yearIndex = totalMonths / 12
        let monthIndex = totalMonths % 12
        let year = state.startYear + yearIndex
        var month = monthIndex + 1

        // 确保年份在有效范围内
        guard year >= state.startYear && year <= state.endYear else { return }

        // 如果是最后一年，限制月份
        if year == state.endYear {
            month = min(month, state.currentMonth)
        }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1

        if let date = Calendar.current.date(from: components) {
            state.updateSelectedDate(date)
        }
    }
    
    /// 刻度线高度（季度和年份刻度更高）
    private func tickHeight(for month: Int) -> CGFloat {
        switch month {
        case 1: return 16  // 1月（年初）
        default: return 8  // 普通月份
        }
    }
    
    /// 刻度线宽度
    private func tickWidth(for month: Int) -> CGFloat {
        switch month {
        case 1: return 1  // 1月（年初）与普通刻度一致
        case 4, 7, 10: return 1.5  // 季度开始
        default: return 1  // 普通月份
        }
    }
    
    /// 刻度线颜色
    private func tickColor(for month: Int) -> Color {
        switch month {
        case 1: return .primary.opacity(0.7)
        case 4, 7, 10: return .primary.opacity(0.5)
        default: return .primary.opacity(0.25)
        }
    }

    private func formattedYearMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy·M"
        return formatter.string(from: date)
    }
    
}


#Preview {
    VStack {
        Spacer()
        
        HStack(spacing: 16) {
            Button(action: {}) {
                Image(systemName: "compass.drawing")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.primary)
                    .frame(width: 44, height: 44)
                    .glassEffect(.regular, in: Circle())
            }
            .buttonStyle(.plain)
            
            TimelineScrollBar(state: TimelineState())
            
            Button(action: {}) {
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
    .background(Color.gray.opacity(0.3))
}
