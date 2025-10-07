
@available(iOS 15.0, *)
struct FileExplorerView: View {
    @ObservedObject var viewModel: StorageControlViewModel

    var body: some View {
        List {
            if viewModel.fileList.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "folder")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)

                    Text("No files in storage")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(viewModel.fileList) { file in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(file.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)

                        HStack {
                            Text(file.sizeString)
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Text(file.dateString)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("File Explorer")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.refreshStats()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .onAppear {
            viewModel.refreshStats()
        }
    }
}