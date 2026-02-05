//
//  MapPage.swift
//  TimeJourney
//
//  Created by 张峰 on 2026/1/1.
//

import SwiftUI
import MapKit
import SwiftData

struct MapPage: View {

    @State private var mapPosition = MapCameraPosition.automatic
    @State private var timelineState = TimelineState()
    @State private var isSingleLocation: Bool = false
    @State private var isSavingCurrentLocation: Bool = false
    @State private var showsUserLocation: Bool = false
    @State private var selectedGroupId: UUID? = nil
    @State private var isShowingAddGuideSheet: Bool = false
    @State private var isAddingPlace: Bool = false
    @Environment(NavigationManager.self) private var navigationManager
    @Environment(\.modelContext) private var modelContext
    @Query private var places: [PlaceItem]
    @Query(sort: \GroupItem.createdAt, order: .forward) private var groups: [GroupItem]
    @Query private var groupPlaceLinks: [GroupPlaceLink]

    private var visiblePlaces: [PlaceItem] {
        let cutoff = selectedMonthEndDate
        let groupFiltered = filterPlacesByGroup(places)
        return groupFiltered.filter { $0.arrivalAt <= cutoff }
    }

    var body: some View {
        MapReader { mapProxy in
            ZStack {
                Map(position: $mapPosition) {
                    if showsUserLocation {
                        UserAnnotation()
                    }

                    ForEach(visiblePlaces, id: \.id) { place in
                        Annotation(truncatedPlaceTitle(place.name), coordinate: place.coordinate) {
                            Button(action: {
                                navigationManager.navigate(to: .placeDetail(id: place.id))
                            }) {
                                PlaceMarkerView(iconName: place.mapIconName, fallbackColor: .red, size: 22)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .mapStyle(.standard)
                .simultaneousGesture(addPlaceGesture(mapProxy: mapProxy))
                .task {
                    await updateMapToFitPlaces()
                }

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
                                    await singleLocation()
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
                            navigationManager.navigate(to: .guide(groupId: selectedGroupId))
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
                                Task {
                                    await markCurrentLocation()
                                }
                            }) {
                                Label("标记当前位置", systemImage: "mappin")
                            }
                            .disabled(isSavingCurrentLocation)
                            Divider()
                            Button(action: {
                                isShowingAddGuideSheet = true
                            }) {
                                Label("添加指南", systemImage: "folder.badge.plus")
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
                if isAddingPlace {
                    AddPlaceLoadingOverlay(text: "正在添加地点…")
                }
            }
            .overlay(alignment: .top) {
                groupFilterBar
                    .safeAreaPadding(.top, 6)
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
        .sheet(isPresented: $isShowingAddGuideSheet) {
            AddGuideSheet { group in
                selectedGroupId = group.id
            }
        }
    }
    
    /// 单次定位
    @MainActor
    func singleLocation() async  {
        isSingleLocation = true
        defer { isSingleLocation = false }

        do {
            guard let location = try await fetchCurrentLocation() else {
                return
            }
            showsUserLocation = true
            let result = """
            单次定位成功:
            系统坐标(WGS84):
            - 纬度: \(location.coordinate.latitude)
            - 经度: \(location.coordinate.longitude)

            定位精度: \(String(format: "%.0f米", location.horizontalAccuracy))
            时间: \(Date().formatted())
            """
            
            print(result)
            
            // 移动地图相机到定位坐标，zoom 15 (约1200米)
            let coordinate = location.coordinate
            // Zoom 15 约对应 0.01 度的跨度 (约1200米)
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            let region = MKCoordinateRegion(center: coordinate, span: span)
            mapPosition = .region(region)
        } catch {
            print("定位失败: \(error.localizedDescription)")
        }
    }

    /// 标记当前位置并保存为地点
    @MainActor
    private func markCurrentLocation() async {
        guard !isSavingCurrentLocation else { return }
        isSavingCurrentLocation = true
        isAddingPlace = true
        defer { isSavingCurrentLocation = false }
        defer { isAddingPlace = false }

        do {
            guard let location = try await fetchCurrentLocation() else {
                return
            }
            showsUserLocation = true

            let mapItem = await reverseGeocode(location: location)
            let place = mapItem.map { PlaceItem(mapItem: $0) } ?? PlaceItem(location: location)

            insertPlaceAndAttachToGuide(place)

            moveMap(to: place.coordinate)
        } catch {
            print("标记当前位置失败: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func updateMapToFitPlaces() async {
        let placesToFit = visiblePlaces
        guard !placesToFit.isEmpty else { return }

        if placesToFit.count == 1, let place = placesToFit.first {
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            let region = MKCoordinateRegion(center: place.coordinate, span: span)
            mapPosition = .region(region)
            return
        }

        var minLat = Double.greatestFiniteMagnitude
        var maxLat = -Double.greatestFiniteMagnitude
        var minLon = Double.greatestFiniteMagnitude
        var maxLon = -Double.greatestFiniteMagnitude

        for place in placesToFit {
            minLat = min(minLat, place.latitude)
            maxLat = max(maxLat, place.latitude)
            minLon = min(minLon, place.longitude)
            maxLon = max(maxLon, place.longitude)
        }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2.0,
            longitude: (minLon + maxLon) / 2.0
        )
        let latDelta = max(0.01, (maxLat - minLat) * 1.2)
        let lonDelta = max(0.01, (maxLon - minLon) * 1.2)

        let region = MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
        mapPosition = .region(region)
    }

    private var selectedMonthEndDate: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: timelineState.selectedDate)
        let startOfMonth = calendar.date(from: components) ?? timelineState.selectedDate
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) ?? startOfMonth
        return calendar.date(byAdding: .second, value: -1, to: nextMonth) ?? timelineState.selectedDate
    }

    @ViewBuilder
    private var groupFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 10) {
                groupFilterButton(title: "全部", isSelected: selectedGroupId == nil) {
                    selectedGroupId = nil
                }
                ForEach(groups, id: \.id) { group in
                    groupFilterButton(title: group.name, isSelected: selectedGroupId == group.id) {
                        selectedGroupId = group.id
                    }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: 68, alignment: .leading)
    }

    @ViewBuilder
    private func groupFilterButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(minHeight: 32)
        }
        .background {
            if isSelected {
                Capsule()
                    .fill(Color.blue)
            }
        }
        .glassEffect(.regular, in: Capsule())
        .buttonStyle(.plain)
    }

