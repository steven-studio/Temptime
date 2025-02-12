//
//  ContentView.swift
//  Temptime WatchApp Watch App
//
//  Created by 游哲維 on 2025/2/12.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    // 讓 ContentView 觀察並更新 UI
    @ObservedObject var healthManager = HealthManager()
    
    var body: some View {
        VStack {
            // 顯示最新心率
            if let bpm = healthManager.lastHeartRate {
                Text("最新心率：\(Int(bpm)) BPM")
                    .font(.headline)
            } else {
                Text("尚無心率資料")
            }
            
            // 按鈕 2：讀取最近一筆心率
            Button("Fetch Recent Heart Rate") {
                healthManager.fetchRecentHeartRate()
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
