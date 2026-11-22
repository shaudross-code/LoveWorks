//
//  iLoveWorksWatchApp.swift
//  iLoveWorksWatch
//

import SwiftUI

@main
struct iLoveWorksWatchApp: App {
    @StateObject private var model = WatchCaloriesModel()

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environmentObject(model)
        }
    }
}
