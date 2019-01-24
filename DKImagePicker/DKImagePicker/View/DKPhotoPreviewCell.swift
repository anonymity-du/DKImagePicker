//
//  DKPhotoPreviewCell.swift
//  DatePlay
//
//  Created by 杜奎 on 2018/11/1.
//  Copyright © 2018年 AimyMusic. All rights reserved.
//

import UIKit
import AVKit
import Photos

class DKPhotoPreviewCell: DKBaseAssetCell {
    
    var imageProgressUpdateBlock: ((_ progress: Double)->())?
    
    override func configSubviews() {
        super.configSubviews()
        self.contentView.backgroundColor = UIColor.clear
        addSubview(previewView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewView.bounds = self.bounds
    }
    
    func recoverSubviews() {
        previewView.recoverSubviews()
    }

    //MARK:- setter & getter
    
    override var model: DKAssetModel? {
        didSet {
            previewView.asset = model?.asset
        }
    }
    
    var allowCrop: Bool = false {
        didSet {
            previewView.allowCrop = allowCrop
        }
    }
    
    var cropRect: CGRect = CGRect.zero {
        didSet {
            previewView.cropRect = cropRect
        }
    }
    
    lazy var previewView: DKPhotoPreviewView = {
        let view = DKPhotoPreviewView.init(frame: self.bounds)
        view.singleTapBlock = {[weak self] in
            if self?.singleTapBlock != nil {
                self?.singleTapBlock!()
            }
        }
        view.imageProgressUpdateBlock = { [weak self] progress in
            if self?.imageProgressUpdateBlock != nil {
                self?.imageProgressUpdateBlock!(progress)
            }
        }
        return view
    }()
}


class DKPhotoPreviewView: UIView, UIScrollViewDelegate {
    private let progressH: CGFloat = 40
    var cropRect: CGRect = CGRect.zero
    var imageRequestID: Int32?
    var singleTapBlock: (() -> ())?
    var imageProgressUpdateBlock: ((_ progress: Double)->())?
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.cropRect = self.bounds
        addSubview(scrollView)
        scrollView.addSubview(imgContainerView)
        imgContainerView.addSubview(imageView)
        
