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
    @State private var isSingleLocation: Bool = false
    @Environment(NavigationManager.self) private var navigationManager

    var body: some View {
        MapReader { mapProxy in
            ZStack {
                Map(position: $mapPosition)
                    .mapStyle(.standard)

                VStack {
                    Spacer()
                    
                    // 底部控制栏
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Button(action: {
                                // 定位功能
                                print("定位按钮被点击")
                                Task {
                                    await singleLocation(mapProxy: mapProxy)
                                }
                            }) {
                                Image(systemName: "location")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(isSingleLocation ? .secondary : .primary)
                                    .frame(width: 36, height: 36)
                                    .contentShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .disabled(isSingleLocation)
                            .glassEffect(.regular, in: Circle())
                            .opacity(isSingleLocation ? 0.5 : 1.0)
                            
                            Button(action: {
                                // TODO: 路线选择功能
                                print("路线选择按钮被点击")
                            }) {
                                Image(systemName: "hand.tap")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.primary)
                                    .frame(width: 36, height: 36)
                                    .contentShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .glassEffect(.regular, in: Circle())
                        }
                        .padding(.trailing, 10)
                    }
                    .padding(.bottom)
                    HStack(spacing: 16) {
                        // 指南按钮 - 使用导航管理器进入指南页面
                        Button(action: {
                            navigationManager.navigate(to: .guide)
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
                    Button(action: {
                        navigationManager.navigate(to: .user)
                    }) {
                        Label("User", systemImage: "person")
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        navigationManager.navigate(to: .search)
                    }) {
                        Label("Search", systemImage: "magnifyingglass")
                    }
                    Menu {
                        Button(action: {
                            // TODO: 分享功能
                        }) {
                            Label("分享", systemImage: "mappin")
                        }
                        Divider()
                        Button(action: {
                            // TODO: 数据导出功能
                        }) {
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
    
    /// 单次定位
    func singleLocation(mapProxy: MapProxy) async  {
        isSingleLocation = true
        let manager = CLLocationManager()
        // 先检查权限
        if await LocationUtil.checkAndRequestPermission() {
            manager.desiredAccuracy = kCLLocationAccuracyBest
            do {
                let location = try await withCheckedThrowingContinuation { continuation in
                    let delegate = LocationDelegate(continuation: continuation)
                    manager.delegate = delegate
                    objc_setAssociatedObject(manager, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                    manager.requestLocation()
                }
                // 转换坐标
                let gcj02 = LocationUtil.wgs84ToGcj02(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
                
                let result = """
                单次定位成功:
                系统坐标(WGS84):
                - 纬度: \(location.coordinate.latitude)
                - 经度: \(location.coordinate.longitude)

                转换坐标(GCJ-02):
                - 纬度: \(String(format: "%.6f", gcj02.latitude))
                - 经度: \(String(format: "%.6f", gcj02.longitude))

                定位精度: \(String(format: "%.0f米", location.horizontalAccuracy))
                时间: \(Date().formatted())
                """
                
                print(result)
                
                // 移动地图相机到定位坐标，zoom 15 (约1200米)
                await MainActor.run {
                    let coordinate = CLLocationCoordinate2D(
                        latitude: gcj02.latitude,
                        longitude: gcj02.longitude
                    )
                    // Zoom 15 约对应 0.01 度的跨度 (约1200米)
                    let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    let region = MKCoordinateRegion(center: coordinate, span: span)
                    mapPosition = .region(region)
                    isSingleLocation = false
                }
            } catch {
                print("定位失败: \(error.localizedDescription)")
                await MainActor.run {
                    isSingleLocation = false
                }
            }
        } else {
            await MainActor.run {
                isSingleLocation = false
            }
        }
    }
    
    /// 仅用于连续定位
    var locationManager: CLLocationManager?
    
    /// 开始连续定位
    private mutating func startContinuousLocation() async {
        // 检查权限
        let hasPermission = await LocationUtil.checkAndRequestPermission()

        guard hasPermission else {
            print("权限不足，无法连续定位")
            return
        }

        await MainActor.run {
            // 创建locationManager
            locationManager = CLLocationManager()
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
            locationManager?.distanceFilter = 10.0

            let delegate = ContinuousLocationDelegate { location in
                let gcj02 = LocationUtil.wgs84ToGcj02(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )

                let newLine = """
                新位置:
                WGS84: \(String(format: "%.6f", location.coordinate.latitude)), \(String(format: "%.6f", location.coordinate.longitude))
                GCJ-02: \(String(format: "%.6f", gcj02.latitude)), \(String(format: "%.6f", gcj02.longitude))
                精度: \(String(format: "%.0f米", location.horizontalAccuracy))
                \n
                """

                print(newLine)
            }

            locationManager?.delegate = delegate
            objc_setAssociatedObject(locationManager!, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            locationManager?.startUpdatingLocation()
        }
    }

    /// 停止连续定位
    private mutating func stopContinuousLocation() {
        locationManager?.stopUpdatingLocation()
        locationManager = nil
    }
}


// MARK: - 位置委托类

/// 单次定位委托
private class LocationDelegate: NSObject, CLLocationManagerDelegate {
    private let continuation: CheckedContinuation<CLLocation, Error>
    private var hasResumed = false

    init(continuation: CheckedContinuation<CLLocation, Error>) {
        self.continuation = continuation
        super.init()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !hasResumed, let location = locations.last else { return }
        hasResumed = true
        manager.stopUpdatingLocation()
        continuation.resume(returning: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard !hasResumed else { return }
        hasResumed = true
        manager.stopUpdatingLocation()
        continuation.resume(throwing: error)
    }
}

/// 连续定位委托
private class ContinuousLocationDelegate: NSObject, CLLocationManagerDelegate {
    private let onUpdate: (CLLocation) -> Void

    init(onUpdate: @escaping (CLLocation) -> Void) {
        self.onUpdate = onUpdate
        super.init()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            onUpdate(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("连续定位错误: \(error.localizedDescription)")
    }
}



#Preview {
    NavigationStack {
        MapPage()
            .environment(NavigationManager())
    }
}
