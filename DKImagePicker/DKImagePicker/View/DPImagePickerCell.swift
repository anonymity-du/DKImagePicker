//
//  DPImagePickerCell.swift
//  DatePlay
//
//  Created by 张昭 on 2018/10/17.
//  Copyright © 2018 AimyMusic. All rights reserved.
//

import UIKit
import AVKit
import Photos

protocol DPImagePickerCellDelegate: NSObjectProtocol {
    func cellSelectBtnWillClicked(with model: DPAssetModel, isSelected: Bool,cell: DPImagePickerCell) -> Bool
    func cellSelectBtnDidClicked(with model: DPAssetModel, isSelected: Bool,cell: DPImagePickerCell)
}

class DPImagePickerCell: UICollectionViewCell {
    
    weak var delegate: DPImagePickerCellDelegate?

    var representedAssetIdentifier: String?
    var imageRequestID: Int32 = 0
    var bigImageRequestID: Int32 = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(self.imageView)
        self.contentView.addSubview(self.selectImageView)
        self.contentView.addSubview(self.selectPhotoButton)
        self.contentView.addSubview(self.bottomView)
        
        self.bottomView.addSubview(self.timeLengthLabel)
        self.contentView.addSubview(self.indexLabel)
        self.contentView.addSubview(self.progressView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- action
    
    func resetIndexLabel() {
        self.index = self.type == .video ? 0 : IMGInstance.calculateCellSelectedIndex(self.model!)
    }
    
    fileprivate func bindDataToView(_ model: DPAssetModel) {
        if let asset = model.asset {
            representedAssetIdentifier = asset.localIdentifier
            let imgRequestID = IMGInstance.getPhotoAllParams(asset: asset, photoWidth: self.width, networkAccessAllowed: false, progressHandler: nil) { [weak self](photo, info, isDegraded) in
                if self?.representedAssetIdentifier == asset.localIdentifier {
                    self?.imageView.image = photo
                } else {
                    if self?.imageRequestID != nil {
                        PHImageManager.default()
                            .cancelImageRequest((self?.imageRequestID)!)
                    }
                }
                if isDegraded == false {
                    self?.hideProgressView()
                    self?.imageRequestID = 0
                }
            }
            if imgRequestID != 0 && self.imageRequestID != 0 && imgRequestID != self.imageRequestID {
                PHImageManager.default().cancelImageRequest(self.imageRequestID)
            }
            self.imageRequestID = imgRequestID
            self.selectPhotoButton.isSelected = index > 0
            self.type = model.mediaType
            // 如果是选中的照片，提前获取大图
            if index > 0 {
                model.isSelected = true
                requestBigImage()
            } else {
                cancelBigImageRequest()
                model.isSelected = false
            }
            
            model.needOscillatoryAnimation = false
            self.setNeedsLayout()
        }
    }
    
    fileprivate func requestBigImage() {
        if bigImageRequestID != 0 {
            PHImageManager.default()
                .cancelImageRequest(bigImageRequestID)
        }
        bigImageRequestID = IMGInstance.getOriginalPhotoData(asset: model!.asset!, progressHandler: { [weak self](progress, error, stop, info) in
            if self?.model?.isSelected == true {
                let prog = progress > 0.02 ? progress : 0.02
                self?.imageView.alpha = 0.4
                self?.progressView.isHidden = false
                self?.progressView.progress = CGFloat(prog)
                print("requestBigImage: \(prog)")
                if prog >= 1 {
                    self?.hideProgressView()
                }
            } else {
                stop.initialize(to: true)
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self?.cancelBigImageRequest()
            }
        }, complete: { [weak self](imageData, info, isDegraded) in
            self?.hideProgressView()
        })
    }
    
    fileprivate func cancelBigImageRequest() {
        if bigImageRequestID != 0 {
            PHImageManager.default()
                .cancelImageRequest(bigImageRequestID)
        }
        hideProgressView()
    }
    
    fileprivate func hideProgressView() {
        self.progressView.isHidden = true
        self.imageView.alpha = 1.0
    }
    
    // MARK: - Actions
    
    @objc fileprivate func selectPhotoButtonClicked(_ sender: UIButton) {
        var continueNext = true
        if let canContinue = self.delegate?.cellSelectBtnWillClicked(with: self.model!, isSelected: sender.isSelected, cell: self) {
            continueNext = canContinue
        }
        if continueNext {
            self.handleDidSelectPhoto(self.model!, isSelected: sender.isSelected)
        }

        if sender.isSelected {
            requestBigImage()
        } else {
            cancelBigImageRequest()
        }
    }
    
    fileprivate func handleDidSelectPhoto(_ model: DPAssetModel, isSelected: Bool) {
        if isSelected {
            self.selectPhotoButton.isSelected = false
            model.isSelected = false
            IMGInstance.removeAssetModel(with: model)
            self.delegate?.cellSelectBtnDidClicked(with: self.model!, isSelected: !isSelected, cell: self)
        } else {
            if IMGInstance.configModel.selectedModels.count < IMGInstance.configModel.maxImagesCount {
                self.selectPhotoButton.isSelected = true
                model.isSelected = true
                IMGInstance.addAssetModel(with: model)
                self.delegate?.cellSelectBtnDidClicked(with: self.model!, isSelected: !isSelected, cell: self)
            } else {
                var strTip = ""
                if IMGInstance.configModel.diyTip.count > 0 {
                    strTip = IMGInstance.configModel.diyTip
                } else {
                    strTip = "最多只能选择\(IMGInstance.configModel.maxImagesCount)张"
                }
                kFrontWindow().makeToast(strTip)
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.selectPhotoButton.right = self.contentView.width
        self.selectImageView.right = self.contentView.width - 6
        self.selectImageView.y = 6
    
        self.indexLabel.sizeToFit()
        self.indexLabel.center = self.selectImageView.center
        self.imageView.frame = self.contentView.bounds
        
        let progressWH: CGFloat = 20
        let progressXY = (self.frame.width - progressWH) * 0.5
        progressView.frame = CGRect.init(x: progressXY, y: progressXY, width: progressWH, height: progressWH)
        
        timeLengthLabel.sizeToFit()
        let timeWidth = timeLengthLabel.size.width
        bottomView.frame = CGRect.init(x: 4, y: self.contentView.height - 15 - 4, width: timeWidth + 12, height: 15)
        timeLengthLabel.frame = CGRect.init(x: 6, y: 0, width: timeWidth, height: 15)
    }
    
    //MARK:- setter & getter
    
    var index: Int = 0 {
        didSet {
            if index > 0 {
                self.indexLabel.isHidden = false
                self.indexLabel.text = "\(index)"
                self.indexLabel.sizeToFit()
                self.indexLabel.center = self.selectImageView.center
                self.selectImageView.image = UIImage.init(named: "ic_selectedbox")
                self.selectPhotoButton.isSelected = true
            } else {
                self.indexLabel.isHidden = true
                self.selectPhotoButton.isSelected = false
                self.selectImageView.image = UIImage.init(named: "ic_selectbox")
            }
        }
    }
    var model: DPAssetModel? {
        didSet {
            if model != nil {
                bindDataToView(model!)
            }
        }
    }
    
    var type: DPAssetModelMediaType? {
        didSet {
            if type == .photo || type == .livePhoto || (type == .photoGif && !IMGInstance.configModel.allowPickingGif) || IMGInstance.configModel.allowPickingMultipleVideo {
                self.selectImageView.isHidden = !IMGInstance.configModel.showSelectBtn
                self.selectPhotoButton.isHidden = !IMGInstance.configModel.showSelectBtn
                if self.indexLabel.isHidden == false {
                    self.indexLabel.isHidden = !IMGInstance.configModel.showSelectBtn
                }
                self.bottomView.isHidden = true
            } else {
                self.selectImageView.isHidden = true
                self.selectPhotoButton.isHidden = true
                self.indexLabel.isHidden = true
            }
            
            if type == .video {
                self.bottomView.isHidden = false
                self.timeLengthLabel.text = model?.timeLength
                self.timeLengthLabel.textAlignment = NSTextAlignment.center
            } else if type == .photoGif && IMGInstance.configModel.allowPickingGif {
                self.bottomView.isHidden = false
                self.timeLengthLabel.text = "GIF"
                self.timeLengthLabel.x = 5
                self.timeLengthLabel.textAlignment = NSTextAlignment.left
            }
        }
    }
    
    private lazy var imageView: UIImageView = {
        let view = UIImageView.init()
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    private lazy var selectImageView: UIImageView = {
        let view = UIImageView.init()
        view.clipsToBounds = true
        view.contentMode = .center
        view.size = CGSize.init(width: 24, height: 24)
        return view
    }()
    
    private lazy var selectPhotoButton: UIButton = {
        let btn = UIButton.init(type: UIButton.ButtonType.custom)
        btn.size = CGSize.init(width: 44, height: 44)
//        btn.expandEdge = UIEdgeInsets.init(top: 5, left: 5, bottom: 5, right: 5)
        btn.addTarget(self, action: #selector(selectPhotoButtonClicked(_:)), for: .touchUpInside)
        return btn
    }()

    private lazy var bottomView: UIView = {
        let view = UIView.init()
        view.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.5)
        view.layer.cornerRadius = 5
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var timeLengthLabel: UILabel = {
        let label = UILabel.init()
        label.font = UIFont.systemFont(ofSize: 10, weight: UIFont.Weight.regular)
        label.textColor = UIColor.white
        label.textAlignment = NSTextAlignment.center
        return label
    }()
   
    private lazy var indexLabel: UILabel = {
        let label = UILabel.init()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.white
        label.textAlignment = NSTextAlignment.center
        return label
    }()
    
    private lazy var progressView: DKProgressView = {
        let view = DKProgressView.init()
        view.isHidden = true
        return view
    }()
}
