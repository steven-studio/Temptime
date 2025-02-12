//
//  AddDatingViewController.swift
//  Temptime
//
//  Created by 游哲維 on 2025/1/31.
//

import UIKit
import PhotosUI

extension AddDatingViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        // 關閉選擇器
        picker.dismiss(animated: true, completion: nil)
        
        // 確定至少有一個結果
        guard let itemProvider = results.first?.itemProvider else { return }

        // 檢查 itemProvider 是否能加載影片
        if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            // 載入檔案表示 (會在沙盒 tmp 目錄生成一個檔案)
            itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] (url, error) in
                guard let self = self, let sourceURL = url else { return }
                if let error = error {
                    print("❌ 載入影片檔案失敗: \(error)")
                    return
                }
                
                do {
                    // 將 tmp 檔案複製到 Documents，以便後續長期保存
                    let fileManager = FileManager.default
                    let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    
                    // 產生一個檔名
                    let newFileName = "pickedVideo\(Date().timeIntervalSince1970).mov"
                    let destinationURL = documents.appendingPathComponent(newFileName)
                    
                    // 先確保若有同名檔案就刪除 (避免衝突)
                    if fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.removeItem(at: destinationURL)
                    }
                    
                    try fileManager.copyItem(at: sourceURL, to: destinationURL)
                    
                    // 在主執行緒裡更新UI或屬性
                    DispatchQueue.main.async {
                        // 把最終沙盒路徑存起來
                        self.selectedVideoPath = destinationURL.path
                        print("✅ 成功複製影片到: \(destinationURL.path)")
                    }
                } catch {
                    print("❌ 無法複製檔案: \(error)")
                }
            }
        } else {
            print("❌ 選取的不是影片格式")
        }
    }
}

class AddDatingViewController: UIViewController {
    
    private let statusOptions = ["無", "牽手", "親吻", "愛撫", "全壘打"]
    
    private let meetOptions = [
        "朋友介紹",
        "網路認識",
        "路上搭訕",
        "搭訕即約",
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
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var videoLabel: UILabel!
    @IBOutlet weak var videoButton: UIButton!
    
    // 用來暫存從 meetPicker 選到的結果
    var currentMeet: String?
    
    // 先宣告一個屬性，用來存「使用者在 statusPicker 選到的結果」
    var currentStatus: String?
    
    // 用來存使用者最終選到的影片在沙盒中的「檔案路徑」
    var selectedVideoPath: String?
    
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
        
        // ✅ 設定 VideoView 的 Auto Layout
        videoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: eventView.bottomAnchor, constant: fieldSpacing),
            videoView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            videoView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60), // 避免 nameView 高度為 0
            
            // ✅ `NameView` 的 BottomAnchor 讓 `nameView` 正確計算 `contentSize`
//            nameView.bottomAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 20),
        ])
        
        if let videoLabel = videoLabel, let videoButton = videoButton {
            videoLabel.translatesAutoresizingMaskIntoConstraints = false
            videoButton.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                // `videoLabel` 置頂
                videoLabel.topAnchor.constraint(equalTo: videoView.topAnchor, constant: fieldSpacing),
                videoLabel.leadingAnchor.constraint(equalTo: videoView.leadingAnchor, constant: fieldSpacing),
                videoLabel.trailingAnchor.constraint(equalTo: videoView.trailingAnchor, constant: -fieldSpacing),
                videoLabel.heightAnchor.constraint(equalToConstant: labelHeight),

                // `eventTextView` 置於 `eventLabel` 下方
                videoButton.topAnchor.constraint(equalTo: videoLabel.bottomAnchor, constant: fieldSpacing),
                videoButton.leadingAnchor.constraint(equalTo: videoView.leadingAnchor, constant: fieldSpacing),
                videoButton.trailingAnchor.constraint(equalTo: videoView.trailingAnchor, constant: -fieldSpacing),
                
                // ✅ `eventView` 自動擴展，包住 `eventLabel` 和 `eventTextView`
                videoButton.bottomAnchor.constraint(equalTo: videoView.bottomAnchor, constant: -fieldSpacing),
                videoButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 100), // 避免 eventView 高度為 0
            ])
        }
        
        videoButton.contentHorizontalAlignment = .center
        videoButton.contentVerticalAlignment = .center
        videoButton.clipsToBounds = true

        // 2. 設定 contentMode 為 .scaleAspectFit
        videoButton.imageView?.contentMode = .scaleAspectFit

        // 3. (選擇性) 設定額外的 edgeInsets 讓圖片與按鈕邊緣留些空間
