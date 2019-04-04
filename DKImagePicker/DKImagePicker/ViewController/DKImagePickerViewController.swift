//
//  DKImagePickerViewController.swift
//  DatePlay
//
//  Created by DU on 2018/10/22.
//  Copyright © 2018 DU. All rights reserved.
//

import UIKit

protocol DKImagePickerViewControllerDelegate: NSObjectProtocol {
    func didSelectModels(photos: [UIImage], infos: [Any], sourceAssets: [DKAssetModel])
}

class DKImagePickerViewController: UIViewController {

    weak var delegate: DKImagePickerViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "图片选择"
        
        self.navigationController?.navigationBar.isHidden = true
        IMGInstance.pickerDelegate = self
        
        view.backgroundColor = UIColor.white
        view.addSubview(self.navigationBar)
        view.addSubview(self.mediaPickerView)
        view.addSubview(self.albumPickerView)
        
        self.navigationBar.addSubview(self.closeBtn)
        self.navigationBar.addSubview(self.finishBtn)
        self.navigationBar.addSubview(self.albumTitleBtn)
        self.finishBtn.sizeToFit()
        self.finishBtn.right = self.navigationBar.width - 16
        self.finishBtn.centerY = 42.5 + kStatusSafeMargin
        self.albumTitleBtn.sizeToFit()
        self.albumTitleBtn.centerX = self.navigationBar.width * 0.5
        self.albumTitleBtn.centerY = self.finishBtn.centerY
        self.closeBtn.sizeToFit()
        self.closeBtn.x = 16
        self.closeBtn.centerY = self.finishBtn.centerY
        
        //默认选中相机胶卷
        self.configTableViewData()
        //点返回和点完成 都会走这儿
        IMGInstance.configModel.previewVCBackBlock = {[weak self] in
            self?.mediaPickerView.updateCollectionView()
            self?.mediaPickerViewDidSelectModel(DKAssetModel())
        }
        
        self.finishBtn.isHidden = IMGInstance.configModel.allowCrop
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.view.bringSubviewToFront(self.navigationBar)
    }
    
    func configTableViewData() {
        _ = DKSystemPermission.photoAblumHasAuthority { (access) in
            if access {
                DispatchQueue.global().async {
                    IMGInstance.getAllAlbums(allowPickingVideo: IMGInstance.configModel.allowPickingVideo, allowPickingImage: IMGInstance.configModel.allowPickingImage, complete: { (arr) in
                        if arr.count > 0 {
                            IMGInstance.configModel.selectedAlbumModel = arr.first!
                        }
                        DispatchQueue.main.async {
                            self.albumPickerView.configTableViewData(with: arr)
                            self.mediaPickerView.albumModel = IMGInstance.configModel.selectedAlbumModel
                        }
                    })
                }
            }
        }
    }
    
    @objc func dismissAnimated(animated: Bool) {
        mediaPickerView.delegate = nil
        albumPickerView.delegate = nil
        self.dismiss(animated: true) {
            IMGInstance.refreshManagerConfig()
        }
    }
    
    @objc fileprivate func titleBtnClicked(_ btn: UIButton) {
        btn.isSelected = !btn.isSelected
        
        let transform = btn.isSelected ? CGAffineTransform.init(rotationAngle: CGFloat.pi) : CGAffineTransform.identity
        let transLate = btn.isSelected ? CGAffineTransform.init(translationX: 0, y: self.albumPickerView.height) : CGAffineTransform.identity
        if btn.isSelected {
            self.albumPickerView.isHidden = false
        }
        UIView.animate(withDuration: 0.25, animations: {
            btn.imageView?.transform = transform
            self.albumPickerView.transform = transLate
        }) { (finished) in
            if !btn.isSelected {
                self.albumPickerView.isHidden = true
            }
        }
        
        if btn.isSelected {
            self.albumPickerView.refreshTableViewData()
        }
    }
    
    @objc fileprivate func doneBtnClicked() {
        IMGInstance.didFinishPicking()
        self.dismissAnimated(animated: true)
    }
    
    //MARK:- setter & getter
    
    private lazy var navigationBar: UIView = {
        let view = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.width, height: kStatusBarAndNavigationBarHeight))
        view.backgroundColor = UIColor.white
        return view
    }()
    
    private lazy var closeBtn: UIButton = {
        let btn = UIButton.init(type: UIButton.ButtonType.custom)
        btn.setImage(UIImage.init(named: "ic_close"), for: .normal)
        btn.sizeToFit()
        btn.addTarget(self, action: #selector(dismissAnimated(animated:)), for: .touchUpInside)
        return btn
    }()
    
    private lazy var albumTitleBtn: UIButton = {
        let btn = UIButton.init(type: UIButton.ButtonType.custom)
        btn.setTitle("相机胶卷", for: .normal)
        btn.setImage(UIImage.init(named: "ic_smallarrow_black"), for: .normal)
        btn.imageEdgeInsets = UIEdgeInsets.init(top: 0, left: -7, bottom: 0, right: 7)
        btn.addTarget(self, action: #selector(titleBtnClicked(_:)), for: UIControl.Event.touchUpInside)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.medium)
        btn.setTitleColor(UIColor.hexColor("4a4a4a"), for: .normal)
        return btn
    }()
    
    private lazy var finishBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.addTarget(self, action: #selector(doneBtnClicked), for: UIControl.Event.touchUpInside)
        btn.setTitle("确定 (0)", for: .normal)
        btn.isEnabled = false
        btn.setTitleColor(UIColor.hexColor("9B8AE5"), for: .normal)
        btn.setTitleColor(UIColor.hexColor("9B8AE5")?.withAlphaComponent(0.5), for: .disabled)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.medium)
        return btn
    }()
    
    fileprivate lazy var mediaPickerView: DKMediaPickerView = {
        let media = DKMediaPickerView.init(frame: CGRect.init(x: 0, y: kStatusBarAndNavigationBarHeight, width: kScreenWidth, height: kScreenHeight - kStatusBarAndNavigationBarHeight))
        media.delegate = self
        return media
    }()
    
    fileprivate lazy var albumPickerView: DKAlbumPickerView = {
        let album = DKAlbumPickerView.init(frame: CGRect.init(x: 0, y: -kScreenHeight + kStatusBarAndNavigationBarHeight * 2, width: kScreenWidth, height: kScreenHeight - kStatusBarAndNavigationBarHeight))
        album.delegate = self
        return album
    }()
}

