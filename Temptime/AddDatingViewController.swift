//
//  AddDatingViewController.swift
//  Temptime
//
//  Created by 游哲維 on 2025/1/31.
//

import UIKit

class AddDatingViewController: UIViewController {
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var datingTypeSegment: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        saveButton.frame = CGRect(
            x: view.bounds.width - saveButton.frame.width - 16,
            y: 20,
            width: 58, // 設定按鈕寬度
            height: 35  // 設定按鈕高度
        )
    }
    
    @IBAction func saveDating(_ sender: UIButton) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let newDating = Dating(context: context)
        newDating.name = nameTextField.text
        newDating.date = datePicker.date
        newDating.type = datingTypeSegment.titleForSegment(at: datingTypeSegment.selectedSegmentIndex)

        do {
            try context.save()
            navigationController?.popViewController(animated: true)
        } catch {
            print("❌ 無法儲存約會紀錄")
        }
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
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
