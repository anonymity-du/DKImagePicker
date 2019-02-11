//
//  TestBViewController.swift
//  DKImagePicker
//
//  Created by 杜奎 on 2019/1/10.
//  Copyright © 2019 杜奎. All rights reserved.
//

import UIKit

class TestBViewController: UIViewController {

    private var selectedVideoModel: DKVideoModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Half Screen"
        self.view.backgroundColor = UIColor.white
        
        self.view.addSubview(self.imgsView)
        self.view.addSubview(self.bottomAssetView)
        
        self.imgsView.y = kNaviBarHeight + 30
        self.bottomAssetView.bottom = self.view.height - kTabbarHeight
        
        // Do any additional setup after loading the view.
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
    
    private lazy var bottomAssetView: DKImagePickerView = {
        let view = DKImagePickerView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.width, height: 267 + kTabbarSafeBottomMargin))
        view.backgroundColor = UIColor.red
        view.modelsChangeBlock = { [weak self] _ in
            self?.changeImgsView()
        }
        return view
    }()
    
}
