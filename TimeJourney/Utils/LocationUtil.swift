//
//  LocationUtil.swift
//  TimeJourney
//
//  Created by 张峰 on 2026/1/2.
//

import Foundation
import CoreLocation

/// 位置工具类 - 权限检查 + GCJ-02坐标转换
/// 无状态的工具类，提供静态方法和权限检查功能
final class LocationUtil {

    // MARK: - 权限检查

    /// 检查并请求位置权限（异步）
    static func checkAndRequestPermission() async -> Bool {
        let status = CLLocationManager().authorizationStatus

        if status == .notDetermined {
            return await withCheckedContinuation { continuation in
                let manager = CLLocationManager()
                // 创建临时的delegate来处理权限回调
                let delegate = PermissionDelegate(continuation: continuation)
                manager.delegate = delegate
                // 保持delegate引用
                objc_setAssociatedObject(manager, "permissionDelegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                manager.requestWhenInUseAuthorization()
            }
        }

        return status == .authorizedWhenInUse || status == .authorizedAlways
    }

    /// 仅检查权限状态（不请求）
    static func checkPermission() -> Bool {
        let status = CLLocationManager().authorizationStatus
        return status == .authorizedWhenInUse || status == .authorizedAlways
    }

    /// 获取当前权限状态
    static func getAuthorizationStatus() -> CLAuthorizationStatus {
        return CLLocationManager().authorizationStatus
    }

    // MARK: - GCJ-02 坐标转换

    /// WGS84 转 GCJ-02 坐标转换
    static func wgs84ToGcj02(latitude: Double, longitude: Double) -> (latitude: Double, longitude: Double) {
        // 中国境内的偏移算法
        let pi = Double.pi

        // 基本转换参数
        let a = 6378245.0 // 长半轴
        let ee = 0.00669342162296594323 // 偏心率平方

        // 判断是否在中国境内
        if !isOutOfChina(latitude: latitude, longitude: longitude) {
            let dLat = transformLat(x: longitude - 105.0, y: latitude - 35.0)
            let dLon = transformLon(x: longitude - 105.0, y: latitude - 35.0)

            let radLat = latitude / 180.0 * pi
            let sinRadLat = sin(radLat)
            let magic = 1 - ee * sinRadLat * sinRadLat

            let sqrtMagic = sqrt(magic)

            let dLat2 = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * pi)
            let dLon2 = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * pi)

            let mgLat = latitude + dLat2
            let mgLon = longitude + dLon2

            return (mgLat, mgLon)
        } else {
            return (latitude, longitude)
        }
    }

    /// 判断是否在中国境外
    private static func isOutOfChina(latitude: Double, longitude: Double) -> Bool {
        return longitude < 72.004 || longitude > 137.8347 || latitude < 0.8293 || latitude > 55.8271
    }

    /// 纬度转换
    private static func transformLat(x: Double, y: Double) -> Double {
        let pi = Double.pi
        var ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(fabs(x))
        ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0
        ret += (20.0 * sin(y * pi) + 40.0 * sin(y / 3.0 * pi)) * 2.0 / 3.0
        ret += (160.0 * sin(y / 12.0 * pi) + 320.0 * sin(y * pi / 30.0)) * 2.0 / 3.0
        return ret
    }

    /// 经度转换
    private static func transformLon(x: Double, y: Double) -> Double {
        let pi = Double.pi
        var ret = 300.0 + x + 2.0 * y + 0.1 * x * y + 0.1 * x * x + 0.1 * sqrt(fabs(x))
        ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0
        ret += (20.0 * sin(x * pi) + 40.0 * sin(x / 3.0 * pi)) * 2.0 / 3.0
        ret += (150.0 * sin(x / 12.0 * pi) + 300.0 * sin(x * pi / 30.0)) * 2.0 / 3.0
        return ret
    }
}

// MARK: - 权限委托类

/// 临时的权限委托类，用于处理权限请求回调
private class PermissionDelegate: NSObject, CLLocationManagerDelegate {
    private let continuation: CheckedContinuation<Bool, Never>

    init(continuation: CheckedContinuation<Bool, Never>) {
        self.continuation = continuation
        super.init()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let hasPermission = manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways
        continuation.resume(returning: hasPermission)
    }
}