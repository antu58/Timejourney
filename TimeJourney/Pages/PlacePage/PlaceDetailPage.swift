//
//  PlaceDetailPage.swift
//  TimeJourney
//
//  Created by Codex on 2026/02/05.
//

import SwiftUI
import SwiftData

struct PlaceDetailPage: View {
    let placeId: UUID

    @Query private var places: [PlaceItem]
    @State private var isShowingAddContent = false
    @State private var isShowingIconPicker = false

    init(placeId: UUID) {
        self.placeId = placeId
        _places = Query(filter: #Predicate<PlaceItem> { $0.id == placeId })
    }

    var body: some View {
        if let place = places.first {
            Form {
                Section("地点信息") {
                    infoRow(title: "名称", value: place.name)
                    infoRow(title: "地址", value: place.addressFull ?? place.addressShort)
                    infoRow(title: "城市", value: place.addressCityWithContext ?? place.addressCityName)
                    infoRow(title: "地区", value: place.addressRegionName)
                    infoRow(title: "坐标", value: String(format: "%.6f, %.6f", place.latitude, place.longitude))
                    infoRow(title: "精度", value: place.horizontalAccuracy.map { String(format: "%.0f米", $0) })
                    infoRow(title: "创建时间", value: formattedDate(place.createdAt))
                }

                Section("到达时间") {
                    DatePicker(
                        "到达时间",
                        selection: Binding(
                            get: { place.arrivalAt },
                            set: { place.arrivalAt = $0 }
                        ),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Section("图标") {
                    HStack {
                        Text("当前图标")
                            .foregroundStyle(.secondary)
                        Spacer()
                        PlaceMarkerView(iconName: place.mapIconName, fallbackColor: .red, size: 28)
                    }
                    Button("选择图标") {
                        isShowingIconPicker = true
                    }
                }

                Section("内容") {
                    let contents = place.contents.sorted { $0.createdAt > $1.createdAt }
                    if contents.isEmpty {
                        Text("暂无内容")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(contents, id: \.id) { content in
                            ContentRow(content: content)
                        }
                    }
                }
            }
            .navigationTitle(place.name ?? "地点详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("添加内容") {
                        isShowingAddContent = true
                    }
                }
            }
            .sheet(isPresented: $isShowingAddContent) {
                AddContentSheet(place: place)
            }
            .sheet(isPresented: $isShowingIconPicker) {
                IconPickerSheet(
                    selectedIconName: place.mapIconName,
                    onSelect: { selected in
                        place.mapIconName = selected
                    }
                )
            }
        } else {
            ProgressView("加载中...")
        }
    }

    @ViewBuilder
    private func infoRow(title: String, value: String?) -> some View {
        if let value, !value.isEmpty {
            HStack(alignment: .top) {
                Text(title)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

private struct IconPickerSheet: View {
    let selectedIconName: String?
    let onSelect: (String?) -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.adaptive(minimum: 56), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    iconCell(
                        iconName: nil,
                        isSelected: selectedIconName == nil
                    )
                    ForEach(MapIconCatalog.all, id: \.self) { icon in
                        iconCell(
                            iconName: icon,
                            isSelected: selectedIconName == icon
                        )
                    }
                }
                .padding(16)
            }
            .navigationTitle("选择图标")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func iconCell(iconName: String?, isSelected: Bool) -> some View {
        Button(action: {
            onSelect(iconName)
            dismiss()
        }) {
            ZStack {
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)

                if let iconName {
                    Image(iconName)
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                } else {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                }

                if isSelected {
                    Circle()
                        .stroke(Color.blue, lineWidth: 3)
                }
            }
            .frame(width: 56, height: 56)
        }
        .buttonStyle(.plain)
    }
}

private struct ContentRow: View {
    let content: ContentItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(content.type.rawValue.uppercased())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let title = content.title, !title.isEmpty {
                    Text(title)
                        .font(.headline)
                }
            }

            if let summary = summaryText, !summary.isEmpty {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 6)
    }

