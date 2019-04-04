//
//  DKImagePreviewViewController.swift
//  DatePlay
//
//  Created by DU on 2018/11/1.
//  Copyright © 2018年 DU. All rights reserved.
//

import UIKit
import AVKit
import Photos

class DKImagePreviewViewController: UIViewController, UICollectionViewDelegate,UICollectionViewDataSource {

    var models: [DKAssetModel]?

    var curIndex: Int = 0
    
    var fromImagePicker: Bool = false
    var isCropImage: Bool = false
    
    private var hideBar = false
    private var progress: Double = 0
    private var alertView: DKAlertView?
    private var photoTempArray = [UIImage]()
    private var assetTempArray = [PHAsset]()
    private var modelTempArray = [DKAssetModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.loadSubview()
        self.navigationController?.navigationBar.isHidden = true
        self.automaticallyAdjustsScrollViewInsets = false
        self.modelTempArray.append(contentsOf: IMGInstance.configModel.selectedModels)
        self.assetTempArray.append(contentsOf: IMGInstance.configModel.selectedAssets)
        let contentWidth = self.view.width + 20.0
        self.collectionView.contentSize = CGSize.init(width: contentWidth * CGFloat(self.models!.count), height: 0)
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.curIndex > 0 {
            let contentWidth = self.view.width + 20
            self.collectionView.setContentOffset(CGPoint.init(x: contentWidth * CGFloat(self.curIndex), y: 0), animated: false)
        }
        self.refreshNaviBarAndBottomBarState()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.fromImagePicker {
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.fromImagePicker {
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.view.bringSubviewToFront(self.navigationBar)
    }
    
    func loadSubview() {
        self.titleLabel.text = isCropImage ? "图片裁剪" : "图片预览"
        self.titleLabel.sizeToFit()
        
        view.addSubview(self.collectionView)
        view.addSubview(self.navigationBar)
        view.addSubview(self.bottomBar)
        bottomBar.bottom = self.view.height
        
        self.navigationBar.addSubview(self.backBtn)
        self.navigationBar.addSubview(self.titleLabel)
        self.backBtn.x = 16
        self.backBtn.centerY = self.navigationBar.height - 22
        self.titleLabel.centerY = self.backBtn.centerY
        self.titleLabel.centerX = self.navigationBar.width * 0.5
        
        if IMGInstance.configModel.allowCrop {
            view.addSubview(self.cropBgView)
            DKCropViewManager.overlayClipping(with: self.cropBgView, cropRect: IMGInstance.configModel.cropRect, containerView: self.view, needCircleCrop: IMGInstance.configModel.needCircleCrop)
            view.addSubview(self.cropView)
            if IMGInstance.configModel.cropViewSettingBlock != nil {
                IMGInstance.configModel.cropViewSettingBlock!(self.cropView)
            }
            self.navigationBar.addSubview(self.completeBtn)
            self.bottomBar.isHidden = true
            self.completeBtn.right = self.view.width - 16
            self.completeBtn.centerY = self.navigationBar.height - 22
        }else {
            self.navigationBar.addSubview(self.selectedView)
            self.backBtn.imageView?.tintColor = UIColor.white
            let backImage = self.backBtn.imageView?.image
            self.backBtn.setImage(backImage?.withRenderingMode(.alwaysTemplate), for: .normal)
            self.navigationBar.backgroundColor = UIColor.init(white: 0, alpha: 0.4)
            self.selectedView.centerY = self.navigationBar.height - 22
            self.selectedView.right = self.view.width - 16
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return IMGInstance.configModel.allowCrop ? .default : .lightContent
    }
    
    @objc func pop() {
        if IMGInstance.configModel.needPreviewTempSelected {
            self.clearTemp()
        }
        if IMGInstance.configModel.previewVCBackBlock != nil {
            IMGInstance.configModel.previewVCBackBlock!()
        }

        if self.fromImagePicker {
            self.navigationController?.dismiss(animated: true, completion: nil)
        }else if self.navigationController?.viewControllers.count == 1 {
            self.navigationController?.dismiss(animated: true, completion: nil)
        }else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func dismissAnimated(animated: Bool) {

        if IMGInstance.configModel.needPreviewTempSelected {
            self.clearTemp()
        }
        if IMGInstance.configModel.previewVCBackBlock != nil {
            IMGInstance.configModel.previewVCBackBlock!()
        }
        dismiss(animated: animated) {
            
        }
    }
    
    private func clearTemp() {
        IMGInstance.configModel.selectedModels.removeAll()
        IMGInstance.configModel.selectedAssets.removeAll()
        for item in self.modelTempArray {
            item.isSelected = true
            IMGInstance.configModel.selectedAssets.append(item.asset!)
        }
        IMGInstance.configModel.selectedModels = self.modelTempArray
        if let delegate = IMGInstance.pickerDelegate, delegate.responds(to: #selector(DKImagePickerDelegate.imagePickerDidChangePicking(models:))) {
            IMGInstance.pickerDelegate?.imagePickerDidChangePicking!(models: IMGInstance.configModel.selectedModels)
        }
    }
    
    //MARK:- action
    
    @objc func selectedBtnClicked() {
        let selectedNumber = IMGInstance.configModel.selectedModels.count
        if let model = self.models?[self.curIndex] {
            if !model.isSelected {
                if selectedNumber >= IMGInstance.configModel.maxImagesCount {
                    
                    var strTip = ""
                    if IMGInstance.configModel.diyTip.count > 0 {
                        strTip = IMGInstance.configModel.diyTip
                    } else {
                        strTip = "最多只能选择\(IMGInstance.configModel.maxImagesCount)张"
                    }
                    kFrontWindow().makeToast(strTip)
                    return
                }else {
                    IMGInstance.addAssetModel(with: model)
                    self.selectedBtn.setBackgroundImage(UIImage.init(named: "ic_selectedbox"), for: .normal)
                    model.isSelected = true
                }
            }else {
                for itemAssetModel in IMGInstance.configModel.selectedModels {
                    if model.asset?.localIdentifier == itemAssetModel.asset?.localIdentifier {
                        IMGInstance.removeAssetModel(with: model)
                        self.selectedBtn.setBackgroundImage(UIImage.init(named: "ic_selectbox"), for: .normal)
                        model.isSelected = false
                    }
                }
            }
            self.refreshNaviBarAndBottomBarState()
        }
    }
    
    @objc func completeBtnClicked() {
        
        if progress > 0 && progress < 1  {
            alertView = DKAlertView.init(title: "提示", message: "正在从iCloud同步照片", buttonTitles: ["确定"], leftBtnActionBlock: nil, rightBtnActionBlock: nil)
            alertView?.show()
        }
        
        if IMGInstance.configModel.selectedModels.count == 0 && IMGInstance.configModel.maxImagesCount > 0, let model = self.models?[self.curIndex] {
            model.isSelected = true
            IMGInstance.addAssetModel(with: model)
        }
        
        if IMGInstance.configModel.allowCrop {
            let indexPath = IndexPath.init(row: curIndex, section: 0)
            let cell = self.collectionView.cellForItem(at: indexPath) as! DKPhotoPreviewCell
            if let cropedImage = DKCropViewManager.cropImage(with: cell.previewView.imageView, toRect: IMGInstance.configModel.cropRect, zoomScale: cell.previewView.scrollView.zoomScale, containerView: self.view) {
                if let delegate = IMGInstance.pickerDelegate, delegate.responds(to: #selector(DKImagePickerDelegate.imagePickerDidFinishPicking(photos:infos:sourceAssets:))) {
                    delegate.imagePickerDidFinishPicking!(photos: [cropedImage], infos: [], sourceAssets: [cell.model!])
                }
            }
        }else {
            if IMGInstance.configModel.previewVCCompleteBlock != nil {
                IMGInstance.configModel.previewVCCompleteBlock!()
            }else {
//                IMGInstance.didFinishPicking()
                self.pop()
            }
        }
    }
    
    private func didTapPreviewCell() {
        self.hideBar = !self.hideBar
        self.navigationBar.isHidden = self.hideBar
        self.bottomBar.isHidden = self.hideBar
    }
    
    private func refreshNaviBarAndBottomBarState() {
        if let model = self.models?[self.curIndex] {
            let index = IMGInstance.calculateCellSelectedIndex(model)
            self.selectedBtn.setBackgroundImage(UIImage.init(named: index > 0 ? "ic_selectedbox" : "ic_selectbox"), for: .normal)
            model.isSelected = index > 0
            indexLabel.text = "\(index)"
            indexLabel.sizeToFit()
            indexLabel.center = selectedBtn.center
            indexLabel.isHidden = index <= 0
        }
        self.completeBtn.isEnabled = self.models!.count > 0
        
    }
    
    //MARK:- delegate & datasource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.models?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let assetModel = self.models![indexPath.row]
        let cell: DKPhotoPreviewCell = collectionView.dequeueReusableCell(withReuseIdentifier:  NSStringFromClass(DKPhotoPreviewCell.self), for: indexPath) as! DKPhotoPreviewCell
        cell.cropRect = IMGInstance.configModel.cropRect
        cell.allowCrop = IMGInstance.configModel.allowCrop
        cell.imageProgressUpdateBlock = {[weak self] progress in
            self?.progress = progress
            if progress >= 1 {
                if self?.alertView != nil && self?.collectionView.visibleCells.contains(cell) ?? false {
                    self?.alertView?.dismiss()
                    self?.completeBtnClicked()
                }
            }
        }
        cell.model = assetModel
        cell.singleTapBlock = { [weak self] in
            self?.didTapPreviewCell()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if cell is DKPhotoPreviewCell {
            (cell as! DKPhotoPreviewCell).recoverSubviews()
        }
    }
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if cell is DKPhotoPreviewCell {
            (cell as! DKPhotoPreviewCell).recoverSubviews()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        var offSetWidth = scrollView.contentOffset.x
        offSetWidth = offSetWidth +  ((self.view.width + 20) * 0.5);
        
        let currentIndex = Int(offSetWidth / (self.view.width + 20))
        
        if (currentIndex < self.models!.count && self.curIndex != currentIndex) {
            self.curIndex = currentIndex
            self.refreshNaviBarAndBottomBarState()
        }
        NotificationCenter.default.post(name: NSNotification.Name.photoPreviewCollectionViewDidScroll, object: nil)
    }
    
    //MARK:- setter & getter
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel.init()
        label.textColor = UIColor.black
        return label
    }()
    
    private lazy var selectedView: UIView = {
        let view = UIView.init()
        view.addSubview(self.selectedBtn)
        view.addSubview(self.indexLabel)
        
        view.size = self.selectedBtn.size
        self.indexLabel.sizeToFit()
        self.indexLabel.center = self.selectedBtn.center
        return view
    }()
    
    private lazy var selectedBtn: UIButton = {
        let btn = UIButton.init(type: UIButton.ButtonType.custom)
        btn.setBackgroundImage(UIImage.init(named: "ic_selectbox"), for: .normal)
        btn.sizeToFit()
        btn.sizeToFit()
        btn.addTarget(self, action: #selector(selectedBtnClicked), for: .touchUpInside)
        return btn
    }()
    
    private lazy var indexLabel: UILabel = {
        let label = UILabel.init()
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.medium)
        label.isHidden = true
        return label
    }()
    
    private lazy var bottomBar: UIView = {
        let view = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.width, height: 45 + kTabbarSafeBottomMargin))
        view.backgroundColor = UIColor.init(white: 0, alpha: 0.4)
        if !IMGInstance.configModel.allowCrop {
            view.addSubview(completeBtn)
            completeBtn.right = view.width - 16
            completeBtn.centerY = 22.5
        }
        return view
    }()
    
    private lazy var completeBtn: UIButton = {
        let btn = UIButton.init(type: UIButton.ButtonType.custom)
        btn.setTitle("完成", for: .normal)
        if !IMGInstance.configModel.allowCrop {
            btn.backgroundColor = UIColor.hexColor("#A28DFF")
            btn.size = CGSize.init(width: 55, height: 29)
            btn.layer.cornerRadius = 8
            btn.layer.masksToBounds = true
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 12)
            btn.setTitleColor(UIColor.white, for: .normal)
        }else {
            btn.setTitleColor(UIColor.hexColor("9B8AE6"), for: .normal)
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: UIFont.Weight.medium)
            btn.sizeToFit()
        }
        btn.addTarget(self, action: #selector(completeBtnClicked), for: .touchUpInside)
        return btn
    }()
    

