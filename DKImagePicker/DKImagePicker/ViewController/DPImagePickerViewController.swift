//
//  DPImagePickerViewController.swift
//  DatePlay
//
//  Created by 张昭 on 2018/10/22.
//  Copyright © 2018 AimyMusic. All rights reserved.
//

import UIKit

protocol DPImagePickerViewControllerDelegate: NSObjectProtocol {
    func didSelectModels(photos: [UIImage], infos: [Any], sourceAssets: [DPAssetModel])
}

class DPImagePickerViewController: UIViewController {

    weak var delegate: DPImagePickerViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "图片选择"
        
        IMGInstance.pickerDelegate = self
        
        view.backgroundColor = UIColor.white
        view.addSubview(self.mediaPickerView)
        view.addSubview(self.albumPickerView)
        
        //默认选中相机胶卷操作
        self.configTableViewData()
        //点返回和点完成 都会走这儿
        IMGInstance.configModel.previewVCBackBlock = {[weak self] in
            self?.mediaPickerView.updateCollectionView()
            self?.mediaPickerViewDidSelectModel(DPAssetModel())
        }
        
//        self.navigationBar.titleView?.isHidden = true
        self.finishBtn.isHidden = IMGInstance.configModel.allowCrop
//        self.navigationBar.addSubview(self.finishBtn)
//        self.navigationBar.addSubview(self.albumTitleView)
       
//        self.finishBtn.snp.makeConstraints { (make) in
//            make.right.equalTo(-16)
//            make.centerY.equalTo(42.5 + kStatusSafeMargin)
//        }
//        self.albumTitleView.snp.makeConstraints { (make) in
//            make.centerY.equalTo(self.finishBtn.snp.centerY)
//            make.centerX.equalToSuperview()
//        }
    }
    
    func configTableViewData() {
//        DPSystemPermission.photoAblumAuthority { (access) in
//            if access {
//                DispatchQueue.global().async {
//                    IMGInstance.getAllAlbums(allowPickingVideo: IMGInstance.configModel.allowPickingVideo, allowPickingImage: IMGInstance.configModel.allowPickingImage, complete: { (arr) in
//                        if arr.count > 0 {
//                            IMGInstance.configModel.selectedAlbumModel = arr.first!
//                        }
//                        DispatchQueue.main.async {
//                            self.albumPickerView.configTableViewData(with: arr)
//                            self.mediaPickerView.albumModel = IMGInstance.configModel.selectedAlbumModel
//                        }
//                    })
//                }
//            }
//        }
    }
    
//    override func dismissAnimated(animated: Bool) {
//        mediaPickerView.delegate = nil
//        albumPickerView.delegate = nil
//        self.dismiss(animated: true) {
//            IMGInstance.refreshManagerConfig()
//        }
//    }
    
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
//        self.dismissAnimated(animated: true)
    }
    
    //MARK:- setter & getter
    
    private lazy var albumTitleView: UIButton = {
        let btn = UIButton.init(type: UIButton.ButtonType.custom)
        btn.setTitle("相机胶卷", for: .normal)
        btn.setImage(UIImage.init(named: "ic_arrow_bot"), for: .normal)
//        btn.iconPosition = RTIconPosition.right.rawValue
//        btn.iconMargin = 7
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
    
    fileprivate lazy var mediaPickerView: DPMediaPickerView = {
        let media = DPMediaPickerView.init(frame: CGRect.init(x: 0, y: kStatusBarAndNavigationBarHeight, width: kScreenWidth, height: kScreenHeight - kStatusBarAndNavigationBarHeight))
        media.delegate = self
        return media
    }()
    
    fileprivate lazy var albumPickerView: DPAlbumPickerView = {
        let album = DPAlbumPickerView.init(frame: CGRect.init(x: 0, y: -kScreenHeight + kStatusBarAndNavigationBarHeight * 2, width: kScreenWidth, height: kScreenHeight - kStatusBarAndNavigationBarHeight))
        album.delegate = self
        return album
    }()
}

extension DPImagePickerViewController: DPMediaPickerViewDelegate {
    func mediaPickerViewCellWillUseCamera(_ isVideo: Bool) -> Bool {
        return true
    }
    
    func mediaPickerViewCellWillSelect(_ model: DPAssetModel) -> Bool {
        return true
    }
    
    func mediaPickerViewCellDidSelect(_ model: DPAssetModel) {
        
    }
    
    func mediaPickerViewWillSelectModel(_ model: DPAssetModel) -> Bool {
        return true
    }
    
    func mediaPickerViewDidSelectModel(_ model: DPAssetModel) {
        let selectedModels = IMGInstance.configModel.selectedModels
        finishBtn.setTitle("确定 (\(selectedModels.count))", for: .normal)
        if selectedModels.count > 0 {
            finishBtn.isEnabled = true
        } else {
            finishBtn.isEnabled = false
        }
    }
}

extension DPImagePickerViewController: DPAlbumPickerViewDelegate {
    func didSelectAlbum(_ album: DPAlbumModel) {
        if IMGInstance.configModel.selectedAlbumModel?.name != album.name {
            self.mediaPickerView.albumModel = album
        }
        albumTitleView.setTitle(album.name, for: .normal)
        self.titleBtnClicked(albumTitleView)
    }
}

extension DPImagePickerViewController: DPImagePickerDelegate {
    func imagePickerDidFinishPicking(photos: [UIImage], infos: [Any], sourceAssets: [DPAssetModel]) {
        self.delegate?.didSelectModels(photos: photos, infos: infos, sourceAssets: sourceAssets)
        if self.navigationController?.presentedViewController is UIImagePickerController {
            self.navigationController?.presentingViewController?
                .dismiss(animated: true, completion: nil)
        }else {
            self.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
    
    func imagePickerDidChangePicking(models: [DPAssetModel]) {
        let selectedModels = IMGInstance.configModel.selectedModels
        finishBtn.setTitle("确定 (\(selectedModels.count))", for: .normal)
        if selectedModels.count > 0 {
            finishBtn.isEnabled = true
        } else {
            finishBtn.isEnabled = false
        }
    }
}
