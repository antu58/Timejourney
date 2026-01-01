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
/// 显示从1970年到当前时间的时间线，支持左右滚动选择日期
struct TimelineScrollBar: View {
    
    /// 时间线状态（与父组件同步）
    @State var state: TimelineState
    
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
    
    var body: some View {
        GeometryReader { geometry in
            let viewWidth = geometry.size.width
            let centerX = viewWidth / 2
            
            ZStack {
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .bottom, spacing: 0) {
                            ForEach(state.startYear...state.endYear, id: \.self) { year in
                                yearView(year: year, isLastYear: year == state.endYear)
                            }
                        }
                        // 左侧 padding 允许1970年1月滚动到中心
                        .padding(.leading, centerX)
                        // 右侧 padding 允许当前月份滚动到中心
                        .padding(.trailing, centerX)
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
                            // 计算最大有效偏移量（当前月份刻度在中轴时的偏移）
                            let currentMonthPosition = CGFloat(state.endYear - state.startYear) * 12 * state.monthWidth
                                + CGFloat(state.currentMonth - 1) * state.monthWidth
                            let maxValidOffset = currentMonthPosition
                            
                            // 如果超出右边界（未来时间），限制到当前时间
                            if newValue.offset > maxValidOffset {
                                proxy.scrollTo(initialScrollID, anchor: .center)
                            } else {
                                updateSelectedDate(scrollOffset: newValue.offset, centerX: centerX)
                            }
                        }
                    }
                    .task {
                        // 等待布局完成后执行初始滚动
                        if !hasInitialScrolled {
                            try? await Task.sleep(for: .milliseconds(100))
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(initialScrollID, anchor: .center)
                            }
                            hasInitialScrolled = true
                        }
                    }
                    .onChange(of: scrollTargetID) { oldValue, newValue in
                        // 响应程序化滚动请求
                        if let targetID = newValue {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(targetID, anchor: .center)
                            }
                            scrollTargetID = nil
                        }
                    }
                }
                
                // 中心指示器
                centerIndicator
                    .allowsHitTesting(false)
            }
            .frame(height: geometry.size.height, alignment: .center)
        }
        .frame(height: 44)
        .glassEffect()
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
            
            // 如果是最后一年且不满12个月，填充空白
            if isLastYear && monthCount < 12 {
                Spacer()
                    .frame(width: CGFloat(12 - monthCount) * state.monthWidth)
            }
        }
    }
    
    /// 月份刻度视图
    @ViewBuilder
    private func monthTick(month: Int, year: Int) -> some View {
        VStack(spacing: 2) {
            // 年份标签（只在1月显示）
            if month == 1 {
                Text(String(year))
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .fixedSize()
            } else {
                Spacer()
                    .frame(height: 11) // 与年份标签高度匹配
            }
            
            // 刻度线
            Rectangle()
                .fill(tickColor(for: month))
                .frame(width: tickWidth(for: month), height: tickHeight(for: month))
        }
        .frame(width: state.monthWidth)
    }
    
    /// 根据滚动偏移更新选中日期
    private func updateSelectedDate(scrollOffset: CGFloat, centerX: CGFloat) {
        // 计算中心位置对应的日期
        let adjustedOffset = scrollOffset + centerX
        
        // 计算年份和月份
        let totalMonthWidth = state.monthWidth
        let yearWidth = 12 * totalMonthWidth
        
        let yearIndex = Int(adjustedOffset / yearWidth)
        let monthOffset = adjustedOffset.truncatingRemainder(dividingBy: yearWidth)
        let monthIndex = Int(monthOffset / totalMonthWidth)
        
        let year = state.startYear + yearIndex
        let month = max(1, min(12, monthIndex + 1))
        
        // 确保年份在有效范围内
        guard year >= state.startYear && year <= state.endYear else { return }
        
        // 如果是最后一年，限制月份
        let validMonth = (year == state.endYear) ? min(month, state.currentMonth) : month
        
        var components = DateComponents()
        components.year = year
        components.month = validMonth
        components.day = 1
        
        if let date = Calendar.current.date(from: components) {
            state.updateSelectedDate(date)
        }
    }
    
    /// 刻度线高度（季度和年份刻度更高）
    private func tickHeight(for month: Int) -> CGFloat {
        switch month {
        case 1: return 16  // 1月（年初）最高
        case 4, 7, 10: return 12  // 季度开始
        default: return 6  // 普通月份
        }
    }
    
    /// 刻度线宽度
    private func tickWidth(for month: Int) -> CGFloat {
        switch month {
        case 1: return 2  // 1月（年初）更粗
        case 4, 7, 10: return 1.5  // 季度开始
        default: return 1  // 普通月份
        }
    }
    
    /// 刻度线颜色
    private func tickColor(for month: Int) -> Color {
        switch month {
        case 1: return .primary.opacity(0.9)
        case 4, 7, 10: return .primary.opacity(0.6)
        default: return .primary.opacity(0.35)
        }
    }
    
    /// 中心指示器
    private var centerIndicator: some View {
        // 中心线
        Rectangle()
            .fill(.primary)
            .frame(width: 2, height: 28)
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

