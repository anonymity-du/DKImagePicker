//
//  DPImageConfigModel.swift
//  DatePlay
//
//  Created by 杜奎 on 2018/12/5.
//  Copyright © 2018 杜奎. All rights reserved.
//

import UIKit
import AVKit
import Photos

class DPImageConfigModel: NSObject {
    
    weak var selectedAlbumModel: DPAlbumModel?
    
    var assetGridThumbnailSize: CGSize = CGSize.zero
    var screenWidth: CGFloat = 0
    var screenHeight: CGFloat = 0
    var screenScale: CGFloat = 0
    
    var diyTip: String = ""

    var shouldFixOrientation = true
    var columnNumber: Int = 4 {
        didSet {
            if columnNumber <= 2 {
                columnNumber = 2
            }else if (columnNumber >= 6) {
                columnNumber = 6
            }else {
                let margin: CGFloat = 4
                let contentWidth = (self.screenWidth - 2 * margin - 4)
                let itemWidth = contentWidth/CGFloat(columnNumber) - margin
                self.assetGridThumbnailSize = CGSize.init(width: itemWidth * self.screenScale, height: itemWidth * self.screenScale)
            }
        }
    }
    var maxImagesCount: Int = 9 {
        didSet {
            if (maxImagesCount > 1) {
                self.showSelectBtn = true
                self.allowCrop = false
            }
        }
    }
    var minImagesCount: Int = 1
    var videoMinDuration: CGFloat = 0
    var videoMaxDuration: TimeInterval = 120
    
    /// 对照片排序，按修改时间升序，默认是YES。如果设置为NO,最新的照片会显示在最前面，内部的拍照按钮会排在第一个
    var sortAscendingByModificationDate = false
    /// 导出图片的宽度，默认828像素宽
    var photoWidth: CGFloat = 828
    /// 默认600像素宽
    var photoPreviewMaxWidth: CGFloat = 600
    /// 超时时间，默认为15秒，当取图片时间超过15秒还没有取成功时，会自动dismiss HUD；
    var timeout: Int = 15
    
    
    /// 默认为NO,原图按钮将隐藏，用户不能选择发送原图
    var allowPickingOriginalPhoto = false
    /// 默认为YES，如果设置为NO,用户将不能选择视频
    var allowPickingVideo = true
    /// 默认为NO，为YES时可以多选视频/gif图片，和照片共享最大可选张数maxImagesCount的限制
    var allowPickingMultipleVideo = false
    /// 默认为NO，如果设置为YES,用户可以选择gif图片
    var allowPickingGif = false
    /// 默认为YES，如果设置为NO,用户将不能选择发送图片
    var allowPickingImage = true
    /// 默认为YES，如果设置为NO,拍照按钮将隐藏,用户将不能选择照片
    var allowTakePicture = true
    /// 默认为YES，如果设置为NO,预览按钮将隐藏,用户将不能去预览照片
    var allowPreview = true
    /// 默认为YES，如果设置为NO, 选择器将不会自己dismiss
    var autoDismiss = true

    var allowChangeDirectory = true //是否允许点击头部修改相册
    var showTakePhotoBtn = true //是否显示拍摄按钮
    var needPreviewTempSelected = false //在preview中临时存放，点击返回，会回归之前的选择
    
    /// 用户选中过的图片数组,目前只用拍照后的asset来填装，然后使用selectedModels
    var selectedAssets = [PHAsset]() {
        didSet {
            self.selectedModels = [DPAssetModel]()
            for asset in selectedAssets {
                let model = DPAssetModel.createModel(with: asset, type: IMGInstance.getAssetType(asset: asset), timeLength: IMGInstance.getNewTime(from: Int(asset.duration)))
                model.isSelected = true
                self.selectedModels.append(model)
            }
        }
    }
    var selectedModels = [DPAssetModel]()

    /// 最小可选中的图片宽度，默认是0，小于这个宽度的图片不可选中
    var minPhotoWidthSelectable: CGFloat = 0
    var minPhotoHeightSelectable: CGFloat = 0
    /// 隐藏不可以选中的图片，默认是NO，不推荐将其设置为YES
    var hideWhenCanNotSelect = false
    /// 单选模式,maxImagesCount为1时才生效
    ///< 在单选模式下，照片列表页中，显示选择按钮,默认为NO
    var showSelectBtn = false {
        didSet {
            // 多选模式下，不允许让showSelectBtn为NO
            if (!showSelectBtn && self.maxImagesCount > 1) {
                self.showSelectBtn = true
            }
        }
    }
    
    ///< 允许裁剪,默认为YES，showSelectBtn为NO才生效
    var allowCrop = false
    
    //裁剪中横屏和竖屏处理是在转屏时候处理的，由于现在是固定竖屏，所以删掉了那部分代码，需要则添加viewcontroller的转屏回调方法
    ///< 裁剪框的尺寸
    var cropRect: CGRect = CGRect.zero
    ///< 裁剪框的尺寸(竖屏)
    var cropRectPortrait = CGRect.zero
    ///< 裁剪框的尺寸(横屏)
    var cropRectLandscape = CGRect.zero
    ///< 需要圆形裁剪框
    var needCircleCrop = false
    ///< 圆形裁剪框半径大小
    var circleCropRadius: CGFloat = 0
    
    ///< 自定义裁剪框的其他属性
    var cropViewSettingBlock: ((_ cropView: UIView)->())?
    ///default no
    var defaultShowVideo = false

    //图片预览和裁剪的按钮回调
    var previewVCBackBlock: (()->())?
    var previewVCCompleteBlock: (()->())?
    var systemImagePickerVCCompleteBlock: ((_ model: DPAssetModel)->())?
    override init() {
        super.init()
        
        self.refreshConfigInfo()
    }
    

    func refreshConfigInfo() {
        let screenSize = UIScreen.main.bounds.size
        let height = screenSize.height
        let width = screenSize.width
      
        // 测试发现，如果scale在plus真机上取到3.0，内存会增大特别多。故这里写死成2.0
        self.screenWidth = width
        self.screenHeight = height
        self.screenScale = 2.0
        if width > 700 {
            self.screenScale = 1.5
        }
        
        self.cropRect = CGRect.init(x: 0, y: (height - width) * 0.5, width: width, height: width)
        self.cropRectPortrait = self.cropRect
        self.cropRectLandscape = CGRect.init(x: (width - height) * 0.5, y: 0, width: height, height: width)
        self.circleCropRadius = width * 0.5
        
        self.columnNumber = 4
    }
}
