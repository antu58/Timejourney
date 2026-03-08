//
//  LocationUtil.swift
//  TimeJourney
//
//  Created by 张峰 on 2026/1/2.
//

import Foundation
import CoreLocation

/// 位置工具类 - 权限检查
/// 无状态的工具类，提供静态方法和权限检查功能
final class LocationUtil {

    // MARK: - 权限检查
    private static var permissionManager: CLLocationManager?

    /// 检查并请求位置权限（异步）
    static func checkAndRequestPermission() async -> Bool {
        let status = CLLocationManager().authorizationStatus
        print("[LocationUtil] current authorizationStatus=\(status.rawValue)")

        if status == .notDetermined {
            return await withCheckedContinuation { continuation in
                let manager = CLLocationManager()
                permissionManager = manager
                // 创建临时的delegate来处理权限回调
                let delegate = PermissionDelegate(continuation: continuation) {
                    permissionManager = nil
                }
                manager.delegate = delegate
                // 保持delegate引用
                objc_setAssociatedObject(manager, "permissionDelegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                print("[LocationUtil] requestWhenInUseAuthorization")
                manager.requestWhenInUseAuthorization()
            }
        }

        let granted = status == .authorizedWhenInUse || status == .authorizedAlways
        print("[LocationUtil] permission granted=\(granted)")
        return granted
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

}

// MARK: - 权限委托类

/// 临时的权限委托类，用于处理权限请求回调
private class PermissionDelegate: NSObject, CLLocationManagerDelegate {
    private var continuation: CheckedContinuation<Bool, Never>?
    private let onFinish: () -> Void
    private var hasResumed = false

    init(continuation: CheckedContinuation<Bool, Never>, onFinish: @escaping () -> Void) {
        self.continuation = continuation
        self.onFinish = onFinish
        super.init()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        let hasPermission = status == .authorizedWhenInUse || status == .authorizedAlways
        print("[LocationUtil] authorization changed -> \(status.rawValue), granted=\(hasPermission)")
        guard status != .notDetermined else { return }
        guard !hasResumed, let continuation else { return }
        hasResumed = true
        continuation.resume(returning: hasPermission)
        self.continuation = nil
        onFinish()
    }
}
