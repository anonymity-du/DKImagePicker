//
//  DPAlbumModel.swift
//  DatePlay
//
//  Created by 杜奎 on 2018/12/5.
//  Copyright © 2018 杜奎. All rights reserved.
//

import UIKit
import AVKit
import Photos

enum DPAlbumModelType: Int {
    case none
    case images
    case videos
    case all
}

class DPAlbumModel: NSObject {
    // 相册名字 The album name
    var name: String = ""
    // 相册中图片数量 Count of photos the album contain
    var count: Int = 0
    
    var models = [DPAssetModel]()
    //选中的数量
    var selectedCount: Int = 0
    //选中的model
    var selectedModels = [DPAssetModel]() {
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
    var albumType: DPAlbumModelType = .all
    
    var result: PHFetchResult<PHAsset>? { ///< PHFetchResult<PHAsset>
        didSet {
            if result != nil {
                let allowPickingImage = DPImageManager.shared.configModel.allowPickingImage
                let allowPickingVideo = DPImageManager.shared.configModel.allowPickingVideo
                
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
