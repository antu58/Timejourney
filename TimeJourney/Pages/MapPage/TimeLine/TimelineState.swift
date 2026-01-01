//
//  TimelineState.swift
//  TimeJourney
//
//  Created by 张峰 on 2026/1/1.
//

import Foundation
import Observation

/// 时间线状态管理器
/// 管理时间线滚动条的状态，支持从1970年到当前时间的时间范围
@Observable
final class TimelineState {
    
    /// 当前选中的时间
    var selectedDate: Date
    
    /// 时间范围起始时间（UTC 时间戳开始：1970年1月1日）
    let startDate: Date
    
    /// 时间范围结束时间（当前时间）
    var endDate: Date
    
    /// 滚动偏移量
    var scrollOffset: CGFloat = 0
    
    /// 是否正在拖动
    var isDragging: Bool = false
    
    /// 每个月份的宽度（像素）
    let monthWidth: CGFloat = 20
    
    /// 初始化
    /// - Parameter initialDate: 初始选中的时间，默认为当前时间
    init(initialDate: Date = Date()) {
        self.selectedDate = initialDate
        self.endDate = Date()
        // UTC 时间戳开始时间：1970年1月1日
        self.startDate = Date(timeIntervalSince1970: 0)
    }
    
    /// 获取从开始到结束的总年数
    var totalYears: Int {
        let calendar = Calendar.current
        let startYear = calendar.component(.year, from: startDate)
        let endYear = calendar.component(.year, from: endDate)
        return endYear - startYear + 1
    }
    
    /// 获取开始年份
    var startYear: Int {
        Calendar.current.component(.year, from: startDate)
    }
    
    /// 获取结束年份
    var endYear: Int {
        Calendar.current.component(.year, from: endDate)
    }
    
    /// 获取当前月份（1-12）
    var currentMonth: Int {
        Calendar.current.component(.month, from: endDate)
    }
    
    /// 计算时间线总宽度
    var totalWidth: CGFloat {
        // 每年12个月，每月 monthWidth 宽度
        CGFloat(totalYears) * 12 * monthWidth
    }
    
    /// 根据日期计算滚动位置
    func scrollPosition(for date: Date) -> CGFloat {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        
        let yearOffset = year - startYear
        let yearWidth = 12 * monthWidth
        
        return CGFloat(yearOffset) * yearWidth + CGFloat(month - 1) * monthWidth
    }
    
    /// 根据滚动位置计算日期
    func date(from scrollPosition: CGFloat) -> Date {
        let yearWidth = 12 * monthWidth
        let yearOffset = Int(scrollPosition / yearWidth)
        let remainingOffset = scrollPosition.truncatingRemainder(dividingBy: yearWidth)
        
        let month = max(1, min(12, Int(remainingOffset / monthWidth) + 1))
        let year = startYear + yearOffset
        
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        
        return Calendar.current.date(from: components) ?? Date()
    }
    
    /// 更新选中日期
    func updateSelectedDate(_ date: Date) {
        // 确保日期在有效范围内
        if date < startDate {
            selectedDate = startDate
        } else if date > endDate {
            selectedDate = endDate
        } else {
            selectedDate = date
        }
    }
    
    /// 滚动到指定日期
    func scrollTo(date: Date) {
        updateSelectedDate(date)
        scrollOffset = scrollPosition(for: selectedDate)
    }
    
    /// 滚动到当前时间
    func scrollToNow() {
        endDate = Date()
        scrollTo(date: endDate)
    }
    
    /// 格式化显示选中的日期
    var formattedSelectedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: selectedDate)
    }
}