    private func filterPlacesByGroup(_ source: [PlaceItem]) -> [PlaceItem] {
        guard let selectedGroupId else {
            return source
        }
        let groupPlaceIds = Set(
            groupPlaceLinks
                .filter { $0.group?.id == selectedGroupId }
                .compactMap { $0.place?.id }
        )
        guard !groupPlaceIds.isEmpty else { return [] }
        return source.filter { groupPlaceIds.contains($0.id) }
    }

    private func truncatedPlaceTitle(_ name: String?) -> String {
        let fallback = "已保存地点"
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let displayName = trimmed.isEmpty ? fallback : trimmed
        let maxCount = 8
        let characters = Array(displayName)
        guard characters.count > maxCount else { return displayName }
        return String(characters.prefix(maxCount)) + "..."
    }

    @MainActor
    private func attachPlaceToSelectedGuide(_ place: PlaceItem) {
        guard let selectedGroupId,
              let group = resolveGroup(for: selectedGroupId) else {
            return
        }
        if groupPlaceLinks.contains(where: { $0.group?.id == selectedGroupId && $0.place?.id == place.id }) {
            return
        }
        let link = GroupPlaceLink(group: group, place: place)
        modelContext.insert(link)
    }

    @MainActor
    private func resolveGroup(for id: UUID) -> GroupItem? {
        if let existing = groups.first(where: { $0.id == id }) {
            return existing
        }
        let descriptor = FetchDescriptor<GroupItem>(
            predicate: #Predicate<GroupItem> { $0.id == id }
        )
        return try? modelContext.fetch(descriptor).first
    }