    private var summaryText: String? {
        switch content.type {
        case .text:
            return content.text
        case .url:
            return content.url?.absoluteString
        case .image, .video, .audio, .file:
            return content.fileName ?? content.filePath
        }
    }
}

private struct AddContentSheet: View {
    let place: PlaceItem

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var type: ContentType = .text
    @State private var title: String = ""
    @State private var note: String = ""
    @State private var text: String = ""
    @State private var urlString: String = ""
    @State private var filePath: String = ""
    @State private var fileName: String = ""
    @State private var mimeType: String = ""
    @State private var fileSizeBytes: String = ""
    @State private var duration: String = ""
    @State private var width: String = ""
    @State private var height: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("内容类型") {
                    Picker("类型", selection: $type) {
                        Text("文字").tag(ContentType.text)
                        Text("链接").tag(ContentType.url)
                        Text("图片").tag(ContentType.image)
                        Text("视频").tag(ContentType.video)
                        Text("音频").tag(ContentType.audio)
                        Text("文件").tag(ContentType.file)
                    }
                    .pickerStyle(.segmented)
                }

                Section("基础信息") {
                    TextField("标题", text: $title)
                    TextField("备注", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section(contentSectionTitle) {
                    if type == .text {
                        TextField("内容", text: $text, axis: .vertical)
                            .lineLimit(4...8)
                    }

                    if type == .url {
                        TextField("URL", text: $urlString)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    if isFileType {
                        TextField("文件路径（沙箱内）", text: $filePath)
                        TextField("文件名", text: $fileName)
                        TextField("MIME 类型", text: $mimeType)
                        TextField("文件大小（字节）", text: $fileSizeBytes)
                            .keyboardType(.numberPad)
                    }

                    if type == .image || type == .video {
                        TextField("宽度（像素）", text: $width)
                            .keyboardType(.decimalPad)
                        TextField("高度（像素）", text: $height)
                            .keyboardType(.decimalPad)
                    }

                    if type == .video || type == .audio {
                        TextField("时长（秒）", text: $duration)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle("添加内容")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveContent()
                    }
                    .disabled(!isSaveEnabled)
                }
            }
        }
    }

    private var isFileType: Bool {
        switch type {
        case .image, .video, .audio, .file:
            return true
        default:
            return false
        }
    }

    private var contentSectionTitle: String {
        switch type {
        case .text:
            return "文字内容"
        case .url:
            return "链接内容"
        case .image:
            return "图片内容"
        case .video:
            return "视频内容"
        case .audio:
            return "音频内容"
        case .file:
            return "文件内容"
        }
    }

    private var isSaveEnabled: Bool {
        switch type {
        case .text:
            return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .url:
            return URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
        case .image, .video, .audio, .file:
            return !filePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func saveContent() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedFilePath = filePath.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedFileName = fileName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMimeType = mimeType.trimmingCharacters(in: .whitespacesAndNewlines)

        let content = ContentItem(
            typeRaw: type.rawValue,
            title: trimmedTitle.isEmpty ? nil : trimmedTitle,
            note: trimmedNote.isEmpty ? nil : trimmedNote,
            text: type == .text ? trimmedText : nil,
            url: type == .url ? URL(string: trimmedURL) : nil,
            filePath: isFileType ? (trimmedFilePath.isEmpty ? nil : trimmedFilePath) : nil,
            fileName: trimmedFileName.isEmpty ? nil : trimmedFileName,
            mimeType: trimmedMimeType.isEmpty ? nil : trimmedMimeType,
            fileSizeBytes: Int64(fileSizeBytes),
            duration: Double(duration),
            width: Double(width),
            height: Double(height),
            place: place
        )

        modelContext.insert(content)
        dismiss()
    }
}

#Preview {
    let sample = PlaceItem(
        name: "示例地点",
        addressFull: "1 Apple Park Way, Cupertino",
        latitude: 37.3349,
        longitude: -122.0090
    )
    return NavigationStack {
        PlaceDetailPage(placeId: sample.id)
    }
}
