//
//  AddDatingViewController.swift
//  Temptime
//
//  Created by 游哲維 on 2025/1/31.
//

import UIKit

class AddDatingViewController: UIViewController {
    
    private let statusOptions = ["無", "牽手", "親吻", "愛撫", "全壘打"]
    
    private let meetOptions = [
        "朋友介紹",
        "網路認識",
        "路上搭訕",
        "同事",
        "同學",
        "其他"
    ]
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var datingTypeSegment: UISegmentedControl!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var nameView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var dateView: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var dateTextField: UITextField!
    
    @IBOutlet weak var locationView: UIView!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var locationTextField: UITextField!
    
    @IBOutlet weak var participantView: UIView!
    @IBOutlet weak var participantLabel: UILabel!
    @IBOutlet weak var participantTextField: UITextField!
    
    @IBOutlet weak var meetView: UIView!
    @IBOutlet weak var meetLabel: UILabel!
    @IBOutlet weak var meetPicker: UIPickerView!
    
    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var statusPicker: UIPickerView!
    
    @IBOutlet weak var eventView: UIView!
    @IBOutlet weak var eventLabel: UILabel!
    @IBOutlet weak var eventTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        modalPresentationStyle = .fullScreen // ✅ 設定為全螢幕
        
        saveButton.frame = CGRect(
            x: view.bounds.width - saveButton.frame.width - 16,
            y: 60,
            width: 58, // 設定按鈕寬度
            height: 35  // 設定按鈕高度
        )
        
        meetPicker.delegate = self
        meetPicker.dataSource = self
        
        statusPicker.delegate = self   // pickerView 的委派是自己
        statusPicker.dataSource = self // pickerView 的資料來源也是自己
        
        // 1️⃣ 建立一個 Tap Gesture，並指派目標方法
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))

        // 2️⃣ 設定 `cancelsTouchesInView = false`，讓點擊後依然可處理其他事件（例如 ScrollView 滑動）
        tapGesture.cancelsTouchesInView = false

        // 3️⃣ 加到你想監控的範圍：例如整個 `scrollView` 或整個 `view`
        scrollView.addGestureRecognizer(tapGesture)
        // 或是 self.view.addGestureRecognizer(tapGesture)
        
        // 監聽鍵盤彈出
        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        // 監聽鍵盤收起
        NotificationCenter.default.addObserver(self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )

    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        // 取得鍵盤高度
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else {
            return
        }

        // 計算實際需要的底部 inset：鍵盤高度 - safeAreaInsets（若有）
        let keyboardHeight = keyboardFrame.height - view.safeAreaInsets.bottom
        print(keyboardHeight)
        scrollView.contentInset.bottom = keyboardHeight
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardHeight
        
        // 2. 再把「正在編輯」的視圖，捲動到可見範圍
        DispatchQueue.main.async {
            if let activeResponder = self.view.currentFirstResponder as? UIView {
                let rect = activeResponder.convert(activeResponder.bounds, to: self.scrollView)
                self.scrollView.scrollRectToVisible(rect, animated: true)
            }
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        // 鍵盤收起時，重設 bottom inset
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
    
    // 目標方法：結束編輯，收起鍵盤
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let fieldSpacing: CGFloat = 8
        let labelHeight: CGFloat = 20
        let textFieldHeight: CGFloat = 35
        
        scrollView.frame = CGRect(
            x: 0,
            y: 103,
            width: view.bounds.width,  // ✅ 確保寬度填滿螢幕
            height: view.bounds.height - 103
        )
        
//        scrollView.backgroundColor = UIColor.green.withAlphaComponent(0.3) // ✅ 讓 StackView 變半透明紅色
        
        NSLayoutConstraint.activate([
            // ⚠️ 注意：這樣會強制 contentLayoutGuide 與 frameLayoutGuide 同大小
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])
        
        scrollView.contentLayoutGuide.heightAnchor.constraint(
            greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor
        ).isActive = true
        
        // ✅ 設定 StackView 的屬性
        stackView.axis = .vertical
        stackView.spacing = fieldSpacing
        stackView.alignment = .fill
        stackView.distribution = .fill
        
        // ✅ 確保 StackView 內的元件會自動調整大小
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // ✅ `StackView` 的 TopAnchor 應該參考 `scrollView.contentLayoutGuide`
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: fieldSpacing),

            // ✅ `StackView` 的 Leading 和 Trailing 必須貼齊 `scrollView.frameLayoutGuide`
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: fieldSpacing),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -fieldSpacing),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: fieldSpacing),
        ])
        
        print(scrollView.contentLayoutGuide)
