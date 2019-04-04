//
//  DKImagePickerView.swift
//  DKImagePicker
//
//  Created by DU on 2019/1/24.
//  Copyright © 2019 DU. All rights reserved.
//

import UIKit
import AVKit
import Photos

class DKImagePickerView: UIView {

    var configModel: DKImageConfigModel?
    private(set) var selectedAssetModels = [DKAssetModel]()
    var modelsChangeBlock: ((_ models: [DKAssetModel])->())?
    private var videoAlbumModel: DKAlbumModel?
    
    private var showAlbum = false {
        willSet {
            if showAlbum != newValue {
                assetsView.isHidden = newValue
                albumView.isHidden = !newValue
                if newValue == true {
                    albumView.refreshTableViewData()
                }
                UIView.animate(withDuration: 0.2) {
                    if newValue {
                        self.albumBtn.imageView!.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                    } else {
                        self.albumBtn.imageView!.transform = CGAffineTransform.identity
                    }
                }
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.changeImageConfigModel()
        
        addSubview(assetsView)
        addSubview(albumView)
        addSubview(bottomBar)
        bottomBar.bottom = self.height
        self.changeBtnStatus(isAlbumBtn: true)
    }
    
    //更换configModel
    func changeImageConfigModel() {
        if self.configModel == nil {
            self.configModel = DKImageConfigModel.init()
            self.configModel?.allowPreview = true
            self.configModel?.allowPickingImage = true
            self.configModel?.allowPickingVideo = false
            self.configModel?.showSelectBtn = true
        }
        IMGInstance.configModel = self.configModel!
        IMGInstance.pickerDelegate = self
    }
    
    func configTableViewData() {
        
        _ = DKSystemPermission.photoAblumHasAuthority { (access) in
            if access {
                DispatchQueue.global().async {
                    IMGInstance.getAllAlbums(allowPickingVideo: IMGInstance.configModel.allowPickingVideo, allowPickingImage: IMGInstance.configModel.allowPickingImage, complete: { (arr) in
                        if arr.count > 0 {
                            IMGInstance.configModel.selectedAlbumModel = arr.first!
                        }
                        IMGInstance.configModel.allowPickingVideo = true
                        IMGInstance.configModel.allowPickingImage = false
                        IMGInstance.getVideoAlbum(allowPickingVideo: true, allowPickingImage: false, complete: { (model) in
                            DispatchQueue.main.async {
                                IMGInstance.configModel.allowPickingVideo = false
                                IMGInstance.configModel.allowPickingImage = true
                                self.albumView.configTableViewData(with: arr)
                                self.assetsView.albumModel = IMGInstance.configModel.selectedAlbumModel
                                self.videoAlbumModel = model
                            }
                        })
                    })
                }
            }
        }
    }
    
    func changeSubviewsFrame(needChangeBounds: Bool) {
        if needChangeBounds {
            assetsView.frame = self.bounds
            albumView.frame = assetsView.bounds
        }
        bottomBar.bottom = self.height
    }
    
    private func changeBtnStatus(isAlbumBtn: Bool) {
        if isAlbumBtn {
            if albumBtn.isSelected {
                self.showAlbum = self.albumView.isHidden
            }else {
                albumBtn.isSelected = true
                self.videoBtn.isSelected = false
                self.assetsView.isHidden = self.showAlbum
                self.albumView.isHidden = !self.showAlbum
                self.albumView.refreshTableViewData()
                self.assetsView.albumModel = IMGInstance.configModel.selectedAlbumModel
            }
            IMGInstance.configModel.allowPreview = true
            IMGInstance.configModel.allowPickingVideo = false
            IMGInstance.configModel.allowPickingImage = true
            albumBtn.imageView?.tintColor = UIColor.hexColor("9B8AE6")
        }else {
            if !videoBtn.isSelected {
                videoBtn.isSelected = true
                self.albumBtn.isSelected = false
                self.albumView.isHidden = true
                self.assetsView.isHidden = false
                self.assetsView.albumModel = self.videoAlbumModel
            }
            IMGInstance.configModel.allowPreview = false
            IMGInstance.configModel.allowPickingVideo = true
            IMGInstance.configModel.allowPickingImage = false
            albumBtn.imageView?.tintColor = UIColor.hexColor("A3A3A3")
        }
    }
    
    func deleteImg(index: Int) {
        if index - 100 >= 0 && index - 100 < self.selectedAssetModels.count {
            let model = self.selectedAssetModels[index - 100]
            IMGInstance.removeAssetModel(with: model)
            self.assetsView.updateCollectionView()
        }
    }
    
    //混合类型提示
    private func mixTypeTips(model: DKAssetModel) -> Bool {
        
        var modelType = 0 // 0没有数据 1照片 2视频
        if let firstItem = IMGInstance.configModel.selectedModels.first {
            if firstItem.mediaType == .photo || firstItem.mediaType == .photoGif{
                modelType = 1
            }else {
                modelType = 2
            }
        }
        
        if model.mediaType == .photo {
            if modelType == 2 {
                kFrontWindow().makeToast("视频与照片无法同时选择")
                return false
            }
        }else if model.mediaType == .video {
            if modelType == 2 {
                kFrontWindow().makeToast("最多只能选择一个视频哦~")
                return false
            }else if modelType == 1 {
                kFrontWindow().makeToast("照片与视频无法同时选择")
                return false
            }
        }
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- action
    
    @objc private func albumBtnAction() {
        print("照片")
        if DKSystemPermission.photoAblumHasAuthority() {
            if self.videoAlbumModel == nil {
                return
            }
            self.changeBtnStatus(isAlbumBtn: true)
        }
    }
    
    @objc private func videoBtnAction() {
        print("视频")
        if DKSystemPermission.photoAblumHasAuthority() {
            if self.videoAlbumModel == nil {
                return
            }
            self.changeBtnStatus(isAlbumBtn: false)
        }
    }
    
    //MARK:- setter & getter
    private lazy var albumView: DKAlbumPickerView = {
        let view = DKAlbumPickerView.init(frame: CGRect.init(x: 0, y: 0, width: self.width, height: self.height))
        view.isHidden = true
        view.delegate = self
        view.resetScrollViewContentInset(bottomBar.height)
        return view
    }()
    private lazy var assetsView: DKMediaPickerView = {
        let view = DKMediaPickerView.init(frame: CGRect.init(x: 0, y: 0, width: self.width, height: self.height))
        view.delegate = self
        view.resetScrollViewContentInset(bottomBar.height)
        return view
    }()
    
    private lazy var bottomBar: UIView = {
        let view = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.width, height: 40 + kTabbarSafeBottomMargin))
        view.backgroundColor = UIColor.white
        
        view.addSubview(albumBtn)
        view.addSubview(videoBtn)
        albumBtn.x = 0
        albumBtn.y = 0
        videoBtn.x = albumBtn.right
        videoBtn.y = albumBtn.y
        
        return view
    }()
    private lazy var albumBtn: UIButton = {
        let btn = UIButton.init(type: UIButton.ButtonType.custom)
        btn.setTitle("照片", for: .normal)
        btn.setTitleColor(UIColor.hexColor("9B8AE6"), for: .selected)
        btn.setTitleColor(UIColor.hexColor("A3A3A3"), for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        btn.setImage(UIImage.init(named: "ic_smallarrow")?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.imageEdgeInsets = UIEdgeInsets.init(top: 0, left: -10, bottom: 0, right: 10)
        btn.backgroundColor = UIColor.white
        btn.size = CGSize.init(width: self.width * 0.5, height: 40)
        btn.imageView?.tintColor = UIColor.hexColor("A3A3A3")
        
        btn.addTarget(self, action: #selector(albumBtnAction), for: .touchUpInside)
        return btn
    }()
    private lazy var videoBtn: UIButton = {
        let btn = UIButton.init(type: UIButton.ButtonType.custom)
        btn.setTitle("视频", for: .normal)
        btn.setTitleColor(UIColor.hexColor("9B8AE6"), for: .selected)
        btn.setTitleColor(UIColor.hexColor("A3A3A3"), for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        btn.backgroundColor = UIColor.white
        btn.size = CGSize.init(width: self.width * 0.5, height: 40)
        btn.addTarget(self, action: #selector(videoBtnAction), for: .touchUpInside)
        return btn
    }()
}

extension DKImagePickerView: DKAlbumPickerViewDelegate {
    func didSelectAlbum(_ album: DKAlbumModel) {
        if IMGInstance.configModel.selectedAlbumModel?.name != album.name {
            self.assetsView.albumModel = album
            showAlbum = false
        }
    }
}

extension DKImagePickerView: DKMediaPickerViewDelegate {
    
    func mediaPickerViewCellWillUseCamera(_ isVideo: Bool) -> Bool {

        if let firstItem = IMGInstance.configModel.selectedModels.first {
            if (firstItem.mediaType == .photo || firstItem.mediaType == .photoGif) && isVideo {
                kFrontWindow().makeToast("照片与视频无法同时选择")
                return false
            }else if firstItem.mediaType == .video && isVideo == false {
                kFrontWindow().makeToast("视频与照片无法同时选择")
                return false
            }else if firstItem.mediaType == .video && isVideo {
                kFrontWindow().makeToast("最多只能选择一个视频哦~")
                return false
            }
        }
        return true
    }
    
    func mediaPickerViewWillSelectModel(_ model: DKAssetModel) -> Bool {
        print("will select")
        let should = self.mixTypeTips(model: model)
        return should
    }
    
    func mediaPickerViewDidSelectModel(_ model: DKAssetModel) {
        print("did select")
    }
    
    func mediaPickerViewCellWillSelect(_ model: DKAssetModel) -> Bool {
        let should = self.mixTypeTips(model: model)
        return should
    }
    
    func mediaPickerViewCellDidSelect(_ model: DKAssetModel) {
        if model.mediaType == .video {
            if model.asset == nil {
                kFrontWindow().makeToast("视频资源不存在!")
                IMGInstance.removeAssetModel(with: model)
                return
            }
            if (model.asset?.duration ?? 0) < 3.0 {
                kFrontWindow().makeToast("视频最短3秒哦")
                IMGInstance.removeAssetModel(with: model)
                return
            }
            
            DKLoadingView.showMessage(message: "视频处理中")
            
            let option = PHVideoRequestOptions.init()
            option.progressHandler = { progress, error, stop, info in
                print("icloud 视频下载中 \(progress)")
            }
            option.isNetworkAccessAllowed = true
            option.deliveryMode = .mediumQualityFormat
            PHImageManager.default().requestAVAsset(forVideo: model.asset!, options: option) { (avasset, audioMix, info) in
                var isCancel = false
                var hasError = false
                var isDownLoadFromICloud = false
                if let dict = info {
                    //是否取消
                    if let cancel = dict[PHImageCancelledKey] as? Bool {
                        isCancel = cancel
                    }
                    //是否出错
                    if let _ = dict[PHImageErrorKey] {
                        hasError = true
                    }
                    //是否从iCloud下载
                    if let icloud = dict[PHImageResultIsInCloudKey] as? Bool {
                        isDownLoadFromICloud = icloud
                    }
                }
                
                if isCancel || hasError {
                    DispatchQueue.main.async {
                        DKLoadingView.hide()
                        kFrontWindow().makeToast("视频处理异常!")
                        IMGInstance.removeAssetModel(with: model)
                    }
                }else if avasset != nil {
                    
                    DKPlayerManager.shared.videoMaxSize = CGSize.init(width: kScreenWidth, height: kScreenWidth)
                    DKPlayerManager.shared.avasset = avasset
                    DKPlayerManager.shared.fetchVideoProperty(complete: { (time, videoTracks, audioTracks) in
                        DKPlayerManager.shared.fetchVideoInfo(time: time, videoTracks: videoTracks, audioTracks: audioTracks)
                        DispatchQueue.main.async {
                            let vc = DKCropVideoViewController.init()
                            vc.videoModel = model
                            vc.avasset = avasset
                            kTopViewController()?.navigationController?
                                .pushViewController(vc, animated: true)
                            DKLoadingView.hide()
                            print("跳转到视频裁切页")
                        }
                    })
                }else if avasset == nil {
                    if isDownLoadFromICloud {
                        print("从 icloud 下载")
                    }else {
                        DispatchQueue.main.async {
                            DKLoadingView.hide()
                            kFrontWindow().makeToast("视频处理异常!")
                            IMGInstance.removeAssetModel(with: model)
                        }
                    }
                }
            }
        }
    }
}

extension DKImagePickerView: DKImagePickerDelegate {
    func imagePickerDidChangePicking(models: [DKAssetModel]) {
        self.selectedAssetModels.removeAll()
        self.selectedAssetModels.append(contentsOf: IMGInstance.configModel.selectedModels)
        if self.modelsChangeBlock != nil {
            self.modelsChangeBlock!(self.selectedAssetModels)
        }
        self.assetsView.updateCollectionView()
    }
}
