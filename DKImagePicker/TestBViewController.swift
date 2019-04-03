//
//  TestBViewController.swift
//  DKImagePicker
//
//  Created by 杜奎 on 2019/1/10.
//  Copyright © 2019 杜奎. All rights reserved.
//

import UIKit

class TestBViewController: UIViewController {
    
    var dataSource = [String]()
    var dataDict = [String: Any]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Half Screen"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(customView: self.startBtn)
        self.view.backgroundColor = UIColor.white
        
        self.dataSource.append(contentsOf: [
            "是否按时间升序",
            "是否允许有图片",
            "是否允许有视频",
            "是否允许图片视频混合",
            "是否允许多个相册",
            "是否可以裁剪（单选）"])
        self.dataDict = [
            "是否按时间升序": false,
            "是否允许有图片": true,
            "是否允许有视频": true,
            "是否允许图片视频混合": false,
            "是否允许多个相册": true,
            "是否可以裁剪（单选）": false]
        self.tableView.register(DKPropertySelectedCell.self, forCellReuseIdentifier: "DKPropertySelectedCell")
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.startBtn)
        // Do any additional setup after loading the view.
    }
    
    //MARK:- action
    
    @objc func startBtnClicked() {
        let vc = TestBAssetViewController.init(dataDict: self.dataDict)
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //MARK:- setter & getter
    
    private lazy var tableView: UITableView = {
        let view = UITableView.init(frame: CGRect.init(x: 0, y: kStatusBarAndNavigationBarHeight, width: self.view.width, height: CGFloat(self.dataSource.count) * 40), style: .plain)
        view.tableFooterView = UIView.init()
        view.delegate = self
        view.dataSource = self
        view.separatorStyle = .none
        return view
    }()
    
    private lazy var startBtn: UIButton = {
        let btn = UIButton.init(type: UIButton.ButtonType.custom)
        btn.setTitleColor(kGenericColor, for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btn.setTitle("打开相册", for: .normal)
        btn.size = CGSize.init(width: 80, height: 40)
        btn.addTarget(self, action: #selector(startBtnClicked), for: .touchUpInside)
        return btn
    }()
}

extension TestBViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DKPropertySelectedCell") as! DKPropertySelectedCell
        let str = self.dataSource[indexPath.row]
        let data = self.dataDict[str]
        cell.delegate = self
        cell.setData(with: str, switchOn: data as? Bool)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

extension TestBViewController: DKPropertySelectedCellDelegate {
    func propertySelectedCellSwitchValueChange(name: String, isOn: Bool) {
        self.dataDict[name] = isOn
    }
}
