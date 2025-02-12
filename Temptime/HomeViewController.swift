//
//  HomeViewController.swift
//  Temptime
//
//  Created by 游哲維 on 2025/1/31.
//

import UIKit
import CoreData

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addDatingButton: UIButton!
    @IBOutlet weak var addPickupButton: UIButton!
    @IBOutlet weak var viewFullDataButton: UIButton!
    
    var datings: [Dating] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
//        createMockDatings(context: context) // ✅ 在一開始就創建假資料
        clearAllDatings()
        datings = []
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "meetingCell")
        
        addDatingButton.translatesAutoresizingMaskIntoConstraints = false
        addPickupButton.translatesAutoresizingMaskIntoConstraints = false
        viewFullDataButton.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // ✅ 設定 Auto Layout
        NSLayoutConstraint.activate([
            // 設定 addDatingButton
            addDatingButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
            addDatingButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 0),
            addDatingButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
            addDatingButton.heightAnchor.constraint(equalToConstant: 60),
            
            // 設定 addPickupButton
            addPickupButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
            addPickupButton.topAnchor.constraint(equalTo: addDatingButton.bottomAnchor, constant: 0),
            addPickupButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
            addPickupButton.heightAnchor.constraint(equalToConstant: 60),

            // 設定 viewFullDataButton
            viewFullDataButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
            viewFullDataButton.topAnchor.constraint(equalTo: addPickupButton.bottomAnchor, constant: 0),
            viewFullDataButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
            viewFullDataButton.heightAnchor.constraint(equalToConstant: 60),

            // ✅ 設定 tableView 的 top 在 addDatingButton 的底部
            tableView.topAnchor.constraint(equalTo: viewFullDataButton.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0) // 讓 tableView 填滿剩餘空間
        ])
        
        print("📢 tableView frame: \(tableView.frame)")
                
        // ✅ 添加 UIRefreshControl
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
                
        fetchDatings() // 加載約會紀錄
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        print("📢 tableView frame: \(tableView.frame)")

        // ✅ 確保在 View 層級建立後再設定背景
        setTableViewBackground(imageName: "backgroundImage")
    }
    
    // ✅ 設定 UITableView 背景圖片
    func setTableViewBackground(imageName: String) {
        if datings.isEmpty {
            let backgroundImage = UIImageView(image: UIImage(named: imageName))
            backgroundImage.contentMode = .scaleAspectFill
            backgroundImage.frame = tableView.bounds
            print(tableView.bounds)
            backgroundImage.alpha = 0.7 // ✅ 設定透明度，避免影響可讀性
            backgroundImage.translatesAutoresizingMaskIntoConstraints = false
            
            // ✅ 確保背景圖片直接加入 `self.view`
            view.insertSubview(backgroundImage, belowSubview: tableView)

            NSLayoutConstraint.activate([
                backgroundImage.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                backgroundImage.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                backgroundImage.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                backgroundImage.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor)
            ])

            tableView.backgroundView = backgroundImage
            print("📢 設定背景圖")
        } else {
            tableView.backgroundView = nil // ✅ 有約會記錄時，移除背景圖片
            print("📢 移除背景圖")
        }
    }
    
    func clearAllDatings() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Dating> = Dating.fetchRequest()

        do {
            let allDatings = try context.fetch(fetchRequest)
            for dating in allDatings {
                context.delete(dating)
            }
            try context.save()
            print("✅ 所有約會記錄已刪除")
        } catch {
            print("❌ 無法刪除約會記錄：\(error)")
        }
    }
    
    // ✅ 當用戶下拉時，重新載入數據
    @objc func refreshData() {
        fetchDatings()
        tableView.refreshControl?.endRefreshing()
    }
    
    func fetchDatings() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Dating> = Dating.fetchRequest()
        do {
            datings = try context.fetch(fetchRequest)
            
            // ✅ 如果沒有資料，則自動添加一些假資料
            if datings.isEmpty {
                datings = try context.fetch(fetchRequest) // 再次加載
            }
            
            tableView.reloadData()
        } catch {
            print("❌ 無法加載約會紀錄：\(error)")
        }
    }
    
    // ✅ 直接創建假資料
    func createMockDatings(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<Dating> = Dating.fetchRequest()
        
        do {
            let existingData = try context.fetch(fetchRequest)
            if !existingData.isEmpty {
                print("✅ 已存在約會記錄，不再添加假資料")
                return // 如果已有資料，不重複新增
            }
        } catch {
            print("❌ 無法檢查現有資料：\(error)")
        }

        let mockData: [(String, String, String, String)] = [
            ("晚餐約會", "2025-02-14 19:00:00", "在高級餐廳用餐", "約會"),
            ("咖啡聊天", "2025-02-10 15:00:00", "討論新項目", "朋友聚會"),
            ("週末郊遊", "2025-02-17 09:00:00", "去山上露營", "旅行"),
            ("電影之夜", "2025-02-20 21:00:00", "看最新的漫威電影", "娛樂"),
            ("健身房訓練", "2025-02-05 07:00:00", "和朋友一起重訓", "健康"),
            ("家庭聚餐", "2025-02-12 18:30:00", "和家人吃飯聊天", "家庭"),
            ("客戶會議", "2025-02-08 14:00:00", "與客戶討論合約", "商務"),
            ("美術館參觀", "2025-02-22 16:00:00", "欣賞當代藝術展覽", "文化"),
        ]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        for (name, dateString, notes, type) in mockData {
            let newDating = Dating(context: context)
            newDating.name = name
            newDating.date = dateFormatter.date(from: dateString)
            newDating.notes = notes
            newDating.type = type
        }

        do {
            try context.save()
            print("✅ 假資料已成功添加！")
        } catch {
            print("❌ 無法存儲假資料：\(error)")
        }
    }
    
    @IBAction func addDatingTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let addDatingVC = storyboard.instantiateViewController(withIdentifier: "AddDatingViewController") as! AddDatingViewController
        addDatingVC.modalPresentationStyle = .fullScreen // ✅ 設定為全螢幕
        present(addDatingVC, animated: true, completion: nil)
    }
    
    @IBAction func addPickupTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let addPickupVC = storyboard.instantiateViewController(withIdentifier: "AddPickupViewController") as! AddPickupViewController
        addPickupVC.modalPresentationStyle = .fullScreen // ✅ 設定為全螢幕
        present(addPickupVC, animated: true, completion: nil)
    }
    
    // ✅ TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "meetingCell", for: indexPath)
        let dating = datings[indexPath.row]
        cell.textLabel?.text = "\(String(describing: dating.name)) - \(dating.date ?? Date())"
        return cell
    }
    
    // ✅ 刪除約會
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
            let datingToDelete = datings[indexPath.row]
            context.delete(datingToDelete)
            
            do {
                try context.save()
                datings.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
            } catch {
                print("❌ 刪除失敗：\(error)")
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