    @MainActor
    private func insertPlaceAndAttachToGuide(_ place: PlaceItem) {
        modelContext.insert(place)
        attachPlaceToSelectedGuide(place)
        modelContext.processPendingChanges()
    }

    @MainActor
    private func moveMap(to coordinate: CLLocationCoordinate2D) {
        let span = currentMapSpan ?? MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapPosition = .region(region)
    }

    private var currentMapSpan: MKCoordinateSpan? {
        mapPosition.region?.span
    }

    private func fetchCurrentLocation() async throws -> CLLocation? {
        let hasPermission = await LocationUtil.checkAndRequestPermission()
        guard hasPermission else {
            print("权限不足，无法获取当前位置")
            return nil
        }

        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyBest

        let location = try await withCheckedThrowingContinuation { continuation in
            let delegate = LocationDelegate(continuation: continuation)
            manager.delegate = delegate
            objc_setAssociatedObject(manager, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            manager.requestLocation()
        }
        return location
    }

    private func reverseGeocode(location: CLLocation) async -> MKMapItem? {
        guard let request = MKReverseGeocodingRequest(location: location) else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            request.getMapItems(completionHandler: { mapItems, error in
                if let error {
                    print("反向地理编码失败: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: mapItems?.first)
            })
        }
    }

    private func addPlaceGesture(mapProxy: MapProxy) -> some Gesture {
        LongPressGesture(minimumDuration: 0.6)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
            .onEnded { value in
                guard case .second(true, let drag?) = value else { return }
                guard let coordinate = mapProxy.convert(drag.location, from: .local) else { return }
                Task {
                    await addPlace(at: coordinate)
                }
            }
    }

    @MainActor
    private func addPlace(at coordinate: CLLocationCoordinate2D) async {
        isAddingPlace = true
        defer { isAddingPlace = false }
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let mapItem = await reverseGeocode(location: location)
        let place = mapItem.map { PlaceItem(mapItem: $0) } ?? PlaceItem(location: location)
        insertPlaceAndAttachToGuide(place)
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
                let newLine = """
                新位置:
                WGS84: \(String(format: "%.6f", location.coordinate.latitude)), \(String(format: "%.6f", location.coordinate.longitude))
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

private struct AddGuideSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isNameFocused: Bool

    @State private var name: String = ""

    let onCreate: (GroupItem) -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("指南名称")
                    .font(.headline)
                TextField("请输入名称", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .focused($isNameFocused)
            }
            .padding()
            .navigationTitle("新建指南")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        save()
                    }
                    .disabled(!isSaveEnabled)
                }
            }
            .presentationDetents([.height(220)])
            .presentationDragIndicator(.visible)
            .onAppear {
                isNameFocused = true
            }
        }
    }

    private var isSaveEnabled: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let group = GroupItem(name: trimmed)
        modelContext.insert(group)
        onCreate(group)
        dismiss()
    }
}

private struct AddPlaceLoadingOverlay: View {
    let text: String

    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                ProgressView()
                Text(text)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        }
        .transition(.opacity)
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

// MARK: - Marker 数据模型和视图

/// 不可拖动的 Marker 视图
struct PlaceMarkerView: View {
    let iconName: String?
    let fallbackColor: Color
    let size: CGFloat

    var body: some View {
        if let iconName, MapIconCatalog.all.contains(iconName) {
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .padding(4)
                .background {
                    Circle()
                        .fill(.white)
                }
                .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
        } else {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: size))
                .foregroundStyle(fallbackColor)
                .background {
                    Circle()
                        .fill(.white)
                        .frame(width: size - 2, height: size - 2)
                }
                .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 2)
        }
    }
}

#Preview {
    NavigationStack {
        MapPage()
            .environment(NavigationManager())
    }
}
