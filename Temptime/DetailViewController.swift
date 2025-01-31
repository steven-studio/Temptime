//
//  DetailViewController.swift
//  Temptime
//
//  Created by 游哲維 on 2025/1/31.
//

import UIKit

class DetailViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var notesTextView: UITextView!
    
    var dating: Dating?

    override func viewDidLoad() {
        super.viewDidLoad()
        if let dating = dating {
            titleLabel.text = dating.name
            dateLabel.text = "約會時間: \(dating.date ?? Date())"
            notesTextView.text = dating.notes
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
