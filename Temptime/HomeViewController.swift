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
    
    var datings: [Dating] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // ✅ 添加 UIRefreshControl
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
                
        fetchDatings() // 加載約會紀錄
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
            tableView.reloadData()
        } catch {
            print("❌ 無法加載約會紀錄：\(error)")
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return datings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "meetingCell", for: indexPath)
        let dating = datings[indexPath.row]
        cell.textLabel?.text = "\(String(describing: dating.name)) - \(dating.date ?? Date())"
        return cell
    }
    
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
