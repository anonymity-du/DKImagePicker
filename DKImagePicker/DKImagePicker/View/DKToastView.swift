//
//  DKToastView.swift
//  DKImagePicker
//
//  Created by 杜奎 on 2019/1/11.
//  Copyright © 2019 DU. All rights reserved.
//

import UIKit

class DKToastView: UIView {

    var message: String = ""
    
    convenience init(with message: String) {
        self.init(frame: CGRect.zero)
        
        self.message = message
        
        self.tipsLabel.text = message
        let maxSizeTitle = CGSize.init(width: kScreenWidth * 0.8, height: kScreenHeight * 0.8)
        var expectedSizeTitle = self.tipsLabel.sizeThatFits(maxSizeTitle)
        expectedSizeTitle = CGSize.init(width: min(maxSizeTitle.width, expectedSizeTitle.width), height: min(maxSizeTitle.height, expectedSizeTitle.height))
        self.tipsLabel.frame = CGRect.init(x: 30, y: 18, width: expectedSizeTitle.width, height: expectedSizeTitle.height)
        
        let viewWidth: CGFloat = self.tipsLabel.width + 30.0 * 2.0
        let viewHeight: CGFloat = self.tipsLabel.height + 18.0 * 2.0
        
        self.frame = CGRect.init(x: 0, y: 0, width: viewWidth, height: viewHeight)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.layer.cornerRadius = 12
        self.layer.masksToBounds = true
        self.backgroundColor = UIColor.init(white: 0, alpha: 0.4)
        self.addSubview(self.tipsLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- setter & getter
    
    private lazy var bgView: UIView = {
        let view = UIView.init()
        
        return view
    }()
    
    private lazy var tipsLabel: UILabel = {
        let label = UILabel.init()
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 17)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
}
