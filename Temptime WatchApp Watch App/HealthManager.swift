//
//  HealthManager.swift
//  Temptime WatchApp Watch App
//
//  Created by 游哲維 on 2025/2/12.
//

import Foundation
import HealthKit
import SwiftUI  // 若需要 ObservableObject
import WatchConnectivity

// 繼承 NSObject，才可符合 HKLiveWorkoutBuilderDelegate 的需求
class HealthManager: NSObject, ObservableObject {
    var selectedWorkout: HKWorkoutActivityType? {
        didSet {
            guard let selectedWorkout = selectedWorkout else { return }
            startWorkoutSession()
        }
    }
    
    let healthStore = HKHealthStore()
    @Published var workout: HKWorkout?        // 結束後的最終 Workout 物件
    var workoutSession: HKWorkoutSession?
    var workoutBuilder: HKLiveWorkoutBuilder?
    private var anchor: HKQueryAnchor?

    /// 觀測用變數，供 SwiftUI 即時更新
    @Published var lastHeartRate: Double?

    // 通常在 Watch 上，您可以在 init 就先 requestAuthorization
    override init() {
        super.init()
        requestAuthorization()
        // 啟動 Watch Connectivity
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    private func startWorkoutSession() {
        // 這是 watchOS 限定的 HKLiveWorkoutBuilder 語法
        let config = HKWorkoutConfiguration()
        config.activityType = .walking
        config.locationType = .outdoor
        
        do {
            self.workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            self.workoutBuilder = workoutSession?.associatedWorkoutBuilder()
            self.workoutBuilder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: config
            )
            
            // 設定 delegate, 監聽即時心率
            self.workoutBuilder?.delegate = self
            self.workoutSession?.delegate = self
            
            // 開始活動
            self.workoutSession?.startActivity(with: Date())
            self.workoutBuilder?.beginCollection(withStart: Date()) { success, error in
                if let error = error {
                    print("❌ beginCollection error: \(error.localizedDescription)")
                } else {
                    print("✅ Workout 開始收集心率")
                }
            }
        } catch {
            print("❌ 建立 WorkoutSession 失敗：\(error)")
        }
    }

