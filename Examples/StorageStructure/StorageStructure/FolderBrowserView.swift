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
    @State private var treeNodes: [TreeNode] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Toolbar
                HStack(spacing: 12) {
                    Button(action: {
                        viewModel.openStorageFolder()
                    }) {
                        Label("Open in Finder", systemImage: "folder")
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: {
                        refreshTree()
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

                // Tree view
                if treeNodes.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)

                        Text("Storage is empty")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Load images from Configuration tab")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(treeNodes) { node in
                                TreeNodeView(node: node, level: 0, viewModel: viewModel)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Folder Browser")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            refreshTree()
        }
    }

    private func refreshTree() {
        treeNodes = viewModel.buildFileTree()
        viewModel.updateStorageInfo()
    }
}

struct TreeNodeView: View {
    let node: TreeNode
    let level: Int
    let viewModel: StorageViewModel
    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Node row
            HStack(spacing: 8) {
                // Indentation
                if level > 0 {
                    ForEach(0..<level, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 1)
                            .padding(.leading, 12)
                    }
                }

                // Expand/collapse button for folders
                if node.isDirectory && !node.children.isEmpty {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(width: 20)
                    }
                } else if node.isDirectory {
                    Spacer()
                        .frame(width: 20)
                } else {
                    Spacer()
                        .frame(width: 20)
                }

                // Icon
                Image(systemName: node.isDirectory ? "folder.fill" : "doc.fill")
                    .font(.body)
                    .foregroundColor(node.isDirectory ? .blue : .green)

                // Name
                Text(node.name)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.primary)

                Spacer()

                // Size for files
                if !node.isDirectory {
                    Text(node.sizeString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(Color.clear)
            .contentShape(Rectangle())
            .onTapGesture {
                if node.isDirectory {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }
            }

            // Children
            if node.isDirectory && isExpanded {
                ForEach(node.children) { child in
                    TreeNodeView(node: child, level: level + 1, viewModel: viewModel)
                }
            }
        }
    }
}

#Preview {
    FolderBrowserView(viewModel: StorageViewModel())
}
