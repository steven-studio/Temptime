//
//  AddPickupViewController.swift
//  Temptime
//
//  Created by 游哲維 on 2025/2/1.
//

import UIKit
import AVFoundation
import PhotosUI
import FirebaseFirestore
import SwiftUICore
import FirebaseStorage
import WatchConnectivity

extension AddPickupViewController: PHPickerViewControllerDelegate {

    func showPHPicker() {
        // 1. 建立 PHPickerConfiguration
        var configuration = PHPickerConfiguration()
        configuration.filter = .videos  // 只顯示影片
        configuration.selectionLimit = 1 // 一次只選一個

        // 2. 建立 PHPickerViewController
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self

        // 3. 顯示
        present(picker, animated: true, completion: nil)
    }
    
    // 4. 實作 PHPickerViewControllerDelegate
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        // 關閉選擇器
        picker.dismiss(animated: true, completion: nil)

        guard let itemProvider = results.first?.itemProvider else {
            print("⚠️ 使用者沒有選任何影片")
            return
        }
        
        // 檢查是否能讀取影片
        if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            // 透過 loadFileRepresentation，把影片檔案複製到 App 的 tmp
            itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] (url, error) in
                guard let self = self, let sourceURL = url else { return }
                if let error = error {
                    print("❌ 載入影片失敗: \(error)")
                    return
                }
                
                // 接著我們要把 tmp 資料移到 Documents，以保留檔案
                do {
                    let fileManager = FileManager.default
                    let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

                    // 幫檔案取個名稱
                    let newFileName = "pickupVideo\(Date().timeIntervalSince1970).mov"
                    let destinationURL = documents.appendingPathComponent(newFileName)

                    // 若該路徑已存在就刪除 (避免衝突)
                    if fileManager.fileExists(atPath: destinationURL.path) {
                        try fileManager.removeItem(at: destinationURL)
                    }

                    try fileManager.copyItem(at: sourceURL, to: destinationURL)
                    
                    // 在主執行緒更新 UI
                    DispatchQueue.main.async {
                        // 假設你想把複製完的路徑存到某個屬性
                        self.videoLocalPath = destinationURL.path
                        print("✅ 選到影片路徑: \(self.videoLocalPath ?? "nil")")
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

class AddPickupViewController: UIViewController, AVAudioRecorderDelegate {

    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    
    @IBOutlet weak var locationView: UIView!
    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var locationNoteView: UIView!
    @IBOutlet weak var locationNoteLabel: UILabel!
    @IBOutlet weak var locationNoteTextField: UITextField!
    
    @IBOutlet weak var openingView: UIView!
    @IBOutlet weak var openingLabel: UILabel!
    @IBOutlet weak var openingTextField: UITextField!
    
    @IBOutlet weak var recordingView: UIView!
    @IBOutlet weak var recordingLabel: UILabel!
    @IBOutlet weak var recordingButton: UIButton!
    @IBOutlet weak var recordingTextView: UITextView!
    
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var videoLabel: UILabel!
    @IBOutlet weak var videoButton: UIButton!
    
    @IBOutlet weak var hasPickUpNumberView: UIView!
    @IBOutlet weak var hasPickUpNumberLabel: UILabel!
    @IBOutlet weak var hasPickUpNumberButton: UIButton!
    @IBOutlet weak var hasNotPickUpNumberButton: UIButton!
    
    @IBOutlet weak var hasInstantDatingView: UIView!
    @IBOutlet weak var hasInstantDatingLabel: UILabel!
    @IBOutlet weak var hasInstantDatingButton: UIButton!
    @IBOutlet weak var hasNotInstantDatingButton: UIButton!
    
    // 1. 管理錄音器
    var audioRecorder: AVAudioRecorder?
    
    private var audioFileURL: URL?

    // 2. 用來判斷現在是否在錄音
    var isRecording = false
    
    // 1️⃣ 用一個屬性來存「地點搜尋」TextField（iOS 13+ = UISearchTextField, fallback = UITextField）
    var locationSearchField: UIView?
    
    // 用來儲存使用者最後選到的本地檔案路徑
    var videoLocalPath: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        modalPresentationStyle = .fullScreen // ✅ 設定為全螢幕
        
        saveButton.frame = CGRect(
            x: view.bounds.width - saveButton.frame.width - 16,
            y: 60,
            width: 58, // 設定按鈕寬度
            height: 35  // 設定按鈕高度
        )
        
        // 2️⃣ 建立 TextField (依版本) 並先加到 locationView (或後面再加)
        if #available(iOS 13.0, *) {
            let searchTF = UISearchTextField()
            searchTF.placeholder = "搜尋文字"
            // 其他個性化設定...
            searchTF.backgroundColor = .systemGray6

            // 加到 locationView
            locationView.addSubview(searchTF)
            
            // 記得存起來
            self.locationSearchField = searchTF

        } else {
            // Fallback: 用 UITextField
            let fallbackTF = UITextField()
            fallbackTF.placeholder = "搜尋文字 (舊系統)"
            fallbackTF.borderStyle = .roundedRect
            
            locationView.addSubview(fallbackTF)
            self.locationSearchField = fallbackTF
        }

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let fieldSpacing: CGFloat = 8
        let labelHeight: CGFloat = 20
        let textFieldHeight: CGFloat = 35
        let buttonHeight: CGFloat = 50
        
        scrollView.frame = CGRect(
            x: 0,
            y: 103,
            width: view.bounds.width,  // ✅ 確保寬度填滿螢幕
            height: view.bounds.height - 103
        )
        
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
        
        // ✅ 設定 locationView 的 Auto Layout
        locationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            locationView.topAnchor.constraint(equalTo: stackView.topAnchor),
            locationView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            locationView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            locationView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60), // 避免 nameView 高度為 0
        ])

        if let locationLabel = locationLabel, let locationSearchField = locationSearchField {
            locationLabel.translatesAutoresizingMaskIntoConstraints = false
            locationSearchField.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                // Name
                locationLabel.topAnchor.constraint(equalTo: locationView.topAnchor, constant: fieldSpacing),
                locationLabel.leadingAnchor.constraint(equalTo: locationView.leadingAnchor, constant: fieldSpacing),
                locationLabel.trailingAnchor.constraint(equalTo: locationView.trailingAnchor, constant: -fieldSpacing),
                locationLabel.heightAnchor.constraint(equalToConstant: labelHeight),

                locationSearchField.topAnchor.constraint(equalTo: locationLabel.bottomAnchor, constant: fieldSpacing),
                locationSearchField.leadingAnchor.constraint(equalTo: locationView.leadingAnchor, constant: fieldSpacing),
                locationSearchField.trailingAnchor.constraint(equalTo: locationView.trailingAnchor, constant: -fieldSpacing),
                locationSearchField.heightAnchor.constraint(equalToConstant: textFieldHeight),
                
                // **最重要的修正：讓 nameView 正確包住 nameTextField**
                locationSearchField.bottomAnchor.constraint(equalTo: locationView.bottomAnchor, constant: -8)
            ])
        }
        
        locationView.backgroundColor = .systemGray6
        
        // ✅ 設定 locationNoteView 的 Auto Layout
        locationNoteView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            locationNoteView.topAnchor.constraint(equalTo: locationView.bottomAnchor),
            locationNoteView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            locationNoteView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            locationNoteView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60), // 避免 nameView 高度為 0
        ])
        
        if let locationNoteLabel = locationNoteLabel, let locationNoteTextField = locationNoteTextField {
            locationNoteLabel.translatesAutoresizingMaskIntoConstraints = false
            locationNoteTextField.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                // `videoLabel` 置頂
                locationNoteLabel.topAnchor.constraint(equalTo: locationNoteView.topAnchor, constant: fieldSpacing),
                locationNoteLabel.leadingAnchor.constraint(equalTo: locationNoteView.leadingAnchor, constant: fieldSpacing),
                locationNoteLabel.trailingAnchor.constraint(equalTo: locationNoteView.trailingAnchor, constant: -fieldSpacing),
                locationNoteLabel.heightAnchor.constraint(equalToConstant: labelHeight),

                // `eventTextView` 置於 `eventLabel` 下方
                locationNoteTextField.topAnchor.constraint(equalTo: locationNoteLabel.bottomAnchor, constant: fieldSpacing),
                locationNoteTextField.leadingAnchor.constraint(equalTo: locationNoteView.leadingAnchor, constant: fieldSpacing),
                locationNoteTextField.trailingAnchor.constraint(equalTo: locationNoteView.trailingAnchor, constant: -fieldSpacing),
                
                // ✅ `eventView` 自動擴展，包住 `eventLabel` 和 `eventTextView`
                locationNoteTextField.bottomAnchor.constraint(equalTo: locationNoteView.bottomAnchor, constant: -fieldSpacing),
                locationNoteTextField.heightAnchor.constraint(equalToConstant: textFieldHeight), // 避免 eventView 高度為 0
            ])
        }

        locationNoteView.backgroundColor = .systemGray6
        
        // ✅ 設定 openingView 的 Auto Layout
        openingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            openingView.topAnchor.constraint(equalTo: locationNoteView.bottomAnchor),
            openingView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            openingView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            openingView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60), // 避免 nameView 高度為 0
        ])
        
        if let openingLabel = openingLabel, let openingTextField = openingTextField {
            openingLabel.translatesAutoresizingMaskIntoConstraints = false
            openingTextField.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                // `openingLabel` 置頂
                openingLabel.topAnchor.constraint(equalTo: openingView.topAnchor, constant: fieldSpacing),
                openingLabel.leadingAnchor.constraint(equalTo: openingView.leadingAnchor, constant: fieldSpacing),
                openingLabel.trailingAnchor.constraint(equalTo: openingView.trailingAnchor, constant: -fieldSpacing),
                openingLabel.heightAnchor.constraint(equalToConstant: labelHeight),

                // `openingTextField` 置於 `openingLabel` 下方
                openingTextField.topAnchor.constraint(equalTo: openingLabel.bottomAnchor, constant: fieldSpacing),
                openingTextField.leadingAnchor.constraint(equalTo: openingView.leadingAnchor, constant: fieldSpacing),
                openingTextField.trailingAnchor.constraint(equalTo: openingView.trailingAnchor, constant: -fieldSpacing),
                
                // ✅ `eventView` 自動擴展，包住 `eventLabel` 和 `eventTextView`
                openingTextField.bottomAnchor.constraint(equalTo: openingView.bottomAnchor, constant: -fieldSpacing),
                openingTextField.heightAnchor.constraint(equalToConstant: textFieldHeight), // 避免 eventView 高度為 0
            ])
        }
        
        openingView.backgroundColor = .systemGray6
        
        // 假設已有一個 IBOutlet: recordButton
        // 先把寬高鎖定成圓形
        recordingButton.layer.cornerRadius = recordingButton.frame.size.height / 2
        recordingButton.backgroundColor = .red

        // (選擇性) 加外框
        recordingButton.layer.borderWidth = 4
        recordingButton.layer.borderColor = UIColor.lightGray.cgColor
        
        // ✅ 設定 recordingView 的 Auto Layout
        recordingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            recordingView.topAnchor.constraint(equalTo: openingView.bottomAnchor),
            recordingView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            recordingView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            recordingView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60), // 避免 nameView 高度為 0
        ])

        if let recordingLabel = recordingLabel, let recordingButton = recordingButton, let recordingTextView = recordingTextView {
            recordingLabel.translatesAutoresizingMaskIntoConstraints = false
            recordingButton.translatesAutoresizingMaskIntoConstraints = false
            recordingTextView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                // `recordingLabel` 置頂
                recordingLabel.topAnchor.constraint(equalTo: recordingView.topAnchor, constant: fieldSpacing),
                recordingLabel.leadingAnchor.constraint(equalTo: recordingView.leadingAnchor, constant: fieldSpacing),
                recordingLabel.trailingAnchor.constraint(equalTo: recordingView.trailingAnchor, constant: -fieldSpacing),
                recordingLabel.heightAnchor.constraint(equalToConstant: labelHeight),

                // `recordingButton` 置於 `recordingLabel` 下方
                recordingButton.topAnchor.constraint(equalTo: recordingLabel.bottomAnchor, constant: fieldSpacing),
                recordingButton.centerXAnchor.constraint(equalTo: recordingView.centerXAnchor),
                // ✅ `recordingView` 自動擴展，包住 `recordingLabel` 和 `recordingTextView`
                recordingButton.bottomAnchor.constraint(equalTo: recordingTextView.topAnchor, constant: -15),
                recordingButton.widthAnchor.constraint(equalToConstant: 60),
                recordingButton.heightAnchor.constraint(equalToConstant: 60),

                // `recordingTextView` 置於 `recordingButton` 下方
                recordingTextView.topAnchor.constraint(equalTo: recordingButton.bottomAnchor, constant: 15),
                recordingTextView.leadingAnchor.constraint(equalTo: recordingView.leadingAnchor, constant: fieldSpacing),
                recordingTextView.trailingAnchor.constraint(equalTo: recordingView.trailingAnchor, constant: -fieldSpacing),
                
                // ✅ `recordingView` 自動擴展，包住 `recordingLabel` 和 `recordingTextView`
                recordingTextView.bottomAnchor.constraint(equalTo: recordingView.bottomAnchor, constant: -fieldSpacing),
                recordingTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100), // 避免 eventView 高度為 0

            ])
        }
        
        recordingView.backgroundColor = .systemGray6
        
        // ✅ 設定 hasPickUpNumberView 的 Auto Layout
        hasPickUpNumberView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hasPickUpNumberView.topAnchor.constraint(equalTo: recordingView.bottomAnchor, constant: fieldSpacing),
            hasPickUpNumberView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            hasPickUpNumberView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            hasPickUpNumberView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60), // 避免 nameView 高度為 0
            
            // ✅ `NameView` 的 BottomAnchor 讓 `nameView` 正確計算 `contentSize`