//        stackView.backgroundColor = UIColor.red.withAlphaComponent(0.3) // ✅ 讓 StackView 變半透明紅色
        
        // ✅ 設定 NameView 的 Auto Layout
        nameView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nameView.topAnchor.constraint(equalTo: stackView.topAnchor),
            nameView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            nameView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            nameView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60), // 避免 nameView 高度為 0
            
            // ✅ `NameView` 的 BottomAnchor 讓 `nameView` 正確計算 `contentSize`
//            nameView.bottomAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 20),
        ])
//        nameView.backgroundColor = UIColor.red.withAlphaComponent(0.3) // ✅ 讓 StackView 變半透明紅色
                
        if let nameLabel = nameLabel, let nameTextField = nameTextField {
            nameLabel.translatesAutoresizingMaskIntoConstraints = false
            nameTextField.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                // Name
                nameLabel.topAnchor.constraint(equalTo: nameView.topAnchor, constant: fieldSpacing),
                nameLabel.leadingAnchor.constraint(equalTo: nameView.leadingAnchor, constant: fieldSpacing),
                nameLabel.trailingAnchor.constraint(equalTo: nameView.trailingAnchor, constant: -fieldSpacing),
                nameLabel.heightAnchor.constraint(equalToConstant: labelHeight),

                nameTextField.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: fieldSpacing),
                nameTextField.leadingAnchor.constraint(equalTo: nameView.leadingAnchor, constant: fieldSpacing),
                nameTextField.trailingAnchor.constraint(equalTo: nameView.trailingAnchor, constant: -fieldSpacing),
                nameTextField.heightAnchor.constraint(equalToConstant: textFieldHeight),
                
                // **最重要的修正：讓 nameView 正確包住 nameTextField**
                nameTextField.bottomAnchor.constraint(equalTo: nameView.bottomAnchor, constant: -8)
            ])
        }
        
        nameView.backgroundColor = .systemGray6
        
        nameTextField.borderStyle = .roundedRect
        
        // ✅ 設定 DateView 的 Auto Layout
        dateView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dateView.topAnchor.constraint(equalTo: nameView.bottomAnchor, constant: fieldSpacing),
            dateView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            dateView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),

            // ✅ `dateView` 內部元件控制高度，這樣它會隨著內容大小自動調整
            dateView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60), // 避免 nameView 高度為 0
        ])
        
        if let dateLabel = dateLabel, let dateTextField = dateTextField {
            dateLabel.translatesAutoresizingMaskIntoConstraints = false
            dateTextField.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                // `dateLabel` 置頂
                dateLabel.topAnchor.constraint(equalTo: dateView.topAnchor, constant: fieldSpacing),
                dateLabel.leadingAnchor.constraint(equalTo: dateView.leadingAnchor, constant: fieldSpacing),
                dateLabel.trailingAnchor.constraint(equalTo: dateView.trailingAnchor, constant: -fieldSpacing),
                dateLabel.heightAnchor.constraint(equalToConstant: labelHeight),

                // `dateTextField` 置於 `dateLabel` 下方
                dateTextField.topAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: fieldSpacing),
                dateTextField.leadingAnchor.constraint(equalTo: dateView.leadingAnchor, constant: fieldSpacing),
                dateTextField.trailingAnchor.constraint(equalTo: dateView.trailingAnchor, constant: -fieldSpacing),
                dateTextField.heightAnchor.constraint(equalToConstant: textFieldHeight),

                // ✅ `dateView` 自動擴展，包住 `dateLabel` 和 `dateTextField`
                dateTextField.bottomAnchor.constraint(equalTo: dateView.bottomAnchor, constant: -fieldSpacing)
            ])
        }
        
        dateView.backgroundColor = .systemGray6
        
        dateTextField.borderStyle = .roundedRect
        
        // ✅ 設定 LocationView 的 Auto Layout
        locationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            locationView.topAnchor.constraint(equalTo: dateView.bottomAnchor, constant: fieldSpacing),
            locationView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            locationView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),

            // ✅ `locationView` 內部元件控制高度，這樣它會隨著內容大小自動調整
            locationView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60), // 避免 nameView 高度為 0
        ])
        
        if let locationLabel = locationLabel, let locationTextField = locationTextField {
            locationLabel.translatesAutoresizingMaskIntoConstraints = false
            locationTextField.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                // `locationLabel` 置頂
                locationLabel.topAnchor.constraint(equalTo: locationView.topAnchor, constant: fieldSpacing),
                locationLabel.leadingAnchor.constraint(equalTo: locationView.leadingAnchor, constant: fieldSpacing),
                locationLabel.trailingAnchor.constraint(equalTo: locationView.trailingAnchor, constant: -fieldSpacing),
                locationLabel.heightAnchor.constraint(equalToConstant: labelHeight),

                // `locationTextField` 置於 `locationLabel` 下方
                locationTextField.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: fieldSpacing),
                locationTextField.leadingAnchor.constraint(equalTo: locationView.leadingAnchor, constant: fieldSpacing),
                locationTextField.trailingAnchor.constraint(equalTo: locationView.trailingAnchor, constant: -fieldSpacing),
                locationTextField.heightAnchor.constraint(equalToConstant: textFieldHeight),

                // ✅ `dateView` 自動擴展，包住 `dateLabel` 和 `dateTextField`
                locationTextField.bottomAnchor.constraint(equalTo: locationView.bottomAnchor, constant: -fieldSpacing)
            ])
        }
        
        locationView.backgroundColor = .systemGray6
        
        locationTextField.borderStyle = .roundedRect

        // ✅ 設定 ParticipantView 的 Auto Layout
        participantView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            participantView.topAnchor.constraint(equalTo: locationView.bottomAnchor, constant: fieldSpacing),
            participantView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            participantView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),

            // ✅ `participantView` 內部元件控制高度，這樣它會隨著內容大小自動調整
            participantView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60), // 避免 nameView 高度為 0
        ])
        
        if let participantLabel = participantLabel, let participantTextField = participantTextField {
            participantLabel.translatesAutoresizingMaskIntoConstraints = false
            participantTextField.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                // `locationLabel` 置頂
                participantLabel.topAnchor.constraint(equalTo: participantView.topAnchor, constant: fieldSpacing),
                participantLabel.leadingAnchor.constraint(equalTo: participantView.leadingAnchor, constant: fieldSpacing),
                participantLabel.trailingAnchor.constraint(equalTo: participantView.trailingAnchor, constant: -fieldSpacing),
                participantLabel.heightAnchor.constraint(equalToConstant: labelHeight),

                // `participantTextField` 置於 `participantLabel` 下方
                participantTextField.topAnchor.constraint(equalTo: participantLabel.bottomAnchor, constant: fieldSpacing),
                participantTextField.leadingAnchor.constraint(equalTo: participantView.leadingAnchor, constant: fieldSpacing),
                participantTextField.trailingAnchor.constraint(equalTo: participantView.trailingAnchor, constant: -fieldSpacing),
                participantTextField.heightAnchor.constraint(equalToConstant: textFieldHeight),

                // ✅ `dateView` 自動擴展，包住 `dateLabel` 和 `dateTextField`
                participantTextField.bottomAnchor.constraint(equalTo: participantView.bottomAnchor, constant: -fieldSpacing)
            ])
        }
        
        participantView.backgroundColor = .systemGray6
        
        participantTextField.borderStyle = .roundedRect
        
        // ✅ 設定 meetView 的 Auto Layout
        meetView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            meetView.topAnchor.constraint(equalTo: participantView.bottomAnchor, constant: fieldSpacing),
            meetView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            meetView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),

            // ✅ `meetView` 內部元件控制高度，這樣它會隨著內容大小自動調整
            meetView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60), // 避免 nameView 高度為 0
        ])
        
        meetPicker.setContentCompressionResistancePriority(.required, for: .vertical)
        
        if let meetLabel = meetLabel, let meetPicker = meetPicker {
            meetLabel.translatesAutoresizingMaskIntoConstraints = false
            meetPicker.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                // `locationLabel` 置頂
                meetLabel.topAnchor.constraint(equalTo: meetView.topAnchor, constant: fieldSpacing),
                meetLabel.leadingAnchor.constraint(equalTo: meetView.leadingAnchor, constant: fieldSpacing),
                meetLabel.trailingAnchor.constraint(equalTo: meetView.trailingAnchor, constant: -fieldSpacing),
                meetLabel.heightAnchor.constraint(equalToConstant: labelHeight),

                // `meetTextField` 置於 `meetLabel` 下方
                meetPicker.topAnchor.constraint(equalTo: meetLabel.bottomAnchor, constant: fieldSpacing),
                meetPicker.leadingAnchor.constraint(equalTo: meetView.leadingAnchor, constant: fieldSpacing),
                meetPicker.trailingAnchor.constraint(equalTo: meetView.trailingAnchor, constant: -fieldSpacing),
                meetPicker.heightAnchor.constraint(equalToConstant: 80),

                // ✅ `dateView` 自動擴展，包住 `dateLabel` 和 `dateTextField`
                meetPicker.bottomAnchor.constraint(equalTo: meetView.bottomAnchor, constant: -fieldSpacing)
            ])
        }
        
        meetView.backgroundColor = .systemGray6

        // ✅ 設定 statusView 的 Auto Layout
        statusView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statusView.topAnchor.constraint(equalTo: meetView.bottomAnchor, constant: fieldSpacing),
            statusView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            statusView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
