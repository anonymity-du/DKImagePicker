//
//  DKImagePickerCameraCell.swift
//  DatePlay
//
//  Created by 张昭 on 2018/10/23.
//  Copyright © 2018 AimyMusic. All rights reserved.
//

import UIKit

class DKImagePickerCameraCell: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.backgroundColor = UIColor.hexColor("f7f5ff")
        
        let imgView = UIImageView()
        imgView.image = UIImage.init(named: "ic_login_camera")
        contentView.addSubview(imgView)
//        imgView.snp.makeConstraints { (make) in
//            make.center.equalToSuperview()
//        }
       
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