//            nameView.bottomAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 20),
        ])
        
        if let hasPickUpNumberLabel = hasPickUpNumberLabel, let hasPickUpNumberButton = hasPickUpNumberButton, let hasNotPickUpNumberButton = hasNotPickUpNumberButton {
            hasPickUpNumberLabel.translatesAutoresizingMaskIntoConstraints = false
            hasPickUpNumberButton.translatesAutoresizingMaskIntoConstraints = false
            hasNotPickUpNumberButton.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                // `hasPickUpNumberLabel` 置頂
                hasPickUpNumberLabel.topAnchor.constraint(equalTo: hasPickUpNumberView.topAnchor, constant: fieldSpacing),
                hasPickUpNumberLabel.leadingAnchor.constraint(equalTo: hasPickUpNumberView.leadingAnchor, constant: fieldSpacing),
                hasPickUpNumberLabel.trailingAnchor.constraint(equalTo: hasPickUpNumberView.trailingAnchor, constant: -fieldSpacing),
                hasPickUpNumberLabel.heightAnchor.constraint(equalToConstant: labelHeight),
                
                hasPickUpNumberButton.topAnchor.constraint(equalTo: hasPickUpNumberLabel.bottomAnchor, constant: fieldSpacing),
                hasPickUpNumberButton.leadingAnchor.constraint(equalTo: hasPickUpNumberView.leadingAnchor, constant: fieldSpacing),
                hasPickUpNumberButton.trailingAnchor.constraint(equalTo: hasPickUpNumberView.centerXAnchor, constant: -fieldSpacing),
                hasPickUpNumberButton.heightAnchor.constraint(equalToConstant: buttonHeight),
                hasPickUpNumberButton.bottomAnchor.constraint(equalTo: hasPickUpNumberView.bottomAnchor, constant: -fieldSpacing),
                
                hasNotPickUpNumberButton.topAnchor.constraint(equalTo: hasPickUpNumberLabel.bottomAnchor, constant: fieldSpacing),
                hasNotPickUpNumberButton.leadingAnchor.constraint(equalTo: hasPickUpNumberView.centerXAnchor, constant: fieldSpacing),
                hasNotPickUpNumberButton.trailingAnchor.constraint(equalTo: hasPickUpNumberView.trailingAnchor, constant: -fieldSpacing),
                hasNotPickUpNumberButton.heightAnchor.constraint(equalToConstant: buttonHeight),
                hasNotPickUpNumberButton.bottomAnchor.constraint(equalTo: hasPickUpNumberView.bottomAnchor, constant: -fieldSpacing),
            ])
        }

        hasPickUpNumberView.backgroundColor = .systemGray6
        
        // ✅ 設定 hasInstantDatingView 的 Auto Layout
        hasInstantDatingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hasInstantDatingView.topAnchor.constraint(equalTo: hasPickUpNumberView.bottomAnchor, constant: fieldSpacing),
            hasInstantDatingView.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            hasInstantDatingView.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            hasInstantDatingView.heightAnchor.constraint(greaterThanOrEqualToConstant: 60), // 避免 nameView 高度為 0
        ])
        
        if let hasInstantDatingLabel = hasInstantDatingLabel, let hasInstantDatingButton = hasInstantDatingButton, let hasNotInstantDatingButton = hasNotInstantDatingButton {
            hasInstantDatingLabel.translatesAutoresizingMaskIntoConstraints = false
            hasInstantDatingButton.translatesAutoresizingMaskIntoConstraints = false
            hasNotInstantDatingButton.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                // `videoLabel` 置頂
                hasInstantDatingLabel.topAnchor.constraint(equalTo: hasInstantDatingView.topAnchor, constant: fieldSpacing),
                hasInstantDatingLabel.leadingAnchor.constraint(equalTo: hasInstantDatingView.leadingAnchor, constant: fieldSpacing),
                hasInstantDatingLabel.trailingAnchor.constraint(equalTo: hasInstantDatingView.trailingAnchor, constant: -fieldSpacing),
                hasInstantDatingLabel.heightAnchor.constraint(equalToConstant: labelHeight),
                
                hasInstantDatingButton.topAnchor.constraint(equalTo: hasInstantDatingLabel.bottomAnchor, constant: fieldSpacing),
                hasInstantDatingButton.leadingAnchor.constraint(equalTo: hasInstantDatingView.leadingAnchor, constant: fieldSpacing),
                hasInstantDatingButton.trailingAnchor.constraint(equalTo: hasInstantDatingView.centerXAnchor, constant: -fieldSpacing),
                hasInstantDatingButton.heightAnchor.constraint(equalToConstant: buttonHeight),
                hasInstantDatingButton.bottomAnchor.constraint(equalTo: hasInstantDatingView.bottomAnchor, constant: -fieldSpacing),
                
                hasNotInstantDatingButton.topAnchor.constraint(equalTo: hasInstantDatingLabel.bottomAnchor, constant: fieldSpacing),
                hasNotInstantDatingButton.leadingAnchor.constraint(equalTo: hasInstantDatingView.centerXAnchor, constant: fieldSpacing),
                hasNotInstantDatingButton.trailingAnchor.constraint(equalTo: hasInstantDatingView.trailingAnchor, constant: -fieldSpacing),
                hasNotInstantDatingButton.heightAnchor.constraint(equalToConstant: buttonHeight),
                hasNotInstantDatingButton.bottomAnchor.constraint(equalTo: hasInstantDatingView.bottomAnchor, constant: -fieldSpacing),

            ])
        }

        
        hasInstantDatingView.backgroundColor = .systemGray6

        // ✅ 設定 VideoView 的 Auto Layout
        videoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            videoView.topAnchor.constraint(equalTo: hasInstantDatingView.bottomAnchor, constant: fieldSpacing),
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

        print("📢 scrollView.frame:", scrollView.frame)
        print("📢 scrollView.contentLayoutGuide.layoutFrame:", scrollView.contentLayoutGuide.layoutFrame)
        print("📢 stackView.frame:", stackView.frame)
        print("📢 locationView.frame:", locationView.frame)
        print("📢 locationLabel.frame:", locationLabel.frame)
        print("📢 locationNoteView.frame:", locationNoteView.frame)
        print("📢 locationNoteLabel.frame:", locationNoteLabel.frame)
        print("📢 locationNoteTextField.frame:", locationNoteTextField.frame)
        print("📢 openingView.frame:", openingView.frame)
        print("📢 openingLabel.frame:", openingLabel.frame)
        print("📢 openingTextField.frame:", openingTextField.frame)
        print("📢 recordingView.frame:", recordingView.frame)
        print("📢 recordingLabel.frame:", recordingLabel.frame)
        print("📢 recordingButton.frame:", recordingButton.frame)
        print("📢 recordingTextView.frame:", recordingTextView.frame)
        print("📢 hasPickUpNumberView.frame:", hasPickUpNumberView.frame)
        print("📢 hasPickUpNumberLabel.frame:", hasPickUpNumberLabel.frame)
        print("📢 hasPickUpNumberButton.frame:", hasPickUpNumberButton.frame)
        print("📢 hasNotPickUpNumberButton.frame:", hasNotPickUpNumberButton.frame)
        print("📢 hasInstantDatingView.frame:", hasInstantDatingView.frame)
        print("📢 hasInstantDatingLabel.frame:", hasInstantDatingLabel.frame)
        print("📢 hasInstantDatingButton.frame:", hasInstantDatingButton.frame)
        print("📢 hasNotInstantDatingButton.frame:", hasNotInstantDatingButton.frame)
        print("📢 videoView.frame:", videoView.frame)
        print("📢 videoLabel.frame:", videoLabel.frame)
        print("📢 videoButton.frame:", videoButton.frame)
    }


    @IBAction func cancelTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func hasPickupNumberButtonTapped(_ sender: Any) {
        // 1. 先把 hasPickupNumberButton 設為已選
        hasPickUpNumberButton.isSelected = true
        // 2. 把 hasNotPickupNumberButton 設為未選
        hasNotPickUpNumberButton.isSelected = false
    }
    
    @IBAction func hasNotPickupNumberButtonTapped(_ sender: Any) {
        // 1. 把 hasNotPickupNumberButton 設為已選
        hasNotPickUpNumberButton.isSelected = true
        // 2. 把 hasPickupNumberButton 設為未選
        hasPickUpNumberButton.isSelected = false
    }
    
    @IBAction func hasInstantDatingButtonTapped(_ sender: Any) {
        hasInstantDatingButton.isSelected = true
        hasNotInstantDatingButton.isSelected = false
    }
    
    @IBAction func hasNotInstantDatingButtonTapped(_ sender: Any) {
        hasNotInstantDatingButton.isSelected = true
        hasInstantDatingButton.isSelected = false
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func recordButtonTapped(_ sender: Any) {
        if isRecording {
            // 如果正在錄音，則停止錄音
            stopRecording()
            
            if WCSession.default.isReachable {
                WCSession.default.sendMessage(
                    ["command": "stopHeartRate"],
                    replyHandler: nil,
                    errorHandler: nil
                )
            }
            
        } else {
            // 如果沒在錄音，則開始錄音
            startRecording()
            
            if WCSession.default.isReachable {
                WCSession.default.sendMessage(
                    ["command": "startHeartRate"],
                    replyHandler: nil,
                    errorHandler: nil
                )
            }

        }
    }
    
    func startRecording() {
        // 1. 要先詢問錄音權限
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if allowed {
                    // 有權限，開始錄音流程
                    self.setupAndStartRecording()
                } else {
                    // 沒有麥克風權限
                    print("使用者拒絕錄音權限")
                    // 你可以在這裡彈出提示框提醒使用者去設定裡開啟
                }
            }
        }
    }

    private func setupAndStartRecording() {
        guard let audioFileURL = audioFileURL else { return }

        // 2. 設定 audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // 設定 category、mode
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("無法設定 Audio Session: \(error.localizedDescription)")
            return
        }

        // 3. 錄音設定（可自行調整）
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            // 4. 建立 AVAudioRecorder
            audioRecorder = try AVAudioRecorder(url: audioFileURL, settings: settings)
            audioRecorder?.delegate = self // 若要監聽錄音完成，需 conform to AVAudioRecorderDelegate
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            
            isRecording = true
            recordingButton.setTitle("停止錄音", for: .normal)
            print("開始錄音：\(audioFileURL)")
        } catch {
            print("建立錄音器失敗: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        
        // 停止後還原 UI
        isRecording = false
        recordingButton.setTitle("開始錄音", for: .normal)
        
        // 將 Audio Session 設回 Inactive（若無其它音訊需求）
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("無法停用音訊 Session：\(error.localizedDescription)")
        }
        
        print("錄音已停止")
    }
    
    @IBAction func savePickup(_ sender: Any) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let newPickUp = PickUp(context: context)

        // 對應 UI
        newPickUp.location = (locationSearchField as? UITextField)?.text ?? ""
        newPickUp.locationNote = locationNoteTextField.text
        newPickUp.opening = openingTextField.text
        newPickUp.recordingText = recordingTextView.text
        newPickUp.audioPath = audioFileURL?.path // or nil
        newPickUp.videoPath = self.videoLocalPath
        newPickUp.hasPickUpNumber = hasPickUpNumberButton.isSelected
        newPickUp.hasInstantDating = hasInstantDatingButton.isSelected
        newPickUp.createdAt = Date()

        do {
            try context.save()
            // 例如儲存成功就關閉視圖
            dismiss(animated: true, completion: nil)
        } catch {
            print("❌")
        }
        
        // Firestore
        let db = Firestore.firestore()

        // 準備要上傳的欄位
        let pickupData: [String: Any] = [
            "location": newPickUp.location ?? "",
            "locationNote": newPickUp.locationNote ?? "",
            "opening": newPickUp.opening ?? "",
            "recordingText": newPickUp.recordingText ?? "",
            "audioPath": newPickUp.audioPath ?? "",
            "videoPath": newPickUp.videoPath ?? "",
            "hasPickUpNumber": newPickUp.hasPickUpNumber,
            "hasInstantDating": newPickUp.hasInstantDating,
            // Firestore 也可存 Timestamp；可以自行轉成 Date 物件
            "createdAt": Timestamp(date: newPickUp.createdAt ?? Date())
        ]

        // 新增一筆文件到 "pickups" 集合裡
        db.collection("pickups").addDocument(data: pickupData) { error in
            if let error = error {
                print("❌ Firestore 寫入失敗: \(error.localizedDescription)")
            } else {
                print("✅ Firestore 寫入成功")
            }

            // 例如寫完之後再關閉畫面
            self.dismiss(animated: true, completion: nil)
        }
        
        // 假設你想同時把檔案上傳 Firebase Storage, 再得到下載URL
        if let localPath = self.videoLocalPath {
            uploadVideoToFirebase(localPath) { downloadURL in
                // 拿到 downloadURL 後, 存到 Firestore
                self.savePickupToFirestore(downloadURL: downloadURL)
            }
        } else {
            // 沒有選影片 -> 直接 save
            self.savePickupToFirestore(downloadURL: nil)
        }
    }
    
    func uploadVideoToFirebase(_ localPath: String, completion: @escaping (String?) -> Void) {
        let storageRef = Storage.storage().reference()
        // 你可以命名檔案路徑 e.g. "videos/\(UUID().uuidString).mov"
        let fileName = "videos/\(UUID().uuidString).mov"
        let videoRef = storageRef.child(fileName)
        
        let fileURL = URL(fileURLWithPath: localPath)
        let uploadTask = videoRef.putFile(from: fileURL, metadata: nil) { metadata, error in
            if let error = error {
                print("❌ 上傳失敗: \(error)")
                completion(nil)
                return
            }
            // 取得下載 URL
            videoRef.downloadURL { url, error in
                if let error = error {
                    print("❌ 下載 URL 取得失敗: \(error)")
                    completion(nil)
                    return
                }
                if let urlString = url?.absoluteString {
                    print("✅ 影片上傳成功, 下載URL: \(urlString)")
                    completion(urlString) // 回傳給外面, 之後存到 Firestore
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    /// 把本地 `PickUp` 資料 (含 downloadURL) 寫入 Firestore
    func savePickupToFirestore(downloadURL: String?) {
        let db = Firestore.firestore()
        
        // 取用你剛剛建立的 newPickUp (Core Data)
        // 或者把 pickUpData 直接存在屬性
        // 在這裡，以參數方式或屬性方式都行。範例中我們直接使用 method scope 的 variables
        // 下列用 local 變數 illustration

        // 準備要上傳的欄位
        let pickupData: [String: Any] = [
            "location": (locationSearchField as? UITextField)?.text ?? "",
            "locationNote": locationNoteTextField.text ?? "",
            "opening": openingTextField.text ?? "",
            "recordingText": recordingTextView.text ?? "",
            "audioPath": audioFileURL?.path ?? "",
            // downloadURL 可能是 nil，如果沒有上傳影片
            "videoPath": downloadURL ?? "",
            "hasPickUpNumber": hasPickUpNumberButton.isSelected,
            "hasInstantDating": hasInstantDatingButton.isSelected,
            "createdAt": Timestamp(date: Date())
        ]

        // 新增一筆文件到 "pickups" 集合裡
        db.collection("pickups").addDocument(data: pickupData) { error in
            if let error = error {
                print("❌ Firestore 寫入失敗: \(error.localizedDescription)")
            } else {
                print("✅ Firestore 寫入成功")
            }

            // （可依需求決定是否此時才 dismiss View ）
            self.dismiss(animated: true, completion: nil)
        }
    }
}
