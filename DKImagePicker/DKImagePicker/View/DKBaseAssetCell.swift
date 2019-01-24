//
//  DKBaseAssetCell.swift
//  DatePlay
//
//  Created by 杜奎 on 2018/11/1.
//  Copyright © 2018年 AimyMusic. All rights reserved.
//

import UIKit

class DKBaseAssetCell: UICollectionViewCell {
    
    var singleTapBlock: (()->())?
    var model: DKAssetModel?
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.createUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createUI() {
        self.configSubviews()
        NotificationCenter.default.addObserver(self, selector: #selector(photoPreviewCollectionViewDidScroll), name: NSNotification.Name.photoPreviewCollectionViewDidScroll, object: nil)
    }
    
    @objc func photoPreviewCollectionViewDidScroll() {
        
    }
    
    func configSubviews() {
    
    }
}