//            statusView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),

            // ✅ `locationView` 內部元件控制高度，這樣它會隨著內容大小自動調整
            statusView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60), // 避免 nameView 高度為 0
        ])
        
        statusPicker.setContentCompressionResistancePriority(.required, for: .vertical)
        
        if let statusLabel = statusLabel, let statusPicker = statusPicker {
            statusLabel.translatesAutoresizingMaskIntoConstraints = false
            statusPicker.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                // `locationLabel` 置頂
                statusLabel.topAnchor.constraint(equalTo: statusView.topAnchor, constant: fieldSpacing),
                statusLabel.leadingAnchor.constraint(equalTo: statusView.leadingAnchor, constant: fieldSpacing),
                statusLabel.trailingAnchor.constraint(equalTo: statusView.trailingAnchor, constant: -fieldSpacing),
                statusLabel.heightAnchor.constraint(equalToConstant: labelHeight),

                // `locationTextField` 置於 `locationLabel` 下方
                statusPicker.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: fieldSpacing),
                statusPicker.leadingAnchor.constraint(equalTo: statusView.leadingAnchor, constant: fieldSpacing),
                statusPicker.trailingAnchor.constraint(equalTo: statusView.trailingAnchor, constant: -fieldSpacing),
                statusPicker.heightAnchor.constraint(equalToConstant: 80),

                // ✅ `dateView` 自動擴展，包住 `dateLabel` 和 `dateTextField`
                statusPicker.bottomAnchor.constraint(equalTo: statusView.bottomAnchor, constant: -fieldSpacing)
            ])
        }
        
        statusView.backgroundColor = .systemGray6
        
        // ✅ 設定 eventView 的 Auto Layout
        eventView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            eventView.topAnchor.constraint(equalTo: statusView.bottomAnchor, constant: fieldSpacing),
            eventView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            eventView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
