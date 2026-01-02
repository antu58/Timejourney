//
//  UserPage.swift
//  TimeJourney
//
//  Created by 张峰 on 2026/1/2.
//

import SwiftUI

/// 用户页面 - 占位实现
struct UserPage: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 用户头像和基本信息
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.gray)

                    Text("用户昵称")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("user@example.com")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)

                // 统计信息
                HStack(spacing: 16) {
                    VStack {
                        Text("12")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("地点")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)

                    VStack {
                        Text("5")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("路线")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)

                    VStack {
                        Text("3")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("收藏")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)

                // 功能列表
                VStack(alignment: .leading, spacing: 8) {
                    Text("设置")
                        .font(.headline)
                        .padding(.horizontal)

                    Button(action: {
                        print("点击个人资料")
                    }) {
                        HStack {
                            Image(systemName: "person")
                                .frame(width: 24)
                            Text("个人资料")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        print("点击隐私设置")
                    }) {
                        HStack {
                            Image(systemName: "lock")
                                .frame(width: 24)
                            Text("隐私设置")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        print("点击通知设置")
                    }) {
                        HStack {
                            Image(systemName: "bell")
                                .frame(width: 24)
                            Text("通知设置")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                    }
                    .buttonStyle(.plain)
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)

                // 退出登录
                Button(action: {
                    print("点击退出登录")
                }) {
                    Text("退出登录")
                        .font(.headline)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("个人中心")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    print("点击设置")
                }) {
                    Image(systemName: "gear")
                }
            }
            #endif
        }
    }
}

#Preview {
    NavigationStack {
        UserPage()
    }
}