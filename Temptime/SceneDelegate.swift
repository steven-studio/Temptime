//
//  SceneDelegate.swift
//  Temptime
//
//  Created by 游哲維 on 2025/1/31.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    // MARK: - Lifecycle

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        // 若在啟動時就有 Deeplink URL，可在這裡處理
        if let urlContext = connectionOptions.urlContexts.first {
            handleIncomingURL(urlContext.url)
        }
    }
    
    // MARK: - Open URL (Deep Link)
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let urlContext = URLContexts.first else { return }
        let url = urlContext.url
        
        // 例如 temptime://addPickup?girlName=Alice&note=xxx
        handleIncomingURL(url)
    }
    
    private func handleIncomingURL(_ url: URL) {
        // 1. 確認 scheme, host 等
        guard url.scheme == "temptime" else { return }

        // 2. 解析 query param
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems
        let girlName   = queryItems?.first(where: { $0.name == "girlName" })?.value
        let note       = queryItems?.first(where: { $0.name == "note" })?.value

        // 3. 在這裡呼叫 Temptime 的邏輯，寫入 AddPickUpViewController
        //    例如跳轉到對應畫面、或直接呼叫 Manager 在 Core Data 建一筆紀錄
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let addPickupVC = storyboard
            .instantiateViewController(withIdentifier: "AddPickupViewController")
                as? AddPickupViewController
        else {
            print("⚠️ 無法生成 AddPickupViewController")
            return
        }
        
        // 4. 傳遞資訊
        addPickupVC.initialGirlName = girlName!
        addPickupVC.initialNote = note ?? ""
        
        // 5. 透過根視圖控制器顯示
        //    需根據您的專案結構做適當呈現 (push / present)

        guard let rootVC = window?.rootViewController else {
            print("⚠️ 根視圖控制器不存在")
            return
        }

        // 若根是 NavigationController, 可以 push
        if let nav = rootVC as? UINavigationController {
            nav.pushViewController(addPickupVC, animated: true)
        }
        // 若根是 TabBar，就先選擇對應 tab 再 push
        else if let tabBar = rootVC as? UITabBarController,
                let nav = tabBar.selectedViewController as? UINavigationController {
            nav.pushViewController(addPickupVC, animated: true)
        }
        // 否則直接 present
        else {
            rootVC.present(addPickupVC, animated: true)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
}

