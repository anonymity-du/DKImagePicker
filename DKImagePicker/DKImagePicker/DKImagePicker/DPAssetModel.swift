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
    var asset: PHAsset?
    var mediaType: DPAssetModelMediaType = DPAssetModelMediaType.photo
    var thumbnail: UIImage?
    var data: Data?
    
    var isSelected = false
    var isSelectOriginalPhoto = false
    var needOscillatoryAnimation = false
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