//        videoButton.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        // 1. 建立一個 configuration (可用 .plain()、.bordered()、.filled() 等)
        var config = UIButton.Configuration.plain()

        // 2. 設定圖片
        if let image = UIImage(named: "video-placeholder") {
            let halfImage = image.scaled(by: (videoButton.frame.width) / 600) // 縮小一半
            config.image = halfImage
        }
        
        // 圖片和文字的間距
        config.imagePadding = 8
        // 圖片擺放位置（leading、trailing、top、bottom）
        config.imagePlacement = .leading

        // 3. 設定整體內容的四邊內距
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)

        // 4. 指派給按鈕
        videoButton.configuration = config
        
        videoView.backgroundColor = .systemGray6

    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        print("📢 nameTextField.isUserInteractionEnabled = \(nameTextField.isUserInteractionEnabled)")
//        print("📢 nameTextField.isEnabled = \(nameTextField.isEnabled)")
//
//        print("📢 scrollView.frame:", scrollView.frame)
//        print("📢 scrollView.contentLayoutGuide.layoutFrame:", scrollView.contentLayoutGuide.layoutFrame)
//        print("📢 stackView.frame:", stackView.frame)
//        print("📢 nameView.frame:", nameView.frame)
//        print("📢 dateView.frame:", dateView.frame)
//        print("📢 dateLabel.frame:", dateLabel.frame)
//        print("📢 dateTextField.frame:", dateTextField.frame)
//        print("📢 locationView.frame:", locationView.frame)
//        print("📢 locationLabel.frame:", locationLabel.frame)
//        print("📢 locationTextField.frame:", locationTextField.frame)
//        print("📢 participantView.frame:", participantView.frame)
//        print("📢 participantLabel.frame:", participantLabel.frame)
//        print("📢 participantTextField.frame:", participantTextField.frame)
//        print("📢 meetView.frame:", meetView.frame)
//        print("📢 meetLabel.frame:", meetLabel.frame)
//        print("📢 meetPicker.frame:", meetPicker.frame)
//        print("📢 statusView.frame:", statusView.frame)
//        print("📢 statusLabel.frame:", statusLabel.frame)
//        print("📢 statusPicker.frame:", statusPicker.frame)
//        print("📢 eventView.frame:", eventView.frame)
//        print("📢 eventLabel.frame:", eventLabel.frame)
//        print("📢 eventTextView.frame:", eventTextView.frame)
//        print("📢 videoView.frame:", videoView.frame)
//        print("📢 videoLabel.frame:", videoLabel.frame)
//        print("📢 videoButton.frame:", videoButton.frame)
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
        newDating.location = locationTextField.text
        newDating.participant = participantTextField.text
        newDating.meet = self.currentMeet
        newDating.status = self.currentStatus
        newDating.event = eventTextView.text
        
        // 如果你有 selectedVideoPath，就存進 Core Data
        newDating.videoPath = self.selectedVideoPath

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
    
    @IBAction func videoButtonTapped(_ sender: Any) {
        // 1. 建立 PHPickerConfiguration
        var configuration = PHPickerConfiguration()
        configuration.filter = .videos  // 只挑選影片
        configuration.selectionLimit = 1 // 最多一次選 1 個

        // 2. 建立 PHPickerViewController
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self // 記得實作

        // 3. 顯示 picker
        present(picker, animated: true, completion: nil)
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

extension UIImage {
    /// 依指定 scale 做寬高等比縮放
    /// 例如 scale=0.5 就是縮小一半； scale=2.0 就是放大兩倍
    func scaled(by scale: CGFloat) -> UIImage? {
        guard scale > 0 else { return self }
        
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
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
            // 1. 取出選中的文字
            let selectedMeet = meetOptions[row]
            
            // 2. 存到我們預先宣告的 currentMeet
            self.currentMeet = selectedMeet
            
            print("選到的認識方式是：\(selectedMeet)")
            // 可以存在變數 e.g. self.currentMeet = selectedMeet
        } else if pickerView == statusPicker {
            let selectedStatus = statusOptions[row]
            self.currentStatus = selectedStatus
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
