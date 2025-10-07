//
//  URLInputSheet.swift
//  SwiftUIExample
//
//  Created by ductd on 7/10/25.
//

import SwiftUI

struct URLInputSheet: View {
    @Binding var url: String
    var onSubmit: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Enter Image URL")
                    .font(.headline)

                TextField("https://example.com/image.jpg", text: $url)
                    .textFieldStyle(.roundedBorder)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()

                // Quick presets
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Presets:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("Random 400x600") {
                        url = "https://picsum.photos/400/600"
                    }
                    .buttonStyle(.bordered)

                    Button("Random 800x600") {
                        url = "https://picsum.photos/800/600"
                    }
                    .buttonStyle(.bordered)

                    Button("Specific Dog Image") {
                        url = "https://picsum.photos/id/237/400/400"
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                Button(action: {
                    onSubmit()
                }) {
                    Text("Load URL")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Custom URL")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
