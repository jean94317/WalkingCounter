//
//  DropDownList.swift
//  DropDownTest
//
//  Created by 曉君 on 2026/7/1.
//

import UIKit

class DropDownList: UIView, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView()
    var menuContainerView: UIView?
    var options: [String] = [] {
        didSet { tableView.reloadData() }
    }
    //選項的開啟狀態
    var optionsEnable: [Bool] = []
    
    var textFont: UIFont = UIFont(name: "PingFangTC-Regular", size: 15) ?? .systemFont(ofSize: 15)
    var textColor: UIColor = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1.0)
    var enabledColor: UIColor = UIColor(red: 189/255, green: 189/255, blue: 189/255, alpha: 1.0)
    var selectColor: UIColor = UIColor(red: 51/255, green: 51/255, blue: 51/255, alpha: 1.0)
    
    // 當使用者選取項目時的回呼 (Callback)
    var onSelect: ((Int) -> Void)?
    //被選到的項目
    var selectNum : Int?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        self.backgroundColor = .systemBackground
        self.layer.cornerRadius = 8
        self.layer.borderWidth = 1
        self.layer.borderColor = (UIColor(red: 130/255, green: 130/255, blue: 130/255, alpha: 1.0) as! CGColor)
        
        //陰影
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.15
        self.layer.shadowOffset = CGSize(width: 0, height: 4)
        self.layer.shadowRadius = 6
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UINib(nibName: "DropDownListTableViewCell", bundle: nil),
                           forCellReuseIdentifier: "DropDownListTableViewCell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.layer.cornerRadius = 8
        
        self.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: self.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DropDownListTableViewCell", for: indexPath) as? DropDownListTableViewCell else {return UITableViewCell()}
        
        cell.titleLabel.text = options[indexPath.row]
        cell.titleLabel.font = textFont
        if let select = selectNum, select == indexPath.row{
            cell.titleLabel.textColor = selectColor
        }else{
            if optionsEnable.count == options.count{
                if optionsEnable[indexPath.row] == true{
                    cell.titleLabel.textColor = textColor
                }else{
                    cell.titleLabel.textColor = enabledColor
                }
            }else{
                cell.titleLabel.textColor = textColor
            }
            
        }
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if selectColor != textColor{
            self.selectNum = indexPath.row
        }
        onSelect?(indexPath.row)
    }
}
