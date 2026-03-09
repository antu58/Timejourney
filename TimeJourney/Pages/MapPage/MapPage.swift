//
//  MapPage.swift
//  TimeJourney
//
//  Created by 张峰 on 2026/1/1.
//

import SwiftUI
import MapKit
import SwiftData
import PhotosUI
import Photos
import ImageIO

struct MapPage: View {

    @State private var mapPosition = MapCameraPosition.automatic
    @State private var timelineState = TimelineState()
    @State private var isSingleLocation: Bool = false
    @State private var isSavingCurrentLocation: Bool = false
    @State private var showsUserLocation: Bool = false
    @State private var selectedGroupId: UUID? = nil
    @AppStorage("lastSelectedGroupId") private var lastSelectedGroupId: String = ""
    @State private var isShowingAddGuideSheet: Bool = false
    @State private var isShowingGroupPicker: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isProcessingPhotoLocation: Bool = false
    @State private var activeAlert: ActiveAlert?
    @State private var isShowingPhotosPicker: Bool = false
    @State private var photoProcessingToken = UUID()
    @State private var didInitialMapFit: Bool = false
    @Environment(NavigationManager.self) private var navigationManager
    @Environment(\.modelContext) private var modelContext
    @Query private var places: [PlaceItem]
    @Query private var routes: [RouteItem]
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
                        Annotation(truncatedPlaceTitle(place.name), coordinate: place.coordinate, anchor: .bottom) {
                            Button(action: {
                                navigationManager.navigate(to: .placeDetail(id: place.id, groupId: selectedGroupId))
                            }) {
                                PlaceMarkerView(iconName: place.mapIconName, fallbackColor: .red, size: 24)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .mapStyle(
                    .standard(
                        elevation: .automatic,
                        emphasis: .muted,
                        pointsOfInterest: [],
                        showsTraffic: false
                    )
                )
                .simultaneousGesture(addPlaceGesture(mapProxy: mapProxy))
                .task {
                    if !didInitialMapFit, mapPosition.region == nil {
                        await updateMapToFitPlaces()
                        didInitialMapFit = true
                    }
                    updateTimelineStartDate()
                }
                .onChange(of: places.map(\.arrivalAt)) { _, _ in
                    updateTimelineStartDate()
                }
                .onChange(of: routes.map(\.arrivalAt)) { _, _ in
                    updateTimelineStartDate()
                }
                .onChange(of: selectedPhotoItem) { _, newItem in
                    guard let newItem else { return }
                    handlePhotoSelection(newItem)
                }
                .onChange(of: selectedGroupId) { _, newValue in
                    lastSelectedGroupId = newValue?.uuidString ?? ""
                }
                .task {
                    if selectedGroupId == nil, let id = UUID(uuidString: lastSelectedGroupId) {
                        selectedGroupId = id
                    }
                }

                VStack {
                    Spacer()
                    
                    // 底部控制栏
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Button(action: {
                                // 定位功能
                            Task {
                                await singleLocation()
                            }
                            }) {
                                Image(systemName: "location")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(isSingleLocation ? .secondary : .primary)
                                    .frame(width: 40, height: 40)
                                    .contentShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .disabled(isSingleLocation)
                            .glassEffect(.regular, in: Circle())
                            .opacity(isSingleLocation ? 0.5 : 1.0)
                            
                            Button(action: {
                                // TODO: 路线选择功能
                            }) {
                                Image(systemName: "hand.tap")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(.primary)
                                    .frame(width: 40, height: 40)
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
                                .frame(width: 50, height: 50)
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular, in: Circle())
                        
                        // 时间线滚动条
                        TimelineScrollBar(state: timelineState)
                        
                        // 添加按钮
                        Button(action: {
                            guard !isSavingCurrentLocation else { return }
                            activeAlert = ActiveAlert(
                                type: .saveCurrentLocationConfirm,
                                message: "将当前位置保存为新地点"
                            )
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.black)
                                .frame(width: 50, height: 50)
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .glassEffect(.regular, in: Circle())
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)

                }
            }
        }
        .photosPicker(isPresented: $isShowingPhotosPicker, selection: $selectedPhotoItem, matching: .images)
        .alert(item: $activeAlert) { alert in
            switch alert.type {
            case .photoLocationFailed:
                return Alert(
                    title: Text("无法识别照片位置"),
                    message: Text(alert.message ?? ""),
                    dismissButton: .cancel(Text("确定"))
                )
            case .locationPermission:
                return Alert(
                    title: Text("无法获取位置"),
                    message: Text(alert.message ?? ""),
                    dismissButton: .cancel(Text("确定"))
                )
            case .photoProcessing:
                return Alert(
                    title: Text("正在解析照片位置…"),
                    message: Text("请稍候"),
                    dismissButton: .cancel(Text("取消"), action: {
                        isProcessingPhotoLocation = false
                        activeAlert = nil
                    })
                )
            case .saveCurrentLocationConfirm:
                return Alert(
                    title: Text("确认保存当前位置"),
                    message: Text(alert.message ?? ""),
                    primaryButton: .default(Text("保存"), action: {
                        Task { @MainActor in
                            await addCurrentLocationPlaceholder()
                        }
                    }),
                    secondaryButton: .cancel(Text("取消"))
                )
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
                        isShowingGroupPicker = true
                    }) {
                        Label("更换指南", systemImage: "arrow.triangle.2.circlepath")
                    }
                    Divider()
                    Button(action: {
                        Task { @MainActor in
                            addSamplePlaces()
                        }
                    }) {
                        Label("生成测试地点", systemImage: "sparkles")
                    }
                    Divider()
                    Button(action: {
                        Task { @MainActor in
                            await requestPhotoAccessAndPresentPicker()
                        }
                    }) {
                        Label("获取照片位置", systemImage: "photo")
                    }
                    Divider()
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
        .sheet(isPresented: $isShowingGroupPicker) {
            GroupPickerSheet(
                groups: groups,
                selectedGroupId: $selectedGroupId
            )
        }
    }
    