//            eventView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),

            // ✅ `locationView` 內部元件控制高度，這樣它會隨著內容大小自動調整
            eventView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60), // 避免 eventView 高度為 0
        ])
                
        if let eventLabel = eventLabel, let eventTextView = eventTextView {
            eventLabel.translatesAutoresizingMaskIntoConstraints = false
            eventTextView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                // `locationLabel` 置頂
                eventLabel.topAnchor.constraint(equalTo: eventView.topAnchor, constant: fieldSpacing),
                eventLabel.leadingAnchor.constraint(equalTo: eventView.leadingAnchor, constant: fieldSpacing),
                eventLabel.trailingAnchor.constraint(equalTo: eventView.trailingAnchor, constant: -fieldSpacing),
                eventLabel.heightAnchor.constraint(equalToConstant: labelHeight),

                // `eventTextView` 置於 `eventLabel` 下方
                eventTextView.topAnchor.constraint(equalTo: eventLabel.bottomAnchor, constant: fieldSpacing),
                eventTextView.leadingAnchor.constraint(equalTo: eventView.leadingAnchor, constant: fieldSpacing),
                eventTextView.trailingAnchor.constraint(equalTo: eventView.trailingAnchor, constant: -fieldSpacing),
                
                // ✅ `eventView` 自動擴展，包住 `eventLabel` 和 `eventTextView`
                eventTextView.bottomAnchor.constraint(equalTo: eventView.bottomAnchor, constant: -fieldSpacing),
                eventTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100), // 避免 eventView 高度為 0
            ])
        }
        
        eventView.backgroundColor = .systemGray6
        
