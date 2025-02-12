//
//  Temptime_WatchAppApp.swift
//  Temptime WatchApp Watch App
//
//  Created by 游哲維 on 2025/2/12.
//

import SwiftUI
import HealthKit

@main
struct Temptime_WatchApp_Watch_AppApp: App {
    // 全域的 HealthStore
    @StateObject private var healthManager = HealthManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthManager)
        }
    }
}