    private lazy var layout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout.init()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        return flowLayout
    }()
    
    private lazy var collectionView: UICollectionView = {
        self.layout.itemSize = CGSize.init(width: self.view.width + 20, height: self.view.height)

        let collection = UICollectionView.init(frame: CGRect.init(origin: CGPoint.init(x: -10, y: 0), size: self.layout.itemSize), collectionViewLayout: self.layout)
        collection.backgroundColor = UIColor.black
        collection.dataSource = self
        collection.delegate = self
        collection.isPagingEnabled = true
        collection.scrollsToTop = false
        collection.showsHorizontalScrollIndicator = false
        collection.contentOffset = CGPoint.zero
        collection.contentSize = CGSize.init(width: 0, height: 0)
        collection.register(DKPhotoPreviewCell.self, forCellWithReuseIdentifier: NSStringFromClass(DKPhotoPreviewCell.self))
        collection.register(DKBaseAssetCell.self, forCellWithReuseIdentifier: NSStringFromClass(DKBaseAssetCell.self))

        return collection
    }()
    
    private lazy var cropView: UIView = {
        let view = UIView.init()
        view.isUserInteractionEnabled = false
        view.frame = IMGInstance.configModel.cropRect

        if IMGInstance.configModel.needCircleCrop {
            view.layer.cornerRadius = IMGInstance.configModel.cropRect.size.width / 2;
            view.clipsToBounds = true
        }
        return view
    }()

    private lazy var cropBgView: UIView = {
        let view = UIView.init()
        view.isUserInteractionEnabled = false
        view.frame = self.view.bounds
        view.backgroundColor = UIColor.clear
        return view
    }()

    private lazy var navigationBar: UIView = {
        let view = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.width, height: kStatusBarAndNavigationBarHeight))
        view.backgroundColor = UIColor.white
        return view
    }()
    
    private lazy var backBtn: UIButton = {
        let btn = UIButton.init(type: UIButton.ButtonType.custom)
        btn.setImage(UIImage.init(named: "back"), for: .normal)
        btn.sizeToFit()
        btn.addTarget(self, action: #selector(pop), for: .touchUpInside)
        return btn
    }()
    
}