    /// 单次定位
    @MainActor
    func singleLocation() async  {
        isSingleLocation = true
        defer {
            isSingleLocation = false
        }

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
            let coordinate = CoordinateConverter.convertIfNeeded(location.coordinate)
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
        guard !isSavingCurrentLocation else {
            return
        }
        isSavingCurrentLocation = true
        defer {
            isSavingCurrentLocation = false
        }

        do {
            guard let location = try await fetchCurrentLocation() else {
                return
            }
            showsUserLocation = true

            let adjustedCoordinate = CoordinateConverter.convertIfNeeded(location.coordinate)
            let adjustedLocation = CLLocation(latitude: adjustedCoordinate.latitude, longitude: adjustedCoordinate.longitude)
            let mapItem = await reverseGeocode(location: adjustedLocation)
            let place = mapItem.map { PlaceItem(mapItem: $0) } ?? PlaceItem(location: adjustedLocation)
            place.mapIconName = "round_pushpin_round_pushpin_3d"

            insertPlaceAndAttachToGuide(place)

            moveMap(to: place.coordinate)
        } catch {
            print("标记当前位置失败: \(error.localizedDescription)")
        }
    }

    @MainActor
    private func addCurrentLocationPlaceholder() async {
        guard !isSavingCurrentLocation else {
            return
        }
        isSavingCurrentLocation = true
        defer {
            isSavingCurrentLocation = false
        }

        do {
            guard let location = try await fetchCurrentLocation() else {
                return
            }
            showsUserLocation = true

            let adjustedCoordinate = CoordinateConverter.convertIfNeeded(location.coordinate)
            let adjustedLocation = CLLocation(latitude: adjustedCoordinate.latitude, longitude: adjustedCoordinate.longitude)
            let place = PlaceItem(
                name: "新地点",
                addressFull: "未知",
                addressShort: "未知",
                latitude: adjustedCoordinate.latitude,
                longitude: adjustedCoordinate.longitude
            )
            place.arrivalAt = Date()
            place.mapIconName = "round_pushpin_round_pushpin_3d"
            insertPlaceAndAttachToGuide(place)
            moveMap(to: adjustedCoordinate)

            if let mapItem = await reverseGeocode(location: adjustedLocation) {
                applyMapItem(mapItem, to: place)
            }
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

    private func updateTimelineStartDate() {
        let minPlaceArrivalAt = places.map(\.arrivalAt).min()
        let minRouteArrivalAt = routes.map(\.arrivalAt).min()
        let minArrivalAt = [minPlaceArrivalAt, minRouteArrivalAt].compactMap { $0 }.min()
        timelineState.updateStartDate(minArrivalAt: minArrivalAt)
    }

    @MainActor
    private func addSamplePlaces() {
        let calendar = Calendar.current
        let now = Date()
        let samples: [(name: String, city: String, latitude: Double, longitude: Double, monthsAgo: Int)] = [
            ("天安门广场", "北京", 39.9087, 116.3975, 0),
            ("外滩", "上海", 31.2400, 121.4900, 1),
            ("兵马俑", "西安", 34.3849, 109.2733, 2),
            ("漓江", "桂林", 25.2736, 110.2900, 3),
            ("峨眉山", "乐山", 29.5170, 103.3310, 4),
            ("张家界国家森林公园", "张家界", 29.3300, 110.4790, 5),
            ("西湖", "杭州", 30.2431, 120.1500, 6),
            ("布达拉宫", "拉萨", 29.6577, 91.1175, 7),
            ("鼓浪屿", "厦门", 24.4510, 118.0660, 8),
            ("九寨沟", "阿坝", 33.2520, 103.9180, 9),
            ("黄山", "黄山", 30.1340, 118.1660, 10),
            ("武陵源", "张家界", 29.3570, 110.5500, 11)
        ]

        for sample in samples {
            let arrivalAt = calendar.date(byAdding: .month, value: -sample.monthsAgo, to: now) ?? now
            let place = PlaceItem(
                createdAt: arrivalAt,
                name: sample.name,
                addressShort: sample.city,
                addressCityName: sample.city,
                latitude: sample.latitude,
                longitude: sample.longitude,
                arrivalAt: arrivalAt
            )
            place.mapIconName = "round_pushpin_round_pushpin_3d"
            insertPlaceAndAttachToGuide(place)
        }
        modelContext.processPendingChanges()
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
        timelineState.scrollToNow()
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

    @MainActor
    private func fetchCurrentLocation() async throws -> CLLocation? {
        let hasPermission = await LocationUtil.checkAndRequestPermission()
        guard hasPermission else {
            activeAlert = ActiveAlert(type: .locationPermission, message: "没有位置权限，无法保存地点")
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
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let place = PlaceItem(
            name: "新地点",
            addressFull: "未知",
            addressShort: "未知",
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        place.arrivalAt = Date()
        place.mapIconName = "round_pushpin_round_pushpin_3d"
        insertPlaceAndAttachToGuide(place)

        if let mapItem = await reverseGeocode(location: location) {
            applyMapItem(mapItem, to: place)
        }
    }

    @MainActor
    private func handlePhotoSelection(_ item: PhotosPickerItem) {
        guard !isProcessingPhotoLocation else { return }
        let token = UUID()
        photoProcessingToken = token
        isProcessingPhotoLocation = true
        activeAlert = ActiveAlert(type: .photoProcessing, message: nil)
        Task {
            defer {
                Task { @MainActor in
                    isProcessingPhotoLocation = false
                    selectedPhotoItem = nil
                    if activeAlert?.type == .photoProcessing {
                        activeAlert = nil
                    }
                }
            }

            Task {
                try? await Task.sleep(for: .seconds(60))
                await MainActor.run {
                    guard isProcessingPhotoLocation, photoProcessingToken == token else { return }
                    activeAlert = ActiveAlert(type: .photoLocationFailed, message: "解析超时，请稍后重试")
                    isProcessingPhotoLocation = false
                }
            }

            guard let data = try? await item.loadTransferable(type: Data.self),
                  let coordinate = extractCoordinate(from: data) else {
                await MainActor.run {
                    activeAlert = ActiveAlert(type: .photoLocationFailed, message: "未能识别照片中的位置信息")
                }
                return
            }

            let adjustedCoordinate = CoordinateConverter.convertIfNeeded(coordinate)
            guard isProcessingPhotoLocation, photoProcessingToken == token else { return }
            await addPlaceFromPhoto(coordinate: adjustedCoordinate)
        }
    }

    @MainActor
    private func addPlaceFromPhoto(coordinate: CLLocationCoordinate2D) async {
        let adjustedCoordinate = CoordinateConverter.convertIfNeeded(coordinate)
        let location = CLLocation(latitude: adjustedCoordinate.latitude, longitude: adjustedCoordinate.longitude)
        let place = PlaceItem(
            name: "新地点",
            addressFull: "未知",
            addressShort: "未知",
            latitude: adjustedCoordinate.latitude,
            longitude: adjustedCoordinate.longitude
        )
        place.arrivalAt = Date()
        place.mapIconName = "round_pushpin_round_pushpin_3d"
        insertPlaceAndAttachToGuide(place)
        moveMap(to: adjustedCoordinate)

        if let mapItem = await reverseGeocode(location: location) {
            applyMapItem(mapItem, to: place)
        }
    }

    @MainActor
    private func requestPhotoAccessAndPresentPicker() async {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        let resolved: PHAuthorizationStatus

        if status == .notDetermined {
            resolved = await withCheckedContinuation { continuation in
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                    continuation.resume(returning: newStatus)
                }
            }
        } else {
            resolved = status
        }

        switch resolved {
        case .authorized, .limited:
            isShowingPhotosPicker = true
        default:
            activeAlert = ActiveAlert(type: .photoLocationFailed, message: "没有照片权限，无法读取照片位置")
        }
    }

    private func extractCoordinate(from data: Data) -> CLLocationCoordinate2D? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any],
              let latitude = gps[kCGImagePropertyGPSLatitude] as? Double,
              let longitude = gps[kCGImagePropertyGPSLongitude] as? Double
        else {
            return nil
        }

        let latRef = gps[kCGImagePropertyGPSLatitudeRef] as? String
        let lonRef = gps[kCGImagePropertyGPSLongitudeRef] as? String
        let finalLat = (latRef == "S") ? -latitude : latitude
        let finalLon = (lonRef == "W") ? -longitude : longitude
        return CLLocationCoordinate2D(latitude: finalLat, longitude: finalLon)
    }

    private func applyMapItem(_ mapItem: MKMapItem, to place: PlaceItem) {
        let updated = PlaceItem(mapItem: mapItem)
        place.name = updated.name
        place.addressFull = updated.addressFull
        place.addressShort = updated.addressShort
        place.addressCityName = updated.addressCityName
        place.addressCityWithContext = updated.addressCityWithContext
        place.addressRegionName = updated.addressRegionName
        place.phoneNumber = updated.phoneNumber
        place.url = updated.url
        place.pointOfInterestCategory = updated.pointOfInterestCategory
        place.timeZoneIdentifier = updated.timeZoneIdentifier
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

private enum ActiveAlertType {
    case photoLocationFailed
    case locationPermission
    case photoProcessing
    case saveCurrentLocationConfirm
}

private struct ActiveAlert: Identifiable {
    let id = UUID()
    let type: ActiveAlertType
    let message: String?
}

struct AddGuideSheet: View {
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

private struct GroupPickerSheet: View {
    let groups: [GroupItem]
    @Binding var selectedGroupId: UUID?

    @Environment(\.dismiss) private var dismiss
    @State private var isShowingAddGuideSheet = false

    var body: some View {
        NavigationStack {
            List {
                groupRow(title: "全部", groupId: nil)
                ForEach(groups, id: \.id) { group in
                    groupRow(title: group.name, groupId: group.id)
                }
            }
            .navigationTitle("更换指南")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("新增") {
                        isShowingAddGuideSheet = true
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .sheet(isPresented: $isShowingAddGuideSheet) {
            AddGuideSheet { group in
                selectedGroupId = group.id
                dismiss()
            }
        }
    }

    @ViewBuilder
    private func groupRow(title: String, groupId: UUID?) -> some View {
        Button(action: {
            selectedGroupId = groupId
            dismiss()
        }) {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                if selectedGroupId == groupId {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.secondary)
                }
            }
        }
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
        } else {
            Image(systemName: "mappin")
                .font(.system(size: size * 0.9, weight: .semibold))
                .foregroundStyle(fallbackColor)
                .frame(width: size, height: size)
        }
    }
}

#Preview {
    NavigationStack {
        MapPage()
            .environment(NavigationManager())
    }
}
