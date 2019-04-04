//
//  DKAlbumModel.swift
//  DatePlay
//
//  Created by DU on 2018/12/5.
//  Copyright © 2018 DU. All rights reserved.
//

import UIKit
import AVKit
import Photos

enum DKAlbumModelType: Int {
    case none
    case images
    case videos
    case all
}

class DKAlbumModel: NSObject {
    // 相册名字 The album name
    var name: String = ""
    // 相册中图片数量 Count of photos the album contain
    var count: Int = 0
    
    var models = [DKAssetModel]()
    //选中的数量
    var selectedCount: Int = 0
    //选中的model
    var selectedModels = [DKAssetModel]() {
        didSet {
            if (self.models.count > 0) {
                self.checkSelectedModels()
            }
        }
    }
    //是否是照片流相册
    var isCameraRoll = false
    //是否是视频相册
    var isAlbumVideo = false
    //相册类型
    var albumType: DKAlbumModelType = .all
    
    var result: PHFetchResult<PHAsset>? { ///< PHFetchResult<PHAsset>
        didSet {
            if result != nil {
                let allowPickingImage = DKImageManager.shared.configModel.allowPickingImage
                let allowPickingVideo = DKImageManager.shared.configModel.allowPickingVideo
                
                IMGInstance.getAssets(fetchResult: result!, allowPickingVideo: allowPickingVideo, allowPickingImage: allowPickingImage) { (models) in
                    self.models = models
                    if self.selectedModels.count > 0 {
                        self.checkSelectedModels()
                    }
                }
            }
        }
    }
    
    //计算当前相册中的被选中的数量
    private func checkSelectedModels() {
        self.selectedCount = 0
        var selectedAssets = [PHAsset]()
        for model in self.selectedModels {
            selectedAssets.append(model.asset!)
        }
        for model in self.models {
            if model.asset != nil && selectedAssets.contains(model.asset!) {
                self.selectedCount += 1
            }
        }
    }
}