    func requestAuthorization() {
        // 確認裝置是否支援 HealthKit (多數 Apple Watch 都支援)
        guard HKHealthStore.isHealthDataAvailable() else {
            print("Health data not available on this device.")
            return
        }
        
        // 指定想讀/寫的資料類型
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let oxygenType    = HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!

        let readTypes: Set<HKObjectType>  = [heartRateType, oxygenType]
        let writeTypes: Set<HKSampleType> = [heartRateType, oxygenType]

        healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
            if let error = error {
                print("❌ HealthKit Auth Error: \(error.localizedDescription)")
                return
            }
            print("✅ HealthKit Auth success: \(success)")
        }
    }
    
    // MARK: - Workout 主要流程
    
    /// 選擇一個 Workout 類型後（如 walking），就開始一段 Session
    /// 這裡示範寫死為 walking，也可依需求自訂
    func startWorkout() {
        let config = HKWorkoutConfiguration()
        config.activityType = .walking  // 假設固定散步
        config.locationType = .outdoor
        
        do {
            // 1) 建立 Workout Session
            let session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            self.workoutSession = session
            
            // 2) 取得 LiveWorkoutBuilder
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)
            self.workoutBuilder = builder
            
            // 3) 指定 Delegate
            session.delegate = self
            builder.delegate = self
            
            // 4) 啟動 Workout
            session.startActivity(with: Date())
            builder.beginCollection(withStart: Date()) { success, error in
                if let e = error {
                    print("❌ beginCollection error: \(e.localizedDescription)")
                } else {
                    print("✅ Workout 開始收集心率")
                }
            }
        } catch {
            print("❌ 建立 WorkoutSession 失敗：\(error)")
        }
    }
    
    // MARK: - Session State Control

    // The app's workout state.
    @Published var running = false
    
    /// 暫停或繼續
    func togglePause() {
        running ? pauseWorkout() : resumeWorkout()
    }

    private func pauseWorkout() {
        workoutSession?.pause()
    }

    private func resumeWorkout() {
        workoutSession?.resume()
    }

    func endWorkout() {
        workoutSession?.end()
//        showingSummaryView = true
    }
    
    // MARK: - Workout Metrics
    @Published var averageHeartRate: Double = 0
    @Published var heartRate: Double = 0
    @Published var heartRateData = [(date: Date, bpm: Double)]()
    @Published var activeEnergy: Double = 0
    
    func fetchRecentHeartRate() {
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        
        // 設定查詢日期範圍 (例如過去 1 小時)
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .hour, value: -1, to: now)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType,
                                  predicate: predicate,
                                  limit: 50,
                                  sortDescriptors: [sortDescriptor]) { query, samples, error in
            if let error = error {
                print("❌ HeartRate Query Error: \(error)")
                return
            }
            
            guard let samples = samples as? [HKQuantitySample] else { return }
            
            for sample in samples {
                let bpm = sample.quantity.doubleValue(for: .init(from: "count/min"))
                print("🩺 心率: \(bpm) BPM, 時間: \(sample.startDate)")
            }
        }
        
        healthStore.execute(query)
    }
    
    func startObservingHeartRate() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] _, completionHandler, error in
            if let error = error {
                print("ObserverQuery Error: \(error.localizedDescription)")
                return
            }

            // 收到通知後，可以使用 AnchoredObjectQuery 再去抓新的資料
            self?.fetchNewHeartRateData()

            // 告知系統已處理完通知
            completionHandler()
        }
        
        healthStore.execute(query)
        healthStore.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { success, error in
            if let error = error {
                print("Background Delivery Error: \(error.localizedDescription)")
            }
        }
    }
    
    func fetchNewHeartRateData() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: anchor,
            limit: HKObjectQueryNoLimit
        ) { [weak self] query, samples, deletedObjects, newAnchor, error in
            if let error = error {
                print("AnchoredObjectQuery Error: \(error.localizedDescription)")
                return
            }
            guard let self = self else { return }
            
            // 更新 anchor
            self.anchor = newAnchor
            
            if let quantitySamples = samples as? [HKQuantitySample], !quantitySamples.isEmpty {
                // 取最後一筆或全部資料
                let mostRecent = quantitySamples.last
                let bpmUnit = HKUnit.count().unitDivided(by: .minute())
                let bpm = mostRecent?.quantity.doubleValue(for: bpmUnit)
                
                DispatchQueue.main.async {
                    self.lastHeartRate = bpm
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    // MARK: - 其他存取
    
    func saveOxygenSaturation(_ value: Double) {
        guard let oxygenType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation) else {
            return
        }
        
        let now = Date()
        let quantity = HKQuantity(unit: .percent(), doubleValue: value)
        let sample = HKQuantitySample(type: oxygenType, quantity: quantity, start: now, end: now)

        healthStore.save(sample) { success, error in
            if let error = error {
                print("❌ Save Blood Oxygen Error: \(error)")
            } else {
                print("✅ Blood Oxygen saved: \(success)")
            }
        }
    }
    
    func startHeartRate() {
        // 1) 檢查授權
        guard HKHealthStore.isHealthDataAvailable(),
              let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        // 2) 如果尚未授權，就先 requestAuthorization
        healthStore.requestAuthorization(toShare: [], read: [heartRateType]) { [weak self] success, error in
            guard let self = self else { return }
            if success {
                // 授權成功，開始 Workout 或 ObserverQuery
                self.startWorkoutSession()
            } else {
                print("❌ 無法取得 HealthKit 授權: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    func stopHeartRate() {
        workoutSession?.stopActivity(with: Date())
        workoutBuilder?.endCollection(withEnd: Date()) { success, error in
            print("✅ 停止心率量測")
            self.workoutSession = nil
            self.workoutBuilder = nil
        }
    }
    
    func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics = statistics else { return }

        DispatchQueue.main.async {
            switch statistics.quantityType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                self.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                self.averageHeartRate = statistics.averageQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                
                // 也可即時傳到 iPhone
                self.sendHeartRateToiPhone(hr: self.heartRate, avg: self.averageHeartRate)

//            case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
//                let energyUnit = HKUnit.kilocalorie()
//                self.activeEnergy = statistics.sumQuantity()?.doubleValue(for: energyUnit) ?? 0
//            case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning), HKQuantityType.quantityType(forIdentifier: .distanceCycling):
//                let meterUnit = HKUnit.meter()
//                self.distance = statistics.sumQuantity()?.doubleValue(for: meterUnit) ?? 0
            default:
                return
            }
        }
    }
    
    private func sendHeartRateToiPhone(hr: Double, avg: Double) {
        guard WCSession.default.isReachable else { return }
        let data: [String: Any] = [
            "heartRate": hr,
            "averageHeartRate": avg
        ]
        WCSession.default.sendMessage(data, replyHandler: nil) { error in
            print("❌ 傳送心率給 iPhone 失敗: \(error.localizedDescription)")
        }
    }

    func resetWorkout() {
        selectedWorkout = nil
        workoutBuilder = nil
        workout = nil
        workoutSession = nil
        activeEnergy = 0
        averageHeartRate = 0
        heartRate = 0
    }
}

// MARK: - HKWorkoutSessionDelegate
extension HealthManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.running = toState == .running
        }

        // Wait for the session to transition states before ending the builder.
        if toState == .ended {
            workoutBuilder?.endCollection(withEnd: date) { (success, error) in
                self.workoutBuilder?.finishWorkout { (workout, error) in
                    DispatchQueue.main.async {
                        self.workout = workout
                    }
                }
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didFailWithError error: Error) {
        print("workoutSession 發生錯誤: \(error.localizedDescription)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension HealthManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {

    }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return // Nothing to do.
            }

            let statistics = workoutBuilder.statistics(for: quantityType)

            // Update the published values.
            updateForStatistics(statistics)
        }
        
        guard collectedTypes.contains(HKQuantityType.quantityType(forIdentifier: .heartRate)!) else { return }
        
        if let stats = workoutBuilder.statistics(for: HKQuantityType.quantityType(forIdentifier: .heartRate)!) {
            let bpmUnit = HKUnit.count().unitDivided(by: .minute())
            let latestHR = stats.mostRecentQuantity()?.doubleValue(for: bpmUnit)
            let latestDate = stats.mostRecentQuantityDateInterval()?.end  // 取心率量測時間
            
            if let hr = latestHR, let date = latestDate {
                // 存進陣列
                heartRateData.append((date: date, bpm: hr))
            }
        }
    }
}

// MARK: - Watch Connectivity

extension HealthManager: WCSessionDelegate {
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("Watch -> iPhone reachable: \(session.isReachable)")
    }
    
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let e = error {
            print("WCSession 啟動失敗: \(e.localizedDescription)")
        } else {
            print("WCSession 狀態: \(activationState.rawValue)")
        }
    }
    
    // 若您需要接收來自 iPhone 的 Message/UserInfo，也可在這裡實作:
    // func session(_ session: WCSession, didReceiveMessage message: [String : Any]) { ... }
}
