//
//  SwiftUIExampleApp.swift
//  SwiftUIExample
//
//  Created by ductd on 7/10/25.
//

import SwiftUI

@main
struct SwiftUIExampleApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                StorageOnlyDemoView()
                    .tabItem {
                        Label("Storage Only", systemImage: "internaldrive")
                    }

                StorageControlDemoView()
                    .tabItem {
                        Label("Storage Control", systemImage: "folder.badge.gearshape")
                    }

                NetworkCustomDemoView()
                    .tabItem {
                        Label("Network Custom", systemImage: "network")
                    }

                FullFeaturedDemoView()
                    .tabItem {
                        Label("Full Demo", systemImage: "photo.on.rectangle")
                    }
            }
        }
    }
}
