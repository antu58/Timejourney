//
//  SearchPage.swift
//  TimeJourney
//
//  Created by 张峰 on 2025/12/25.
//

import SwiftUI
import SwiftData

struct SearchPage: View {
    @State private var searchText = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("搜索地点、路线或指南", text: $searchText)
                    .textFieldStyle(.plain)

                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding()

            if searchText.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("热门搜索")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(["城市探索", "历史之旅", "美食路线", "观景台", "中央公园"], id: \.self) { tag in
                                Button(action: {
                                    searchText = tag
                                }) {
                                    Text(tag)
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundStyle(.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }

                    Text("搜索历史")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(["老街区", "海岸线", "艺术中心"], id: \.self) { history in
                            Button(action: {
                                searchText = history
                            }) {
                                HStack {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .foregroundStyle(.secondary)
                                    Text(history)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.systemBackground))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
                .padding(.top, 20)
            } else {
                VStack(spacing: 16) {
                    ForEach(1...5, id: \.self) { index in
                        HStack(spacing: 16) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.red)
                                .frame(width: 40, height: 40)
                                .background(Color.red.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("搜索结果 \(index)")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text("这是搜索结果的描述信息")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }

            Spacer()
        }
        .navigationTitle("搜索")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Text("清除")
                    }
                }
            }
            #endif
        }
    }
}

#Preview {
    NavigationStack {
        SearchPage()
    }
}
