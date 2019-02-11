//
//  TestAViewController.swift
//  DKImagePicker
//
//  Created by 杜奎 on 2019/1/10.
//  Copyright © 2019 杜奎. All rights reserved.
//

import UIKit

class TestAViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Full Screen"
        self.view.backgroundColor = UIColor.red
        
        
        let btn = UIButton(type: UIButton.ButtonType.custom)
        btn.setTitle("click!", for: .normal)
        btn.setTitleColor(UIColor.purple, for: .normal)
        btn.addTarget(self, action: #selector(btnClicked), for: .touchUpInside)
        btn.sizeToFit()
        self.view.addSubview(btn)
        btn.center = CGPoint.init(x: self.view.width * 0.5, y: self.view.height * 0.5)
        // Do any additional setup after loading the view.
    }
    
    @objc func btnClicked() {
//        DKLoadingView.show()
    }
    
}
