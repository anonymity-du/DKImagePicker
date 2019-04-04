//
//  TestBAssetViewController.swift
//  DKImagePicker
//
//  Created by DU on 2019/2/11.
//  Copyright © 2019 DU. All rights reserved.
//

import UIKit

class TestBAssetViewController: UIViewController {
    private var configModel: DKImageConfigModel = DKImageConfigModel()
    private var selectedVideoModel: DKVideoModel?
    private var bottomBarGestureHandler: GenericPanGestureHandler?
    
    deinit {
        print("TestBAssetViewController dealloc")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Half Screen"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(customView: self.startBtn)
        self.view.backgroundColor = UIColor.white
        
        IMGInstance.refreshManagerConfig()

        self.view.addSubview(self.imgsView)
        self.view.addSubview(self.bottomBar)
        self.view.addSubview(self.bottomAssetView)
        
        self.imgsView.y = kNaviBarHeight + 30
        self.configPanGesture()
        //获取数据 fetch assets
        self.bottomAssetView.configTableViewData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(cropVideoSuccess(notification:)), name: NSNotification.Name("cropVideoSuccess"), object: nil)
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //由于IMGInstance为单例，configModel只有一个，在去往其他访问相册的页面后，
        //可能配置被更改了，需要在回到此页面时复原为原来的configModel
        self.bottomAssetView.changeImageConfigModel()
        self.navigationController?.isNavigationBarHidden = false
    }
    
    private func configPanGesture() {
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
            if direction == false {
                self?.bottomAssetView.changeSubviewsFrame(needChangeBounds: false)
            }else {
                self?.bottomAssetView.changeSubviewsFrame(needChangeBounds: true)
            }
        }
        self.bottomBarGestureHandler?.levelType = .mid
    }
    
    //MARK:- action
    
    @objc func startBtnClicked() {
        let vc = TestAAvatarViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func cropVideoSuccess(notification: Notification) {
        self.selectedVideoModel = notification.object as? DKVideoModel
        self.changeImgsView()
    }
    
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
            itemView.selectBlock = { [weak itemView] in
                print("itemview \(itemView?.tag ?? 0)")
            }
            itemView.deleteBlock = { [weak self, weak itemView] in
                let tag = itemView?.tag ?? 0
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
    
    private lazy var startBtn: UIButton = {
        let btn = UIButton.init(type: UIButton.ButtonType.custom)
        btn.setTitleColor(kGenericColor, for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btn.setTitle("打开头像设置", for: .normal)
        btn.size = CGSize.init(width: 80, height: 40)
        btn.addTarget(self, action: #selector(startBtnClicked), for: .touchUpInside)
        return btn
    }()
}
