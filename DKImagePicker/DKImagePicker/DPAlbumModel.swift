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
    
    var name: String = "" ///< The album name
    var count: Int = 0  ///< Count of photos the album contain
    
    var models = [DPAssetModel]()
    var selectedModels = [DPAssetModel]() {
        didSet {
            if (self.models.count > 0) {
                self.checkSelectedModels()
            }
        }
    }
    var selectedCount: Int = 0
    
    var isCameraRoll = false
    var isAlbumVideo = false
    
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