        let tap1 = UITapGestureRecognizer.init(target: self, action: #selector(singleTap(gesture:)))
        self.addGestureRecognizer(tap1)
        
        let tap2 = UITapGestureRecognizer.init(target: self, action: #selector(doubleTap(gesture:)))
        tap2.numberOfTapsRequired = 2
        tap1.require(toFail: tap2)
        self.addGestureRecognizer(tap2)
        
//        addSubview(progressView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.scrollView.frame = CGRect.init(x: 10, y: 0, width: self.width - 20, height: self.height)
        let progressX = (self.width - progressH) * 0.5
        let progressY = (self.height - progressH) * 0.5
//        progressView.frame = CGRect.init(x: progressX, y: progressY, width: progressH, height: progressH)
        recoverSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK:- action
    
    @objc private func singleTap(gesture: UIGestureRecognizer) {
        if self.singleTapBlock != nil {
            self.singleTapBlock!()
        }
    }
    
    @objc private func doubleTap(gesture: UIGestureRecognizer) {
        if scrollView.zoomScale > 1 {
            scrollView.contentInset = UIEdgeInsets.zero
            scrollView.setZoomScale(1.0, animated: true)
        }else {
            let touchPoint = gesture.location(in: self.imageView)
            let newZoomScale = scrollView.maximumZoomScale
            let xSize = self.width / newZoomScale
            let ySize = self.height / newZoomScale
            scrollView.zoom(to: CGRect.init(x: touchPoint.x - xSize * 0.5, y: touchPoint.y - ySize * 0.5, width: xSize, height: ySize), animated: true)
        }
    }
    
    //MARK:- delegate
    
    func recoverSubviews() {
        scrollView.setZoomScale(1, animated: false)
        self.resizeSubviews()
    }
    
    private func resizeSubviews() {
        self.imgContainerView.frame = CGRect.init(origin: CGPoint.zero, size: CGSize.init(width: self.scrollView.width, height: 0))
        if let image = imageView.image {
            if image.size.height/image.size.width > self.height/self.scrollView.width {
                imgContainerView.height = floor(image.size.height / (image.size.width / self.scrollView.width))
            }else {
                var height = image.size.height / image.size.width * self.scrollView.width
                if height < 1 || height.isNaN {
                    height = self.height
                }
                height = floor(height)
                imgContainerView.height = height
                imgContainerView.centerY = self.height/2.0
            }
            if imgContainerView.height > self.height && self.imgContainerView.height - self.height <= 1 {
                imgContainerView.height = self.height
            }
        }
        let contentSizeH = max(imgContainerView.height, self.height)
        scrollView.contentSize = CGSize.init(width: scrollView.width, height: contentSizeH)
        scrollView.scrollRectToVisible(self.bounds, animated: false)
        scrollView.alwaysBounceVertical = self.imgContainerView.height > self.height
        imageView.frame = imgContainerView.bounds
        refreshScrollViewContentSize()
    }

    private func refreshScrollViewContentSize() {
        if self.allowCrop {
            let contentWidthAdd = self.scrollView.width - self.cropRect.maxX
            let contentHeightAdd = (min(imgContainerView.height, self.height) - self.cropRect.height) * 0.5
            
            let newSizeW = scrollView.contentSize.width + contentWidthAdd
            let newSizeH = max(scrollView.contentSize.height, self.height) + contentHeightAdd
            
            scrollView.contentSize = CGSize.init(width: newSizeW, height: newSizeH)
            scrollView.alwaysBounceVertical = true
            if contentHeightAdd > 0 || contentWidthAdd > 0 {
                scrollView.contentInset = UIEdgeInsets.init(top: contentHeightAdd, left: cropRect.origin.x, bottom: 0, right: 0)
            }else {
                scrollView.contentInset = UIEdgeInsets.zero
            }
        }
    }

    //MARK:- scrollview delegate
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imgContainerView
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.contentInset = UIEdgeInsets.zero
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.refreshImageContainerViewCenter()
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        self.refreshScrollViewContentSize()
    }
    
    private func refreshImageContainerViewCenter() {
        let offsetX = scrollView.width > scrollView.contentSize.width ? (scrollView.width - scrollView.contentSize.width) * 0.5 : 0.0
        let offsetY = scrollView.height > scrollView.contentSize.height ? (scrollView.height - scrollView.contentSize.height) * 0.5 : 0.0
        imgContainerView.center = CGPoint.init(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
    }

    //MARK:- setter & getter
    
    var model: DKAssetModel? {
        didSet {
            if let assetModel = model {
                scrollView.setZoomScale(1.0, animated: false)
                if assetModel.mediaType == .photoGif {
                    _ = IMGInstance.getPhotoAllParams(asset: assetModel.asset!, photoWidth: IMGInstance.configModel.screenWidth, networkAccessAllowed: false) { (photo, info, isDegraded) in
                        self.imageView.image = photo
                        self.resizeSubviews()
                        _ = IMGInstance.getOriginalPhotoData(asset: assetModel.asset!, complete: { (data, info, idDegraded) in
                            if !isDegraded {
                                self.imageView.image = UIImage.animatedGif(with: data!)
                                self.resizeSubviews()
                            }
                        })
                    }
                }else {
                    self.asset = assetModel.asset
                }
            }
        }
    }
    
    var asset: PHAsset? {
        willSet {
            if let _ = asset, let requestId = self.imageRequestID {
                PHImageManager.default().cancelImageRequest(requestId)
            }
            imageRequestID = IMGInstance.getPhotoNoWidth(asset: newValue!, networkAccessAllowed: true, progressHandler: { (progress, error, stop, info) in
//                self.progressView.isHidden = false
//                self.bringSubviewToFront(self.progressView)
                let startProgress = progress > 0.02 ? progress : 0.02
//                self.progressView.progress = startProgress
                if self.imageProgressUpdateBlock != nil && startProgress < 1 {
                    self.imageProgressUpdateBlock!(startProgress)
                }
                if startProgress >= 1 {
//                    self.progressView.isHidden = true
                    self.imageRequestID = 0
                }
            }, complete: { (photo, info, isDegraded) in
                self.imageView.image = photo
                self.resizeSubviews()
//                self.progressView.isHidden = true
                if self.imageProgressUpdateBlock != nil {
                    self.imageProgressUpdateBlock!(1)
                }
                if !isDegraded {
                    self.imageRequestID = 0
                }
            })
        }
    }
    
    var allowCrop: Bool = false {
        didSet {
            scrollView.maximumZoomScale = allowCrop ? 4.0 : 2.5
           
            
            var aspectRatio: CGFloat = 0
            if let ph = self.asset {
                aspectRatio = CGFloat(ph.pixelWidth) / CGFloat(ph.pixelHeight)
            }
            if aspectRatio > 1.5 {
                self.scrollView.maximumZoomScale *= aspectRatio / 1.5
            }
        }
    }
    
    private(set) lazy var scrollView: UIScrollView = {
        let view = UIScrollView.init()
        view.bouncesZoom = true
        view.maximumZoomScale = 2.5
        view.minimumZoomScale = 1.0
        view.isMultipleTouchEnabled = true
        view.delegate = self
        view.scrollsToTop = false
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = true
        view.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        view.delaysContentTouches = false
        view.canCancelContentTouches = true
        view.alwaysBounceVertical = false
        adjustsScrollViewInsets(scrollView: view)
        return view
    }()
    
    private lazy var imgContainerView: UIView = {
        let view = UIView.init()
        view.clipsToBounds = true
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    private(set) lazy var imageView: UIImageView = {
        let view = UIImageView.init()
        view.backgroundColor = UIColor.black
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        return view
    }()
    
//    private lazy var progressView: TZProgressView = {
//        let view = TZProgressView.init()
//        view.isHidden = true
//        return view
//    }()
    
}
