//
//  TestBViewController.swift
//  DKImagePicker
//
//  Created by DU on 2019/1/10.
//  Copyright © 2019 DU. All rights reserved.
//

import UIKit

class TestBViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Half Screen"
        self.view.backgroundColor = UIColor.white
        
        self.view.addSubview(self.startBtn)
        self.startBtn.centerX = self.view.width * 0.5
        self.startBtn.centerY = self.view.height * 0.5
        // Do any additional setup after loading the view.
    }
    
    //MARK:- action
    
    @objc func startBtnClicked() {
        let vc = TestBAssetViewController()
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //MARK:- setter & getter
    
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

