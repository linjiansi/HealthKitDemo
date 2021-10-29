//
//  ViewController.swift
//  HealthKitDemo
//
//  Created by 林健司 on 2021/10/06.
//

import UIKit
import HealthKit

class ViewController: UIViewController {

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    let calendar = Calendar(identifier: .gregorian)

    var dataComponents: DateComponents {
        calendar.dateComponents(in: .current, from: Date())
    }

    var startDate: Date {
        DateComponents(
            calendar: calendar,
            timeZone: .current,
            year: dataComponents.year,
            month: dataComponents.month,
            day: dataComponents.day
        ).date!
    }

    var endDate: Date {
        calendar.date(byAdding: DateComponents(day: 1), to: startDate)!
    }

    private let healthStore = HKHealthStore()
    private var statisticsCollection: HKStatisticsCollection?

    private var timer: Timer {
        .scheduledTimer(
            timeInterval: 5.0,
            target: self,
            selector: #selector(self.updateRealTimeStepCounts),
            userInfo: nil,
            repeats: true
        )
    }

    @IBOutlet private weak var stepCountLabel: UILabel!
    @IBOutlet private weak var realTimeStepCount: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        let readType = Set([HKObjectType.quantityType(forIdentifier: .stepCount)!])
        healthStore.requestAuthorization(toShare: [], read: readType) { _, _ in }

        timer.fire()
    }

    @IBAction func startCountingRealTimeStepCount(_ sender: Any) {
        timer.fire()
    }

    @IBAction func StopCountingRealTimeStepCount(_ sender: Any) {
        timer.invalidate()
    }

    @IBAction func dataPickerValueChanged(_ sender: UIDatePicker) {
        let calendar = Calendar(identifier: .gregorian)
        let dataComponents = calendar.dateComponents(in: .current, from: sender.date)
        let startDate = DateComponents(
            calendar: calendar,
            timeZone: .current,
            year: dataComponents.year,
            month: dataComponents.month,
            day: dataComponents.day
        ).date!
        let endDate = calendar.date(byAdding: DateComponents(day: 1), to: startDate)!
        self.updateStepCounts(start: startDate, end: endDate)
    }

    private func updateStepCounts(start: Date, end: Date) {
        self.getStepCounts(from: start, to: end) { query, statistics, error in
            DispatchQueue.main.async {
                if let value = statistics?.sumQuantity()?.doubleValue(for: .count()) {
                    self.stepCountLabel.text = "\(start)\n \(Int(value)) 歩"
                } else {
                    self.stepCountLabel.text = "取得できませんでした"

                }
            }
        }
    }

    @objc private func updateRealTimeStepCounts() {
        self.getStepCounts(from: self.startDate, to: self.endDate) { query, statistics, error in
            DispatchQueue.main.async {
                if let value = statistics?.sumQuantity()?.doubleValue(for: .count()) {
                    self.realTimeStepCount.text = "Now: \(Int(value)) 歩"
                } else {
                    self.realTimeStepCount.text = "取得できませんでした"
                }
            }
        }
    }

    private func getStepCounts(from start: Date, to end: Date, completion handler: @escaping (HKStatisticsQuery, HKStatistics?, Error?) -> Void) {
        let type = HKSampleType.quantityType(forIdentifier: .stepCount)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum, completionHandler: handler)
        healthStore.execute(query)
    }

}

