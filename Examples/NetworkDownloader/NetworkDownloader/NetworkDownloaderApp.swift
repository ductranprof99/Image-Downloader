//
//  NetworkDownloaderApp.swift
//  NetworkDownloader
//
//  Created by ductd on 9/10/25.
//

import SwiftUI

@main
struct NetworkDownloaderApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                NetworkCustomDemoView()
                    .tabItem {
                        Label("Download Setting", systemImage: "network")
                    }
                
                NetworkRequestDemoView()
                    .tabItem {
                        Label("Multi Load", systemImage: "photo.on.rectangle")
                    }
            }
        }
    }
}
