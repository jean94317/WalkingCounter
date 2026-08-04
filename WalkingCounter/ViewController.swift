//
//  ViewController.swift
//  WalkingCounter
//
//  Created by 曉君 on 2026/7/22.
//

import UIKit
import HealthKit
class ViewController: UIViewController,UIGestureRecognizerDelegate {

    @IBOutlet weak var sentBtn: UIButton!
    @IBOutlet weak var datepicker: UIDatePicker!
    @IBOutlet weak var walkTextField: UITextField!
    @IBOutlet weak var showLabel: UILabel!
    var nowSteps: Int = 0
    let healthStore = HKHealthStore()
    let stepArr = [100,300,500,1000,3000,5000]
    let stepType = HKQuantityType.quantityType(
        forIdentifier: .stepCount
    )!
    var saveDate : Date! = Date()
    override func viewDidLoad() {
        super.viewDidLoad()
        if HKHealthStore.isHealthDataAvailable() {
            print("支援 HealthKit")
            healthStore.requestAuthorization(
                toShare: [stepType],
                read: [stepType]
            ) { success, error in
                
                if success {
                    print("取得寫入資料授權")
                } else {
                    print(error?.localizedDescription ?? "")
                }
            }
        }
        self.walkTextField.delegate = self
        getTodaySteps()
        setDatePicker()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        // 允許點擊時不干擾其他控制項（如按鈕）的點擊事件
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    func setDatePicker(){
        self.datepicker.maximumDate = Date()
    }
    
    @objc func handleTap() {
        view.endEditing(true)
    }

    @IBAction func inputWalkCount(_ sender: UIButton) {
        if self.walkTextField.text != ""{
            let count = Int(self.walkTextField.text!)!
            //增加步數
            print("增加部署：\(count)")
            self.addSteps(count)
        }
        self.walkTextField.text = ""
        self.walkTextField.resignFirstResponder()
        self.sentBtn.backgroundColor = .systemGray
    }
    
    @IBAction func returnStep(_ sender: UIButton) {
        setDatePicker()
        getTodaySteps()
    }
    
    @IBAction func randomStep(_ sender: UIButton) {
        self.walkTextField.text = "\(Int.random(in: 1...1000))"
        self.sentBtn.backgroundColor = .systemBlue
    }
    
    @IBAction func setStep(_ sender: UIButton) {
        let step = sender.titleLabel?.text
        self.walkTextField.text = step
        self.sentBtn.backgroundColor = .systemBlue
    }
    
    @IBAction func setSaveDate(_ sender: UIDatePicker) {
        let date = sender.date
        self.saveDate = date
    }
    //取得當日步數
    func getTodaySteps() {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date())

        let query = HKStatisticsQuery(quantityType: stepType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, result, error in
            guard let result = result,
                  let sum = result.sumQuantity()
            else {
                return
            }

            let steps = sum.doubleValue(
                for: HKUnit.count()
            )
            DispatchQueue.main.async {
                print("今天步數：\(Int(steps))")
                self.nowSteps = Int(steps)
                self.showLabel.text = "\(self.nowSteps)"
            }
        }
        healthStore.execute(query)
        
        //2. 依照時間排序（最新的在前面或後面）
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        // 3. 建立樣本查詢
        let query1 = HKSampleQuery(
            sampleType: stepType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit, //不限制筆數，或填入數字（例如 10）限制只抓前 10 筆
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            guard let samples = samples as? [HKQuantitySample], error == nil else {
                print("讀取步數明細失敗: \(error?.localizedDescription ?? "")")
                return
            }
            
            print("--- 取得詳細步數紀錄（共 \(samples.count) 筆）---")
            
            if samples.count > 0{
                var saveStartDate = Calendar.current.startOfDay(for: Date())
                self.saveDate = saveStartDate
                for num in 0..<samples.count {
                    let sample = samples[num]
                    let steps = sample.quantity.doubleValue(for: HKUnit.count())
                    let start = sample.startDate
                    let end = sample.endDate
                    if start > self.saveDate {
                        break
                    }else{
                        self.saveDate = end.addingTimeInterval(60)
                    }
                    print("步數: \(Int(steps)) 步 | 時間: \(start) ~ \(end)")
                }
            }else{
                let calendar = Calendar.current
                self.saveDate = calendar.startOfDay(for: Date())
            }
            
            if self.saveDate > Date() {
                self.saveDate = Date()
            }
            DispatchQueue.main.async {
                self.datepicker.date = self.saveDate
//                self.datepicker.minimumDate = self.saveDate
            }
        }
        
        healthStore.execute(query1)
    }
    
    //增加步數
    func addSteps(_ steps: Int){
        let quantity = HKQuantity(unit: HKUnit.count(), doubleValue: Double(steps))
        let calendar = Calendar.current
        var startDate = calendar.startOfDay(for: Date())
        let sample = HKQuantitySample(type: stepType,
                                      quantity: quantity,
                                      start: self.saveDate,
                                      end: self.saveDate)

        healthStore.save(sample) { success, error in
            if success {
                print("成功增加 \(steps) 步")
                self.getTodaySteps()
            } else {
                print(error?.localizedDescription ?? "")
            }
        }
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if textField.text != ""{
            self.sentBtn.backgroundColor = .systemBlue
        }else{
            self.sentBtn.backgroundColor = .systemGray
        }
    }
}
