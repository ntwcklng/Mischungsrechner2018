//
//  MischungsrechnerApp.swift
//  Mischungsrechner
//
//  Copyright © 2025 Marvin Mieth. All rights reserved.
//

import SwiftUI

@main
struct MischungsrechnerApp: App {
    @State private var data = AppData()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(data)
        }
    }
}
