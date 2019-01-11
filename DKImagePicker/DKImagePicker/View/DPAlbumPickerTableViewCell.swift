//
//  DPAlbumPickerTableViewCell.swift
//  DatePlay
//
//  Created by 张昭 on 2018/10/23.
//  Copyright © 2018 AimyMusic. All rights reserved.
//

import UIKit

class DPAlbumPickerTableViewCell: UITableViewCell {
    
    fileprivate let imgView = UIImageView()
    fileprivate let albumTitleLabel = UILabel()
    fileprivate let iconImageView = UIImageView()
    fileprivate let iconRightDot = UIImageView()
    
    var model: DPAlbumModel? {
        didSet {
            if let mm: DPAlbumModel = model {
                albumTitleLabel.text = "\(mm.name)（\(mm.count)）"
                IMGInstance.getPosterImage(albumModel: mm) { (image) in
                    self.imgView.image = image
                }
                iconRightDot.isHidden = mm.selectedCount <= 0
            }
        }
    }
    
    var showSelectedIcon: Bool? {
        didSet {
            if showSelectedIcon == true {
                iconImageView.isHidden = false
            } else {
                iconImageView.isHidden = true
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(imgView)
        imgView.backgroundColor = UIColor.hexColor("f3f3f3")
        imgView.contentMode = UIView.ContentMode.scaleAspectFill
        imgView.clipsToBounds = true
        
        contentView.addSubview(albumTitleLabel)
        albumTitleLabel.textColor = UIColor.hexColor("4a4a4a")
        albumTitleLabel.font = UIFont.systemFont(ofSize: 15)
        
        contentView.addSubview(iconImageView)
        iconImageView.image = UIImage.init(named: "ic_selectalbum")
        iconImageView.isHidden = true
        
//        imgView.snp.makeConstraints { (make) in
//            make.left.equalTo(16)
//            make.centerY.equalToSuperview()
//            make.width.height.equalTo(55)
//        }
//        albumTitleLabel.snp.makeConstraints { (make) in
//            make.left.equalTo(self.imgView.snp.right).offset(17)
//            make.centerY.equalToSuperview()
//            make.right.lessThanOrEqualTo(-40)
//        }
//        iconImageView.snp.makeConstraints { (make) in
//            make.right.equalTo(-16)
//            make.centerY.equalToSuperview()
//        }
        
        contentView.addSubview(iconRightDot)
        iconRightDot.image = UIImage.init(named: "ic_selectedbox")
//        iconRightDot.snp.makeConstraints { (make) in
//            make.top.equalTo(imgView.snp.top).offset(4)
//            make.right.equalTo(imgView.snp.right).offset(-4)
//            make.size.equalTo(CGSize.init(width: 13, height: 13))
//        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
