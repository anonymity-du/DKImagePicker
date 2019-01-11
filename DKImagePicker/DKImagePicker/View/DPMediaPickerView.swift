//
//  DPMediaPickerView.swift
//  DatePlay
//
//  Created by 张昭 on 2018/10/22.
//  Copyright © 2018 AimyMusic. All rights reserved.
//

import UIKit

@objc protocol DPMediaPickerViewDelegate: NSObjectProtocol {
    //将要选择拍照或者拍摄
    @objc func mediaPickerViewCellWillUseCamera(_ isVideo: Bool) -> Bool
    //将要选择
    @objc func mediaPickerViewWillSelectModel(_ model: DPAssetModel) -> Bool
    //已经选择
    @objc func mediaPickerViewDidSelectModel(_ model: DPAssetModel)
    //将要选择Cell
    @objc func mediaPickerViewCellWillSelect(_ model: DPAssetModel) -> Bool
    //已经选择Cell
    @objc func mediaPickerViewCellDidSelect(_ model: DPAssetModel)
}

class DPMediaPickerView: UIView {

    fileprivate var collectionView: UICollectionView?
    fileprivate var dataSource = [DPAssetModel]()
    var cameraIndex:Int = -1 //拍照按钮的位置
    var modelIndex:Int = 0 //相册默认的开始位置
    weak var delegate: DPMediaPickerViewDelegate?

    var albumModel: DPAlbumModel? {
        didSet {
            if let model = albumModel {
                self.dataSource.removeAll()
                self.dataSource.append(contentsOf: model.models)
                if IMGInstance.configModel.showTakePhotoBtn {
                    self.cameraIndex = IMGInstance.configModel.sortAscendingByModificationDate ?  self.dataSource.count : 0
                    self.modelIndex = IMGInstance.configModel.sortAscendingByModificationDate ? 0 : 1
                }
                self.collectionView?.reloadData()
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let itemWidth = (kScreenWidth - 5) * 0.25
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize.init(width: itemWidth, height: itemWidth)
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        
        collectionView = UICollectionView.init(frame: self.bounds, collectionViewLayout: layout)
        collectionView?.backgroundColor = UIColor.hexColor("f3f3f3")
        collectionView?.contentInset = UIEdgeInsets.init(top: 0, left: 1, bottom: 0, right: 1)
        addSubview(collectionView!)
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.register(DPImagePickerCell.self, forCellWithReuseIdentifier: "DPImagePickerCell")
        collectionView?.register(DPImagePickerCameraCell.self, forCellWithReuseIdentifier: "DPImagePickerCameraCell")
//        collectionView?.snp.makeConstraints({ (make) in
//            make.edges.equalTo(UIEdgeInsets.zero)
//        })
    }
    
    // MARK: - Public Methods
    
    func resetScrollViewContentInset(_ offsetY: CGFloat) {
        collectionView?.contentInset = UIEdgeInsets.init(top: 0, left: 1, bottom: 0 + offsetY, right: 1)
    }
    
    func updateCollectionView() {
        if let cells = self.collectionView?.visibleCells {
            for cell in cells {
                if cell is DPImagePickerCell {
                    let imageCell = cell as! DPImagePickerCell
                    imageCell.resetIndexLabel()
                }
            }
        }
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegate
extension DPMediaPickerView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == self.cameraIndex {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DPImagePickerCameraCell", for: indexPath) as! DPImagePickerCameraCell
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DPImagePickerCell", for: indexPath) as! DPImagePickerCell
            let model = self.dataSource[indexPath.row - self.modelIndex]
            cell.index = model.mediaType == .video ? 0 : IMGInstance.calculateCellSelectedIndex(model)
            cell.model = model
            cell.delegate = self
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if IMGInstance.configModel.showTakePhotoBtn {
            return dataSource.count + (self.cameraIndex == -1 ? 0 : 1)
        }
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if indexPath.row == self.cameraIndex {
            
            if let should = self.delegate?.mediaPickerViewCellWillUseCamera(IMGInstance.configModel.allowPickingVideo),should == false {
                return
            }
            
            IMGInstance.configModel.systemImagePickerVCCompleteBlock = nil
            if IMGInstance.configModel.selectedModels.count < IMGInstance.configModel.maxImagesCount {
//                DPSystemPermission.shared.cameraAblumAuthority { (success) in
//                    if success {
//                        let configModel = IMGInstance.configModel
//                        configModel.systemImagePickerVCCompleteBlock = { model in
//                            if configModel.sortAscendingByModificationDate {
//                                self.albumModel?.models.append(model)
//                                self.dataSource.append(model)
//                            }else {
//                                self.albumModel?.models.insert(model, at: 0)
//                                self.dataSource.insert(model, at: 0)
//                            }
//                            self.albumModel?.count += 1
//                            self.collectionView?.reloadData()
//                        }
//                        IMGInstance.pushImagePickerController(isTakePhoto: !IMGInstance.configModel.allowPickingVideo)
//                    }
//                }
            } else {
                var strTip = ""
                if IMGInstance.configModel.diyTip.count > 0 {
                    strTip = IMGInstance.configModel.diyTip
                } else {
                    strTip = "最多只能选择\(IMGInstance.configModel.maxImagesCount)张"
                }
                kFrontWindow().makeToast(strTip)
            }
            return
        }
        
        let model = self.dataSource[indexPath.row - self.modelIndex]
        if let shouldSelectCell = self.delegate?.mediaPickerViewCellWillSelect(model),shouldSelectCell == false {
            return
        }
        
        if IMGInstance.configModel.allowPreview && model.mediaType != .video {
//            let vc = DPImagePreviewViewController.init()
//            vc.models = self.dataSource
//            vc.curIndex = indexPath.row - self.modelIndex
//            vc.isCropImage = IMGInstance.configModel.allowCrop
//            if let nav = IMGInstance.pickerNav {
//                nav.pushViewController(vc, animated: true)
//            }else {
//                let nav = DPBaseNavigationViewController.init(rootViewController: vc)
//                IMGInstance.pickerNav = nav
//                DPUtil.topViewController()?.navigationController?.present(nav, animated: true, completion: nil)
//            }
        } else  {
            IMGInstance.addAssetModel(with: model)
            self.delegate?.mediaPickerViewCellDidSelect(model)
        }
    }
    
}

extension DPMediaPickerView: DPImagePickerCellDelegate {
    func cellSelectBtnWillClicked(with model: DPAssetModel, isSelected: Bool,cell: DPImagePickerCell) -> Bool {
        let should = self.delegate?.mediaPickerViewWillSelectModel(model) ?? true
        return should
    }
    func cellSelectBtnDidClicked(with model: DPAssetModel, isSelected: Bool,cell: DPImagePickerCell) {
        self.delegate?.mediaPickerViewDidSelectModel(model)
        self.updateCollectionView()
    }
}

