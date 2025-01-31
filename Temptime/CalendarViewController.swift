//
//  CalendarViewController.swift
//  Temptime
//
//  Created by 游哲維 on 2025/1/31.
//

import UIKit
import FSCalendar

class CalendarViewController: UIViewController, FSCalendarDelegate, FSCalendarDataSource {
    
    @IBOutlet weak var calendarView: FSCalendar!

    override func viewDidLoad() {
        super.viewDidLoad()
        calendarView.delegate = self
        calendarView.dataSource = self
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        print("選擇的日期：\(date)")
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
