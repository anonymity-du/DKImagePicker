//
//  DKAlbumPickerTableViewCell.swift
//  DatePlay
//
//  Created by DU on 2018/10/23.
//  Copyright © 2018 DU. All rights reserved.
//

import UIKit

class DKAlbumPickerTableViewCell: UITableViewCell {
    
    var model: DKAlbumModel? {
        didSet {
            if let mm: DKAlbumModel = model {
                albumTitleLabel.text = "\(mm.name)（\(mm.count)）"
                albumTitleLabel.sizeToFit()
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
        contentView.addSubview(albumTitleLabel)
        contentView.addSubview(iconImageView)
        contentView.addSubview(iconRightDot)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imgView.x = 16
        imgView.centerY = self.contentView.height * 0.5
        
        albumTitleLabel.x = imgView.right + 17
        albumTitleLabel.centerY = imgView.centerY
        
        iconImageView.right = self.contentView.width - 16
        iconImageView.centerY = imgView.centerY
        
        iconRightDot.y = imgView.y + 4
        iconRightDot.right = imgView.right - 4
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- setter & getter
    
    private lazy var imgView: UIImageView = {
        let view = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 55, height: 55))
        view.backgroundColor = UIColor.hexColor("f3f3f3")
        view.contentMode = UIView.ContentMode.scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var albumTitleLabel: UILabel = {
        let label = UILabel.init()
        label.textColor = UIColor.hexColor("4a4a4a")
        label.font = UIFont.systemFont(ofSize: 15)
        return label
    }()
    
    private lazy var iconImageView: UIImageView = {
        let view = UIImageView.init()
        view.image = UIImage.init(named: "ic_selectalbum")
        view.isHidden = true
        view.sizeToFit()
        return view
    }()
    
    private lazy var iconRightDot: UIImageView = {
        let view = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 13, height: 13))
        view.image = UIImage.init(named: "ic_selectedbox")
        return view
    }()
}
