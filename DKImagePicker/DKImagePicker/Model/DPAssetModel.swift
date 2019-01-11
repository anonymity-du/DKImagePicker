//
//  DPAssetModel.swift
//  DatePlay
//
//  Created by 杜奎 on 2018/12/5.
//  Copyright © 2018 杜奎. All rights reserved.
//

import UIKit
import AVKit
import Photos

enum DPAssetModelMediaType: UInt {
    case photo = 0
    case livePhoto
    case photoGif
    case video
    case audio
}

class DPAssetModel: NSObject {
    //当前资源asset
    var asset: PHAsset?
    //资源类型
    var mediaType: DPAssetModelMediaType = DPAssetModelMediaType.photo
    //资源缩略图
    var thumbnail: UIImage?
    //资源data
    var data: Data?
    //是否被选中
    var isSelected = false
    //是否选中原图
    var isSelectOriginalPhoto = false
    //是否需要选中动画
    var needOscillatoryAnimation = false
    //如果是video，则表示时间长度（已处理为xx:xx）
    var timeLength: String?
    
    override init() {
        super.init()
    }

    /// Init a photo dataModel With a asset
    /// 用一个PHAsset/ALAsset实例，初始化一个照片模型
    class func createModel(with asset: PHAsset, type: DPAssetModelMediaType, timeLength: String) -> DPAssetModel {
        let model = DPAssetModel()
        model.asset = asset;
        model.isSelected = false
        model.mediaType = type
        model.timeLength = timeLength
        return model
    }
}
