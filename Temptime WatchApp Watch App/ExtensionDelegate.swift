//
//  ExtensionDelegate.swift
//  Temptime WatchApp Watch App
//
//  Created by 游哲維 on 2025/2/12.
//

import Foundation
import WatchConnectivity
import HealthKit
import WatchKit

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        if let error = error {
            print("WCSession 啟動失敗: \(error.localizedDescription)")
        } else {
            print("WCSession 啟動成功, 狀態: \(activationState.rawValue)")
        }
    }
    
    let healthManager = HealthManager() // 這個 HealthManager 是「Watch 專屬」的
    
    func applicationDidFinishLaunching() {
        // 設定 Watch Connectivity
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    // MARK: - WCSessionDelegate
    func session(_ session: WCSession,
                 didReceiveMessage message: [String : Any]) {
        // 收到 iPhone 傳來的 ["command": "startHeartRate"] / ["command": "stopHeartRate"]
        if let command = message["command"] as? String {
            switch command {
            case "startHeartRate":
                healthManager.startHeartRate()  // <--- 在這裡開始量測
            case "stopHeartRate":
                healthManager.stopHeartRate()   // <--- 在這裡停止量測
            default:
                break
            }
        }
    }

    // 其餘必須實作的 WCSessionDelegate 內容...
}
