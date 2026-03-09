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
    @AppStorage("hideRoutesOnMap") private var hideRoutesOnMap: Bool = false
    @State private var isShowingAddGuideSheet: Bool = false
    @State private var isShowingGroupPicker: Bool = false
    @State private var isShowingGuideSheet: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isProcessingPhotoLocation: Bool = false
    @State private var activeAlert: ActiveAlert?
    @State private var isShowingPhotosPicker: Bool = false
    @State private var photoProcessingToken = UUID()
    @State private var didInitialMapFit: Bool = false
    @State private var isRouteSelectionMode: Bool = false
    @State private var routeSelectionPoints: [CLLocationCoordinate2D] = []
    @State private var isShowingRouteNameInput: Bool = false
    @State private var routeNameInput: String = ""
    @State private var placeDetailItem: DetailSheetItem?
    @State private var routeDetailItem: DetailSheetItem?
    @Environment(NavigationManager.self) private var navigationManager
    @Environment(\.modelContext) private var modelContext
    @Query private var places: [PlaceItem]
    @Query private var routes: [RouteItem]
    @Query(sort: \GroupItem.createdAt, order: .forward) private var groups: [GroupItem]
    @Query private var groupPlaceLinks: [GroupPlaceLink]
    @Query private var groupRouteLinks: [GroupRouteLink]

    private var visiblePlaces: [PlaceItem] {
        let cutoff = selectedMonthEndDate
        let groupFiltered = filterPlacesByGroup(places)
        return groupFiltered.filter { $0.arrivalAt <= cutoff }
    }

    private var visibleRoutes: [RouteItem] {
        let cutoff = selectedMonthEndDate
        let groupFiltered = filterRoutesByGroup(routes)
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
                                guard !isRouteSelectionMode else { return }
                                placeDetailItem = DetailSheetItem(id: place.id, groupId: selectedGroupId)
                            }) {
                                PlaceMarkerView(iconName: place.mapIconName, fallbackColor: .red, size: 26)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if !hideRoutesOnMap {
                        ForEach(visibleRoutes.filter { $0.sortedPoints.count >= 2 }, id: \.id) { route in
                            MapPolyline(coordinates: route.sortedPoints.map(\.coordinate))
                                .stroke(.blue, lineWidth: 3)
                            Annotation(route.name ?? "", coordinate: routeMidPoint(route), anchor: .bottom) {
                                Button(action: {
                                    guard !isRouteSelectionMode else { return }
                                    routeDetailItem = DetailSheetItem(id: route.id, groupId: selectedGroupId)
                                }) {
                                    Text(route.name ?? "路线")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.blue, in: Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if isRouteSelectionMode {
                        if routeSelectionPoints.count >= 2 {
                            MapPolyline(coordinates: routeSelectionPoints)
                                .stroke(.orange, lineWidth: 3)
                        }
                        ForEach(Array(routeSelectionPoints.enumerated()), id: \.offset) { index, point in
                            Annotation("", coordinate: point) {
                                ZStack {
                                    Circle()
                                        .fill(.orange)
                                        .frame(width: 16, height: 16)
                                    Circle()
                                        .stroke(.white, lineWidth: 2)
                                        .frame(width: 16, height: 16)
                                    Text("\(index + 1)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }
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
                .simultaneousGesture(
                    SpatialTapGesture()
                        .onEnded { value in
                            guard isRouteSelectionMode else { return }
                            guard let coordinate = mapProxy.convert(value.location, from: .local) else { return }
                            routeSelectionPoints.append(coordinate)
                        }
                )
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
                                withAnimation {
                                    hideRoutesOnMap.toggle()
                                }
                            }) {
                                Image(systemName: hideRoutesOnMap ? "eye.slash" : "eye")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(hideRoutesOnMap ? .secondary : .primary)
                                    .frame(width: 40, height: 40)
                                    .contentShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .glassEffect(.regular, in: Circle())

                            Button(action: {
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
                            
                            if !isRouteSelectionMode {
                                Button(action: {
                                    withAnimation {
                                        isRouteSelectionMode = true
                                        routeSelectionPoints = []
                                        routeNameInput = ""
                                    }
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
                        }
                        .padding(.trailing, 10)
                    }
                    .padding(.bottom)
                    if isRouteSelectionMode {
                        RouteSelectionBar(
                            pointCount: routeSelectionPoints.count,
                            totalDistance: routeSelectionTotalDistance,
                            onUndo: undoLastRoutePoint
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    } else {
                        HStack(spacing: 16) {
                            Button(action: {
                                isShowingGuideSheet = true
                            }) {
                                Image(systemName: "tray")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundStyle(.primary)
                                    .frame(width: 50, height: 50)
                                    .contentShape(Circle())
                            }
                            .buttonStyle(.plain)
                            .glassEffect(.regular, in: Circle())
                            
                            TimelineScrollBar(state: timelineState)
                            
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
        .alert("保存路线", isPresented: $isShowingRouteNameInput) {
            TextField("路线名称", text: $routeNameInput)
            Button("取消", role: .cancel) { }
            Button("保存") {
                saveRoute()
            }
        } message: {
            Text("请输入路线名称")
        }
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarLeading) {
                if isRouteSelectionMode {
                    Button("取消") {
                        exitRouteSelectionMode()
                    }
                } else {
                    Button(action: {
                        navigationManager.navigate(to: .user)
                    }) {
                        Label("User", systemImage: "person")
                    }
                }
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if isRouteSelectionMode {
                    Button("保存") {
                        routeNameInput = "新路线\(routes.count + 1)"
                        isShowingRouteNameInput = true
                    }
                    .disabled(routeSelectionPoints.count < 2)
                } else {
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
            }
            #endif
        }
        .sheet(item: $placeDetailItem) { item in
            NavigationStack {
                PlaceDetailPage(placeId: item.id, groupId: item.groupId)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $routeDetailItem) { item in
            NavigationStack {
                RouteDetailPage(routeId: item.id, groupId: item.groupId)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $isShowingGuideSheet) {
            NavigationStack {
                GuidePage(groupId: selectedGroupId)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
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
    
    // MARK: - 路线选择

    private var routeSelectionTotalDistance: Double {
        guard routeSelectionPoints.count >= 2 else { return 0 }
        var total: Double = 0
        for i in 1..<routeSelectionPoints.count {
            let prev = CLLocation(
                latitude: routeSelectionPoints[i - 1].latitude,
                longitude: routeSelectionPoints[i - 1].longitude
            )
            let curr = CLLocation(
                latitude: routeSelectionPoints[i].latitude,
                longitude: routeSelectionPoints[i].longitude
            )
            total += prev.distance(from: curr)
        }
        return total
    }

    private func undoLastRoutePoint() {
        guard !routeSelectionPoints.isEmpty else { return }
        routeSelectionPoints.removeLast()
    }

    private func exitRouteSelectionMode() {
        withAnimation {
            isRouteSelectionMode = false
            routeSelectionPoints = []
            routeNameInput = ""
        }
    }

    @MainActor
    private func saveRoute() {
        guard routeSelectionPoints.count >= 2 else { return }

        let name = routeNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = name.isEmpty ? "新路线\(routes.count + 1)" : name

        let route = RouteItem(
            name: finalName,
            sourceTypeRaw: RouteSourceType.planned.rawValue,
            geometryTypeRaw: RouteGeometryType.straightLine.rawValue,
            distanceMeters: routeSelectionTotalDistance,
            startLatitude: routeSelectionPoints.first?.latitude,
            startLongitude: routeSelectionPoints.first?.longitude,
            endLatitude: routeSelectionPoints.last?.latitude,
            endLongitude: routeSelectionPoints.last?.longitude
        )

        route.points = routeSelectionPoints.enumerated().map { index, coord in
            RoutePoint(index: index, latitude: coord.latitude, longitude: coord.longitude)
        }

        modelContext.insert(route)

        if let selectedGroupId, let group = resolveGroup(for: selectedGroupId) {
            let link = GroupRouteLink(group: group, route: route)
            modelContext.insert(link)
        }

        modelContext.processPendingChanges()
        exitRouteSelectionMode()
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

    private func filterRoutesByGroup(_ source: [RouteItem]) -> [RouteItem] {
        guard let selectedGroupId else {
            return source
        }
        let groupRouteIds = Set(
            groupRouteLinks
                .filter { $0.group?.id == selectedGroupId }
                .compactMap { $0.route?.id }
        )
        guard !groupRouteIds.isEmpty else { return [] }
        return source.filter { groupRouteIds.contains($0.id) }
    }

    private func routeMidPoint(_ route: RouteItem) -> CLLocationCoordinate2D {
        let points = route.sortedPoints
        guard !points.isEmpty else {
            return CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }
        return points[points.count / 2].coordinate
    }

    private func updateTimelineStartDate() {
        let minPlaceArrivalAt = places.map(\.arrivalAt).min()
        let minRouteArrivalAt = routes.map(\.arrivalAt).min()
        let minArrivalAt = [minPlaceArrivalAt, minRouteArrivalAt].compactMap { $0 }.min()
        timelineState.updateStartDate(minArrivalAt: minArrivalAt)
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
                guard !isRouteSelectionMode else { return }
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
        moveMap(to: coordinate)

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

private struct RouteSelectionBar: View {
    let pointCount: Int
    let totalDistance: Double
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "map")
                .font(.system(size: 18))
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("总里程")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(formattedDistance)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            Spacer()

            Text("\(pointCount) 个点")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)

            Button(action: onUndo) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(pointCount == 0 ? .secondary : .primary)
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .glassEffect(.regular, in: Circle())
            .disabled(pointCount == 0)
            .opacity(pointCount == 0 ? 0.4 : 1.0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 25))
    }

    private var formattedDistance: String {
        if totalDistance >= 1000 {
            return String(format: "%.2f km", totalDistance / 1000)
        } else {
            return String(format: "%.0f m", totalDistance)
        }
    }
}

struct DetailSheetItem: Identifiable {
    let id: UUID
    let groupId: UUID?
}

#Preview {
    NavigationStack {
        MapPage()
            .environment(NavigationManager())
    }
}
