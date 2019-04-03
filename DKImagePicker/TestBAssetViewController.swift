//
//  TestBAssetViewController.swift
//  DKImagePicker
//
//  Created by 杜奎 on 2019/2/11.
//  Copyright © 2019 DU. All rights reserved.
//

import UIKit

class TestBAssetViewController: UIViewController {
    var dataDict: [String: Any]?
    private var configModel: DKImageConfigModel = DKImageConfigModel()
    private var mixPhotoAndVideo: Bool = false
    private var muiltyAlbums: Bool = false
    private var selectedVideoModel: DKVideoModel?
    private var bottomBarGestureHandler: GenericPanGestureHandler?
    
    convenience init(dataDict: [String: Any]) {
        self.init()
        self.dataDict = dataDict
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Half Screen"
        self.view.backgroundColor = UIColor.white
        
        self.refreshConfig()
        
        self.view.addSubview(self.imgsView)
        self.view.addSubview(self.bottomBar)
        self.view.addSubview(self.bottomAssetView)
        
        self.imgsView.y = kNaviBarHeight + 30
        self.bottomBarGestureHandler = GenericPanGestureHandler.init(gestureView: bottomBarCoverView, handleView: bottomBar, minY: kStatusBarAndNavigationBarHeight, midY: kScreenHeight - 315 - kTabbarSafeBottomMargin, maxY: kScreenHeight - bottomBar.height)
        self.bottomBarGestureHandler?.offsetCompleteBlock = { [weak self] in
            self?.bottomAssetView.changeSubviewsFrame(needChangeBounds: true)
        }
        self.bottomBarGestureHandler?.offsetChangeBlock = { [weak self] afterY, _,direction in
            self?.bottomAssetView.y = self?.bottomBar.bottom ?? 0
            if afterY < (self?.view.height ?? 0) - 267 - 48 {
                self?.bottomAssetView.height = (self?.view.height ?? 0) - (self?.bottomAssetView.y ?? 0)
            }else {
                self?.bottomAssetView.height = 267
            }
            if afterY < self!.view.height && self!.bottomAssetView.isHidden {
                self?.bottomAssetView.isHidden = false
            }
            if direction != nil {
                if direction! == false {
                    self?.bottomAssetView.changeSubviewsFrame(needChangeBounds: false)
                }else {
                    self?.bottomAssetView.changeSubviewsFrame(needChangeBounds: true)
                }
            }else {
                self?.bottomAssetView.changeSubviewsFrame(needChangeBounds: true)
            }
        }
        self.bottomBarGestureHandler?.levelType = .mid
        
        // Do any additional setup after loading the view.
    }
    
    func refreshConfig() {

        for key in self.dataDict!.keys {
            let value = self.dataDict?[key] as! Bool
            if key == "是否按时间升序" {
                self.configModel.sortAscendingByModificationDate = value
            }else if key == "是否允许有图片" {
                self.configModel.allowPickingImage = value
            }else if key == "是否允许有视频" {
                self.configModel.allowPickingVideo = value
            }else if key == "是否允许图片视频混合" {
                self.mixPhotoAndVideo = value
            }else if key == "是否允许多个相册" {
                self.muiltyAlbums = value
            }else if key == "是否可以裁剪（单选）" {
                configModel.allowCrop = value
            }
        }
        IMGInstance.configModel = self.configModel
    }
    
    //MARK:- action
    
