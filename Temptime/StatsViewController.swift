//
//  StatsViewController.swift
//  Temptime
//
//  Created by 游哲維 on 2025/1/31.
//

import UIKit
import CoreData

class StatsViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    
    func analyzeTopics() {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<Dating> = Dating.fetchRequest()
        
        do {
            let datings = try context.fetch(fetchRequest)
            let topics = datings.map { $0.notes ?? "" }
            let commonWords = analyzeCommonWords(in: topics)
            textView.text = "最常聊的話題: \(commonWords)"
        } catch {
            print("❌ 無法分析話題")
        }
    }

    func analyzeCommonWords(in texts: [String]) -> [String] {
        let words = texts.flatMap { $0.split(separator: " ") }
        let wordCount = Dictionary(words.map { ($0, 1) }, uniquingKeysWith: +)
        return wordCount.keys
            .sorted { wordCount[$0]! > wordCount[$1]! }
            .map { String($0) } // ✅ 將 Substring 轉為 String
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