//        eventTextView.layer.borderColor = UIColor.lightGray.cgColor  // 邊框顏色
//        eventTextView.layer.borderWidth = 1.0                       // 邊框線寬
        eventTextView.layer.cornerRadius = 6.0                      // 圓角大小
        eventTextView.layer.masksToBounds = true                   // 確保超出範圍被裁切
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("📢 nameTextField.isUserInteractionEnabled = \(nameTextField.isUserInteractionEnabled)")
        print("📢 nameTextField.isEnabled = \(nameTextField.isEnabled)")

        print("📢 scrollView.frame:", scrollView.frame)
        print("📢 scrollView.contentLayoutGuide.layoutFrame:", scrollView.contentLayoutGuide.layoutFrame)
        print("📢 stackView.frame:", stackView.frame)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "yourSegueIdentifier" {
            let destinationVC = segue.destination
            destinationVC.modalPresentationStyle = .fullScreen // ✅ 設定為全螢幕
        }
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

extension AddDatingViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    // UIPickerViewDataSource: 幾個欄位 (component)
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    // UIPickerViewDataSource: 該欄有幾列 (row)
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        // 判斷 pickerView 是 meetPicker 還是 statusPicker
        if pickerView == meetPicker {
            return meetOptions.count   // 「怎麼認識」的選項
        } else if pickerView == statusPicker {
            return statusOptions.count // 「狀態」的選項
        } else {
            return 0
        }
    }
    
    // UIPickerViewDelegate: 每一列要顯示的文字
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == meetPicker {
            return meetOptions[row]
        } else if pickerView == statusPicker {
            return statusOptions[row]
        } else {
            return nil
        }
    }
    
    // UIPickerViewDelegate: 選到哪一列
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == meetPicker {
            let selectedMeet = meetOptions[row]
            print("使用者選了怎麼認識方式：\(selectedMeet)")
            // 可以存在變數 e.g. self.currentMeet = selectedMeet
        } else if pickerView == statusPicker {
            let selectedStatus = statusOptions[row]
            print("使用者選了狀態：\(selectedStatus)")
            // 可以存在變數 e.g. self.currentStatus = selectedStatus
        }
    }
}

extension UIView {
    var currentFirstResponder: UIResponder? {
        if self.isFirstResponder {
            return self
        }
        for subview in subviews {
            if let responder = subview.currentFirstResponder {
                return responder
            }
        }
        return nil
    }
}