    private func changeImgsView() {
        for subview in self.imgsView.subviews {
            if let selectView = subview as? DKSelectedImageView {
                selectView.imgView.image = nil
            }
            subview.removeFromSuperview()
        }
        var height: CGFloat = 0
        
        var existVideo = false
        if self.selectedVideoModel != nil {
            existVideo = true
        }
        
        let itemWidth: CGFloat = 74 * K320Scale
        
        for (index, itemModel) in self.bottomAssetView.selectedAssetModels.enumerated() {
            let itemView = DKSelectedImageView.init(frame: CGRect.init(x: 0, y: 0, width: itemWidth, height: itemWidth))
            if index == 0 && itemModel.mediaType == .video {
                if existVideo == false {
                    break
                }else {
                    itemView.videoModel = self.selectedVideoModel
                }
            }else {
                itemView.assetModel = itemModel
            }
            self.imgsView.addSubview(itemView)
            let col = index%3
            let row = index/3
            itemView.tag = 100 + index
            itemView.selectBlock = { [weak self] in
                print("itemview \(itemView.tag)")
                
                //                if self?.selectedVideoModel != nil {
                //                    let playView = DPVideoScreenPlayView.init(frame: self?.view.bounds ?? CGRect.zero)
                //                    playView.videoSize = CGSize.init(width: self?.selectedVideoModel?.width ?? 210, height: self?.selectedVideoModel?.height ?? 210)
                //                    playView.outsideFrame = DPUtil.frontWindow().convert(itemView.frame, from: self?.imgsView)
                //                    playView.thumbImage = self?.selectedVideoModel?.coverThumbImg
                //                    playView.url = URL.init(fileURLWithPath: self?.selectedVideoModel?.path ?? "")
                //                    playView.show()
                //                }else if let selectAssets = self?.bottomAssetView.selectedAssetModels {
                //                    let isFirst = self?.inputTextView.inputTextView.isFirstResponder ?? false
                //                    let picPreview = DPPicPreviewPopView.init(assetModels:  selectAssets, initIndex: index)
                //                    picPreview.delegate = self
                //                    picPreview.animationCompleteAction = { isShow in
                //                        if !isShow {
                //                            if isFirst == true {
                //                                self?.inputTextView.inputTextView
                //                                    .becomeFirstResponder()
                //                            }
                //                        }
                //                    }
                //                    picPreview.show()
                //                    self?.view.endEditing(true)
                //                }
            }
            itemView.deleteBlock = { [weak self] in
                let tag = itemView.tag
                self?.selectedVideoModel = nil //无论是视频还是图片，都可以将选中的视频model置空
                self?.bottomAssetView.deleteImg(index: tag)
            }
            itemView.x = (itemWidth + 4) * CGFloat(col)
            itemView.y = (itemWidth + 4) * CGFloat(row)
            height = CGFloat(itemWidth + (itemWidth + 4) * CGFloat(row))
        }
        self.imgsView.height = height
    }
    
    //MARK:- setter & getter
    
    private lazy var imgsView: UIView = {
        let view = UIView.init(frame: CGRect.init(x: 16, y: 0, width: 74 * K320Scale * 3 + 8, height: 0))
        view.backgroundColor = UIColor.white
        return view
    }()
    
    private lazy var bottomBar: UIView = {
        let view = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.width, height: 48))
        view.addSubview(bottomBarCoverView)
        view.backgroundColor = UIColor.clear
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize.init(width: 0, height: 2)
        view.layer.shadowOpacity = Float(0.14)
        view.layer.shadowRadius = 3
        
        let label = UILabel.init()
        label.text = "拖拽条"
        label.textColor = kGenericColor
        label.sizeToFit()
        view.addSubview(label)
        label.centerX = view.width * 0.5
        label.centerY = view.height * 0.5
        return view
    }()
    
    private lazy var bottomBarCoverView: UIView = {
        let view = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.width, height: 48))
        view.backgroundColor = UIColor.white
        view.createCorner(bounds: view.bounds, rectCorner: [.topRight,.topLeft], cornerRadius: 12)
        return view
    }()
    
    private lazy var bottomAssetView: DKImagePickerView = {
        let view = DKImagePickerView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.width, height: 267 + kTabbarSafeBottomMargin))
        view.backgroundColor = UIColor.red
        view.modelsChangeBlock = { [weak self] _ in
            self?.changeImgsView()
        }
        return view
    }()

}
