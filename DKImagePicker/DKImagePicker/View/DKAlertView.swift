//
//  DKAlertView.swift
//  DKImagePicker
//
//  Created by DU on 2019/2/11.
//  Copyright © 2019 DU. All rights reserved.
//

import UIKit

class DKAlertView: UIView {

    private var title: String = ""
    private var message: String = ""
    private var buttonTitles = [String]()
    
    private var leftActionBlock: (()->())?
    private var rightActionBlock: (()->())?

    convenience init(title: String, message: String, buttonTitles:[String], leftBtnActionBlock:(()->())?, rightBtnActionBlock: (()->())?) {
        self.init(frame: CGRect.init(x: 0, y: 0, width: kScreenWidth, height: kScreenHeight))
        
        self.title = title
        self.message = message
        self.buttonTitles = buttonTitles
        self.leftActionBlock = leftBtnActionBlock
        self.rightActionBlock = rightBtnActionBlock
        self.createUI()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func createUI() {
        self.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.15)
        self.addSubview(self.backView)
        if self.title.count != 0 {
            self.backView.contentView.addSubview(self.titleLabel)
            self.titleLabel.centerX = self.backView.width * 0.5
            self.titleLabel.y = 21
        }
        var btnOffsetY = self.titleLabel.bottom + 21
        
        if self.message.count > 0 {
            self.backView.contentView.addSubview(self.messageLabel)
            self.messageLabel.centerX = self.backView.width * 0.5
            if self.title.count > 0 {
                self.messageLabel.y = self.titleLabel.bottom + 8
            }else {
                self.messageLabel.y = 21
            }
            btnOffsetY = self.messageLabel.bottom + 21
        }
        
        if self.buttonTitles.count == 1 {
            self.backView.contentView.addSubview(self.leftBtn)
            self.leftBtn.y = btnOffsetY
        }else {
            self.backView.contentView.addSubview(self.leftBtn)
            self.backView.contentView.addSubview(self.rightBtn)
            self.leftBtn.y = btnOffsetY
            self.rightBtn.y = self.leftBtn.y
        }
        self.backView.height = self.leftBtn.bottom - 0.5
        self.backView.centerX = self.width * 0.5
        self.backView.centerY = self.height * 0.5
    }
    
    //MARK:- action
    
    func show() {
        kFrontWindow().endEditing(true)
        self.alpha = 0
        kFrontWindow().addSubview(self)
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }

    func dismiss() {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }) { (finished) in
            self.removeFromSuperview()
        }
    }

    @objc private func leftBtnClicked() {
        self.dismiss()
        if self.leftActionBlock != nil {
            self.leftActionBlock!()
        }
    }

    @objc private func rightBtnClicked() {
        self.dismiss()
        if self.rightActionBlock != nil {
            self.rightActionBlock!()
        }
    }
    
    //MARK:- setter & getter
    
    private lazy var backView: UIVisualEffectView = {
        let view = UIVisualEffectView.init(effect: UIBlurEffect.init(style: UIBlurEffect.Style.extraLight))
        view.frame = CGRect.init(x: 0, y: 0, width: kScreenWidth - 52 * 2 * K320Scale, height: 142)
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let titleFont = UIFont.systemFont(ofSize: 17.0, weight: .medium)
        let label = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: self.backView.width - 40 * K320Scale, height: titleFont.lineHeight))
        label.textColor = UIColor.black
        label.font = titleFont
        label.numberOfLines = 0
        let size = MULTILINE_TEXT_SIZE(text: self.title, font: titleFont, maxSize: CGSize.init(width: label.width, height: CGFloat.greatestFiniteMagnitude))
        label.size = size
        label.text = self.title
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    private lazy var messageLabel: UILabel = {
        let messageFont = UIFont.systemFont(ofSize: 13.0)
        let label = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: self.backView.width - 40 * K320Scale, height: 0))
        label.textColor = UIColor.black
        label.font = messageFont
        let size = MULTILINE_TEXT_SIZE(text: self.message, font: messageFont, maxSize: CGSize.init(width: label.width, height: CGFloat.greatestFiniteMagnitude))
        label.size = size
        label.numberOfLines = 0
        label.text = self.message
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    private lazy var leftBtn: UIButton = {
        let btn = UIButton.init(type: UIButton.ButtonType.custom)
        
        let leftTitle = self.buttonTitles.first
        if leftTitle != nil && leftTitle!.isEmpty == false {
            btn.setTitle(leftTitle!, for: .normal)
        }else {
            btn.setTitle("取消", for: .normal)
        }
        if self.buttonTitles.count == 1 {
            btn.frame = CGRect.init(x: -0.5, y: 0, width: self.backView.width + 1, height: 44.5)
        }else {
            btn.frame = CGRect.init(x: -0.5, y: 0, width: self.backView.width * 0.5 + 1, height: 44.5)
        }
        
        btn.addTarget(self, action: #selector(leftBtnClicked), for: .touchUpInside)
        btn.layer.borderColor = UIColor.hexColor("#09141f", 0.13)!.cgColor
        btn.layer.borderWidth = 0.5
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        btn.setTitleColor(UIColor.hexColor("#007aff"), for: .normal)
        return btn
    }()
    
    private lazy var rightBtn: UIButton = {
        let btn = UIButton.init(type: UIButton.ButtonType.custom)
        
        if self.buttonTitles.count == 0 {
            btn.setTitle("确定", for: .normal)
        }else {
            let rightTitle = self.buttonTitles.last
            if rightTitle != nil && rightTitle!.isEmpty == false {
                btn.setTitle(rightTitle!, for: .normal)
            }else {
                btn.setTitle("确定", for: .normal)
            }
        }
        
        btn.frame = CGRect.init(x: self.leftBtn.right - 0.5, y: 0, width: self.leftBtn.width, height: 44.5)
        btn.addTarget(self, action: #selector(rightBtnClicked), for: .touchUpInside)
        btn.layer.borderColor = UIColor.hexColor("#09141f", 0.13)!.cgColor
        btn.layer.borderWidth = 0.5
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        btn.setTitleColor(UIColor.hexColor("#007aff"), for: .normal)
        return btn
    }()
}
