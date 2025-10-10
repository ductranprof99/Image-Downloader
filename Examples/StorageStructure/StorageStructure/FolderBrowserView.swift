//
//  FolderBrowserView.swift
//  StorageStructure
//
//  Created by ductd on 9/10/25.
//

import SwiftUI
import ImageDownloader

struct FolderBrowserView: View {
    @ObservedObject var viewModel: StorageViewModel
    @State private var currentPath: String? = nil
    @State private var files: [FileItem] = []
    @State private var pathComponents: [String] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Breadcrumb navigation
                if !pathComponents.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button(action: {
                                navigateToRoot()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "house.fill")
                                    Text("Storage")
                                }
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }

                            ForEach(Array(pathComponents.enumerated()), id: \.offset) { index, component in
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundColor(.gray)

                                Button(action: {
                                    navigateTo(index: index)
                                }) {
                                    Text(component)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding()
                    }
                    .background(Color.gray.opacity(0.05))
                }

                // Toolbar
                HStack(spacing: 12) {
                    Button(action: {
                        viewModel.openStorageFolder()
                    }) {
                        Label("Open in Finder", systemImage: "folder")
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: {
                        refreshFiles()
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    if let info = viewModel.storageInfo {
                        Text("\(info.fileCount) items • \(info.sizeString)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()

                Divider()

                // File list
                if files.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("Folder is empty")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Load images from Configuration tab")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(files) { file in
                            FileRowView(file: file) {
                                if file.isDirectory {
                                    navigateInto(folder: file)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Folder Browser")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !pathComponents.isEmpty {
                        Button(action: {
                            navigateBack()
                        }) {
                            Image(systemName: "arrow.up")
                        }
                    }
                }
            }
        }
        .onAppear {
            refreshFiles()
        }
    }

    private func refreshFiles() {
        files = viewModel.listFiles(at: currentPath)
        viewModel.updateStorageInfo()
    }

    private func navigateInto(folder: FileItem) {
        currentPath = folder.relativePath
        pathComponents.append(folder.name)
        refreshFiles()
    }

    private func navigateBack() {
        guard !pathComponents.isEmpty else { return }
        pathComponents.removeLast()

        if pathComponents.isEmpty {
            currentPath = nil
        } else {
            currentPath = pathComponents.joined(separator: "/")
        }
        refreshFiles()
    }

    private func navigateToRoot() {
        currentPath = nil
        pathComponents.removeAll()
        refreshFiles()
    }

    private func navigateTo(index: Int) {
        pathComponents = Array(pathComponents.prefix(index + 1))
        currentPath = pathComponents.joined(separator: "/")
        refreshFiles()
    }
}

struct FileRowView: View {
    let file: FileItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: file.isDirectory ? "folder.fill" : "doc.fill")
                    .font(.title3)
                    .foregroundColor(file.isDirectory ? .blue : .green)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(file.name)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if !file.isDirectory {
                        Text(file.sizeString)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if file.isDirectory {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FolderBrowserView(viewModel: StorageViewModel())
}
