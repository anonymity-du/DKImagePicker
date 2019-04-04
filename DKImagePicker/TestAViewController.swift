//
//  TestAViewController.swift
//  DKImagePicker
//
//  Created by DU on 2019/1/10.
//  Copyright © 2019 DU. All rights reserved.
//

import UIKit

class TestAViewController: UIViewController {

    var dataSource = [String]()
    var dataDict = [String: Any]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Full Screen"
        self.view.backgroundColor = UIColor.white
        self.view.addSubview(self.multipleChangeAvatarBtn)
        self.view.addSubview(self.multipleSelectBtn)
        
        self.multipleChangeAvatarBtn.centerX = self.view.width * 0.5
        self.multipleChangeAvatarBtn.bottom = self.view.height * 0.5 - 12
        
        self.multipleSelectBtn.centerX = self.multipleChangeAvatarBtn.centerX
        self.multipleSelectBtn.y = self.view.height * 0.5 + 12
        
        // Do any additional setup after loading the view.
    }
    
    //MARK:- action
    
    @objc func multipleSelectBtnClicked() {
        let vc = TestAMuiltyImageViewController()
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func multipleChangeAvatarBtnClicked() {
        let vc = TestAAvatarViewController()
        vc.hidesBottomBarWhenPushed = true
        self.navigationController?.pushViewController(vc, animated: true)
    }
        
    //MARK:- setter & getter
    
    private lazy var multipleSelectBtn: UIButton = {
        let btn = UIButton.init(type: UIButton.ButtonType.custom)
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btn.setTitle("多选相片", for: .normal)
        btn.backgroundColor = kGenericColor
        btn.size = CGSize.init(width: 80, height: 40)
        btn.addTarget(self, action: #selector(multipleSelectBtnClicked), for: .touchUpInside)
        return btn
    }()
    
    private lazy var multipleChangeAvatarBtn: UIButton = {
        let btn = UIButton.init(type: UIButton.ButtonType.custom)
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btn.setTitle("更改头像", for: .normal)
        btn.backgroundColor = kGenericColor
        btn.size = CGSize.init(width: 80, height: 40)
        btn.addTarget(self, action: #selector(multipleChangeAvatarBtnClicked), for: .touchUpInside)
        return btn
    }()

}