extension DKImagePickerViewController: DKMediaPickerViewDelegate {
    func mediaPickerViewCellWillUseCamera(_ isVideo: Bool) -> Bool {
        return true
    }
    
    func mediaPickerViewCellWillSelect(_ model: DKAssetModel) -> Bool {
        return true
    }
    
    func mediaPickerViewCellDidSelect(_ model: DKAssetModel) {
        
    }
    
    func mediaPickerViewWillSelectModel(_ model: DKAssetModel) -> Bool {
        return true
    }
    
    func mediaPickerViewDidSelectModel(_ model: DKAssetModel) {
        let selectedModels = IMGInstance.configModel.selectedModels
        finishBtn.setTitle("确定 (\(selectedModels.count))", for: .normal)
        if selectedModels.count > 0 {
            finishBtn.isEnabled = true
        } else {
            finishBtn.isEnabled = false
        }
    }
}

extension DKImagePickerViewController: DKAlbumPickerViewDelegate {
    func didSelectAlbum(_ album: DKAlbumModel) {
        if IMGInstance.configModel.selectedAlbumModel?.name != album.name {
            self.mediaPickerView.albumModel = album
        }
        albumTitleBtn.setTitle(album.name, for: .normal)
        self.titleBtnClicked(albumTitleBtn)
    }
}

extension DKImagePickerViewController: DKImagePickerDelegate {
    func imagePickerDidFinishPicking(photos: [UIImage], infos: [Any], sourceAssets: [DKAssetModel]) {
        self.delegate?.didSelectModels(photos: photos, infos: infos, sourceAssets: sourceAssets)
        if self.navigationController?.presentedViewController is UIImagePickerController {
            self.navigationController?.presentingViewController?
                .dismiss(animated: true, completion: nil)
        }else {
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func imagePickerDidChangePicking(models: [DKAssetModel]) {
        let selectedModels = IMGInstance.configModel.selectedModels
        finishBtn.setTitle("确定 (\(selectedModels.count))", for: .normal)
        if selectedModels.count > 0 {
            finishBtn.isEnabled = true
        } else {
            finishBtn.isEnabled = false
        }
    }
}
