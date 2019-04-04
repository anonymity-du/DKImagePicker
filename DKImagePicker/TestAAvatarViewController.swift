//
//  TestAAvatarViewController.swift
//  DKImagePicker
//
//  Created by DU on 2019/4/4.
//  Copyright © 2019 DU. All rights reserved.
//

import UIKit

class TestAAvatarViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.white
        self.view.addSubview(self.avatarImageView)
        self.view.addSubview(self.tipsLabel)
        self.avatarImageView.centerX = self.view.width * 0.5
        self.avatarImageView.centerY = self.view.height * 0.5
        self.tipsLabel.center = self.avatarImageView.center
        // Do any additional setup after loading the view.
    }
    
    @objc func avatarImageViewTaped() {
        IMGInstance.configModel(maxImagesCount: 1)
        IMGInstance.configModel.allowPickingVideo = false
        IMGInstance.configModel.allowCrop = true
        IMGInstance.pushPhotoPickerVC(delegate: self)
    }

    private lazy var avatarImageView: UIImageView = {
        let view = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 200, height: 200))
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        view.layer.cornerRadius = 50
        view.backgroundColor = kGenericColor
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(avatarImageViewTaped)))
        return view
    }()
    
    private lazy var tipsLabel: UILabel = {
        let label = UILabel.init()
        label.textColor = UIColor.white
        label.text = "更换头像"
        label.sizeToFit()
        return label
    }()
}

extension TestAAvatarViewController: DKImagePickerViewControllerDelegate {
    func didSelectModels(photos: [UIImage], infos: [Any], sourceAssets: [DKAssetModel]) {
        if let photo = photos.first {
            self.avatarImageView.image = photo
            self.tipsLabel.isHidden = true
        }  else {
            print("没有选中图片")
        }
    }
}
