//
//  DKSelectedImageView.swift
//  DKImagePicker
//
//  Created by 杜奎 on 2019/1/24.
//  Copyright © 2019 DU. All rights reserved.
//

import UIKit

class DKSelectedImageView: UIView {

    var deleteBlock: (()->())?
    var selectBlock: (()->())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(imgView)
        addSubview(playView)
        addSubview(deleteView)
        
        self.playView.center = self.imgView.center
        self.deleteView.right = self.imgView.right - 4
        self.deleteView.y = self.imgView.y + 4
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- action
    
    @objc func deleteAction() {
        if self.deleteBlock != nil {
            self.deleteBlock!()
        }
    }
    
    @objc func tapAction() {
        if self.selectBlock != nil {
            self.selectBlock!()
        }
    }
    
    //MARK:- setter & getter
    
    var assetModel: DKAssetModel? {
        didSet {
            if let model = assetModel {
                imgView.image = model.thumbnail
                if let data = model.data {
                    imgView.image = UIImage.init(data: data)
                }else {
                    _ = IMGInstance.getPhotoNoWidth(asset: model.asset!, networkAccessAllowed: true, complete: { [weak self](photo, info, isDegraded) in
                        model.data = photo?.jpegData(compressionQuality: 0.5)
                        if !(self?.imgView.image != nil && photo == nil) {
                            self?.imgView.image = photo
                        }
                    })
                }
                if model.mediaType == .video {
                    playView.isHidden = false
                }else {
                    playView.isHidden = true
                }
            }
        }
    }
    
    var videoModel: DKVideoModel? {
        didSet {
            if let video = videoModel {
                imgView.image = video.coverThumbImg
                playView.isHidden = false
            }
        }
    }
    
    private lazy var imgView: UIImageView = {
        let view = UIImageView.init(frame: self.bounds)
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(tapAction)))
        return view
    }()
    
    private lazy var deleteView: UIImageView = {
        let view = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 16, height: 16))
        view.image = UIImage.init(named: "ic_deleteimgs")
        view.isUserInteractionEnabled = true
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
//        view.expandEdge = UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10)
        view.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(deleteAction)))
        return view
    }()
    
    private lazy var playView: UIImageView = {
        let view = UIImageView.init()
        view.image = UIImage.init(named: "ic_square_play")
        view.isHidden = true
        return view
    }()

}
