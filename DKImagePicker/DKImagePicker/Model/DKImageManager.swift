//
//  DKImageManager.swift
//  DatePlay
//
//  Created by DU on 2018/12/5.
//  Copyright © 2018 DU. All rights reserved.
//

import UIKit
import AssetsLibrary
import MobileCoreServices
import AVKit
import Photos

let IMGInstance = DKImageManager.shared

@objc protocol DKImagePickerDelegate: NSObjectProtocol {
    //// 这个照片选择器会自己dismiss，当选择器dismiss的时候，会执行下面的handle
    //// 你也可以设置autoDismiss属性为NO，选择器就不会自己dismis了
    //// 你可以通过一个asset获得原图，通过这个方法：getOriginalPhotoWithAsset:completion:
    //// photos数组里的UIImage对象，默认是828像素宽，你可以通过设置photoWidth属性的值来改变它
    @objc optional func imagePickerDidFinishPicking(photos: [UIImage], infos: [Any], sourceAssets: [DKAssetModel])
    //正在改变所选择的
    @objc optional func imagePickerDidChangePicking(models: [DKAssetModel])
    //通过拍照获得新的assetModel
    @objc optional func imagePickerDidAddNewAsset(photo: UIImage, model: DKAssetModel)
    //取消选择
    @objc optional func imagePickerDidCancel()
    
    // 如果用户选择了一个视频，下面的handle会被执行
    @objc optional func imagePickerDidFinishPickingVideo(sourceAssets: PHAsset)
    // 如果用户选择了一个gif图片，下面的handle会被执行
    @objc optional func imagePickerDidFinishPicking(GIFImg: UIImage, sourceAssets: PHAsset)
    // 决定相册显示与否 albumName:相册名字 result:相册原始数据
    @objc optional func isAlbumCanSelect(albumName: String, result: PHFetchResult<PHAsset>) -> Bool
    // 决定照片显示与否
    @objc optional func isAssetCanSelect(asset: PHAsset) -> Bool
}


class DKImageManager: NSObject {
    
    static let shared = DKImageManager()
    
    weak var pickerDelegate: DKImagePickerDelegate?
    weak var pickerNav: UINavigationController?
    var systemImagePicker: UIImagePickerController?
    private override init() {
        super.init()
        
        
    }
    
    //MARK: - 配置相关model
    
    func configModel(maxImagesCount: Int, columnNumber: Int? = nil) {
        self.refreshManagerConfig()
        self.configModel.maxImagesCount = maxImagesCount > 0 ? maxImagesCount : 9
        self.configModel.allowPickingVideo = true
        self.configModel.allowPickingImage = true
        if let number = columnNumber, number > 1 {
            self.configModel.columnNumber = number
        }else {
            self.configModel.columnNumber = 4
        }
    }

    func pushPhotoPickerVC(delegate: DKImagePickerViewControllerDelegate?)  {
        _ = DKSystemPermission.photoAblumHasAuthority { (success) in
            if success  {
                let pickerVC = DKImagePickerViewController()
                pickerVC.delegate = delegate
                var nav: UINavigationController?
                if let pickerCurNav = self.pickerNav  {
                    nav = pickerCurNav
                } else {
                    nav = UINavigationController.init(rootViewController: pickerVC)
                }
                self.configModel.shouldFixOrientation = false
                if self.pickerNav != nav {
                    self.pickerNav = nav
                }

                if let presentingVC = kTopViewController() {
                    presentingVC.present(nav!, animated: true, completion: nil)
                }
            }
        }
    }
    
    func pushImagePickerController(isTakePhoto: Bool) {
        let sourceType = UIImagePickerController.SourceType.camera
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            var mediaTypes: [String] = []
            systemImagePicker = UIImagePickerController()
            if isTakePhoto {
                mediaTypes.append(kUTTypeImage as String)
                systemImagePicker?.mediaTypes = mediaTypes
                systemImagePicker?.sourceType = UIImagePickerController.SourceType.camera
                systemImagePicker?.cameraDevice = .rear
                systemImagePicker?.cameraCaptureMode = .photo
            }else {
                mediaTypes.append(kUTTypeMovie as String)
                systemImagePicker?.mediaTypes = mediaTypes
                systemImagePicker?.videoMaximumDuration = IMGInstance.configModel.videoMaxDuration
                systemImagePicker?.sourceType = UIImagePickerController.SourceType.camera
                systemImagePicker?.videoQuality = .typeHigh
                systemImagePicker?.cameraDevice = .rear
                systemImagePicker?.cameraCaptureMode = .video
            }

            systemImagePicker?.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
            systemImagePicker?.delegate = self
            if systemImagePicker != nil {
                kTopViewController()?.navigationController?
                    .present(systemImagePicker!, animated: true, completion: nil)
            }
        }
    }
    //刷新配置
    func refreshManagerConfig() {
        let configModel = DKImageConfigModel.init()
        self.configModel = configModel
        self.pickerDelegate = nil
        self.pickerNav = nil
    }
    
    //计算所选model的index
    func calculateCellSelectedIndex(_ model: DKAssetModel) -> Int {
        var index = 0
        for i in 0..<self.configModel.selectedModels.count {
            let selModel = self.configModel.selectedModels[i]
            if model.asset?.localIdentifier == selModel.asset?.localIdentifier {
                index = i + 1
                break
            }
        }
        return index
    }
    //增加model
    func addAssetModel(with model: DKAssetModel) {
        self.configModel.selectedModels.append(model)
        self.configModel.selectedAssets.append(model.asset!)
        if let delegate = self.pickerDelegate, delegate.responds(to: #selector(DKImagePickerDelegate.imagePickerDidChangePicking(models:))) {
            self.pickerDelegate?.imagePickerDidChangePicking!(models: self.configModel.selectedModels)
        }
    }
    //移除所选的model
    func removeAssetModel(with model: DKAssetModel) {
        for (index, itemModel) in self.configModel.selectedModels.enumerated() {
            if model.asset?.localIdentifier == itemModel.asset?.localIdentifier {
                self.configModel.selectedModels.remove(at: index)
                self.configModel.selectedAssets.remove(at: index)
                break
            }
        }
        if let delegate = self.pickerDelegate, delegate.responds(to: #selector(DKImagePickerDelegate.imagePickerDidChangePicking(models:))) {
            self.pickerDelegate?.imagePickerDidChangePicking!(models: self.configModel.selectedModels)
        }
    }
    
    func removeMuiltyAssetModel(with models: [DKAssetModel]) {
        for (index, itemModel) in self.configModel.selectedModels.enumerated().reversed() {
            for model in models {
                if model.asset?.localIdentifier == itemModel.asset?.localIdentifier {
                    self.configModel.selectedModels.remove(at: index)
                    self.configModel.selectedAssets.remove(at: index)
                }
            }
        }

        if let delegate = self.pickerDelegate, delegate.responds(to: #selector(DKImagePickerDelegate.imagePickerDidChangePicking(models:))) {
            self.pickerDelegate?.imagePickerDidChangePicking!(models: self.configModel.selectedModels)
        }
    }
    
    //完成选择
    func didFinishPicking(with completeBlock: (()->())? = nil) {
        DKLoadingView.show()
        var photos = [Any]()
        var assetModels = [Any]()
        var infos = [Any]()
        for _ in IMGInstance.configModel.selectedModels {
            photos.append(1)
            assetModels.append(1)
            infos.append(1)
        }

        var havenotShowAlert = true
        IMGInstance.configModel.shouldFixOrientation = true
        for (index,itemModel) in IMGInstance.configModel.selectedModels.enumerated() {
            _ = IMGInstance.getPhotoNoWidth(asset: itemModel.asset!, networkAccessAllowed: true, progressHandler: { (progress, error, stop, info) in
                // 如果图片正在从iCloud同步中,提醒用户
                if progress < 1 && havenotShowAlert {
                    havenotShowAlert = false
                    kFrontWindow().makeToast("正在从iCloud同步第\(index)张")
                    return
                }
                if progress >= 1 {
                    havenotShowAlert = true
                }
            }, complete: { (photo, info, isDegraded) in
                if isDegraded {
                    return
                }
                if photo != nil {
                    photos[index] = photo!
                }
                if info != nil {
                    infos[index] = info!
                }
                assetModels[index] = itemModel
                for item in photos {
                    if item is Int {
                        return
                    }
                }
                DKLoadingView.hide()
                if let delegate = self.pickerDelegate, delegate.responds(to: #selector(DKImagePickerDelegate.imagePickerDidFinishPicking(photos:infos:sourceAssets:))) {
                    delegate.imagePickerDidFinishPicking!(photos: photos as! [UIImage], infos: infos, sourceAssets: assetModels as! [DKAssetModel])
                }
                if completeBlock != nil {
                    completeBlock!()
                }
            })
        }
    }
    
    private func fetchOption(allowPickingVideo: Bool, allowPickingImage: Bool) -> PHFetchOptions {
        let option = PHFetchOptions.init()
        if !allowPickingVideo {
            option.predicate = NSPredicate.init(format: "mediaType == \(PHAssetMediaType.image.rawValue)")
        }
        if !allowPickingImage {
            option.predicate = NSPredicate.init(format: "mediaType == \(PHAssetMediaType.video.rawValue) AND duration > \(self.configModel.videoMinDuration)")
        }
        
        if allowPickingImage && allowPickingVideo {
            option.predicate = NSPredicate.init(format: "mediaType == \(PHAssetMediaType.video.rawValue) AND duration > \(self.configModel.videoMinDuration) || mediaType == \(PHAssetMediaType.image.rawValue)")
        }
        
        if !self.configModel.sortAscendingByModificationDate {
            let sort = NSSortDescriptor.init(key: "creationDate", ascending: self.configModel.sortAscendingByModificationDate)
            option.sortDescriptors = [sort]
        }
        return option
    }
    
    //MARK: - 获得相册/相册数组
    //获取相机流（相机胶卷）
    func getCameraRollAlbum(allowPickingVideo: Bool, allowPickingImage: Bool, complete: ((_ model: DKAlbumModel)->())?) {
        let option = self.fetchOption(allowPickingVideo: allowPickingVideo, allowPickingImage: allowPickingImage)
        let smartAlbums: PHFetchResult<PHAssetCollection> = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum, subtype: PHAssetCollectionSubtype.albumRegular, options: nil)
        let count = smartAlbums.count
        if count < 1 {
            return
        }
        for index in 0..<count {
            let collection = smartAlbums.object(at: index)
            if self.isCameraRollAlbum(collection: collection) {
                let fetchResult = PHAsset.fetchAssets(in: collection, options: option)
                let model = self.createAlbumModel(result: fetchResult, name: collection.localizedTitle ?? "", isCameraRoll: true)
                if complete != nil {
                    complete!(model)
                }
                break;
            }
        }
        
    }
    
    //获取大部分相册
    func getAllAlbums(allowPickingVideo: Bool, allowPickingImage: Bool, complete: ((_ models: [DKAlbumModel])->())?) {
        var albumArr = [DKAlbumModel]()
        let option = self.fetchOption(allowPickingVideo: allowPickingVideo, allowPickingImage: allowPickingImage)

        // 我的照片流 1.6.10重新加入..
        let myPhotoStreamAlbum = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype: PHAssetCollectionSubtype.albumMyPhotoStream, options: nil) as! PHFetchResult<PHCollection>
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum, subtype: PHAssetCollectionSubtype.albumRegular, options: nil) as! PHFetchResult<PHCollection>

        let topLevelUserCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)
        let syncedAlbums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype: PHAssetCollectionSubtype.albumSyncedAlbum, options: nil) as! PHFetchResult<PHCollection>
        let sharedAlbums = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.album, subtype: PHAssetCollectionSubtype.albumCloudShared, options: nil) as! PHFetchResult<PHCollection>

        let allAlbums:[PHFetchResult<PHCollection>] = [myPhotoStreamAlbum , smartAlbums, topLevelUserCollections, syncedAlbums, sharedAlbums]
        for fetchResult in allAlbums {
            let count = fetchResult.count
            if count < 1 {
                continue
            }
            for index in 0..<count {
                let collection = fetchResult.object(at: index)
                if !(collection is PHAssetCollection) {
                    continue
                }
                let result = PHAsset.fetchAssets(in: collection as! PHAssetCollection, options: option)
                if result.count < 1 {
                    continue
                }

                if let delegate = self.pickerDelegate, delegate.responds(to: #selector(DKImagePickerDelegate.isAlbumCanSelect(albumName:result:))) {
                    if delegate.isAlbumCanSelect!(albumName: collection.localizedTitle ?? "", result: result) == false {
                        continue
                    }
                }
                
                if let title = collection.localizedTitle {
                    if title.contains("Hidden") || title.contains("已隐藏") {
                        continue
                    }

                    if title.contains("Deleted") || title.contains("最近删除") {
                        continue
                    }
                }


                if self.isCameraRollAlbum(collection: collection as! PHAssetCollection) {
                    let model = self.createAlbumModel(result: result, name: collection.localizedTitle ?? "", isCameraRoll: true)
                    albumArr.insert(model, at: 0)
                }else {
                    let model = self.createAlbumModel(result: result, name: collection.localizedTitle ?? "", isCameraRoll: false)
                    albumArr.append(model)
                }
            }
        }
        if complete != nil && albumArr.count > 0 {
            complete!(albumArr)
        }
    }

    // 获取 视频相册
    func getVideoAlbum(allowPickingVideo: Bool, allowPickingImage: Bool, complete: ((_ model: DKAlbumModel)->())?) {
    
        let option = self.fetchOption(allowPickingVideo: allowPickingVideo, allowPickingImage: allowPickingImage)
        let smartAlbums: PHFetchResult<PHAssetCollection> = PHAssetCollection.fetchAssetCollections(with: PHAssetCollectionType.smartAlbum, subtype: PHAssetCollectionSubtype.albumRegular, options: nil)
        let count = smartAlbums.count
        if count < 1 {
            return
        }
        for index in 0..<count {
            let collection = smartAlbums.object(at: index)
            if self.isVideoAlbum(collection: collection) {
                let fetchResult = PHAsset.fetchAssets(in: collection, options: option)
                let model = self.createAlbumModel(result: fetchResult, name: collection.localizedTitle ?? "", isCameraRoll: false)
                model.isAlbumVideo = true
                if complete != nil {
                    complete!(model)
                }
                break
            }
        }
    }
    
    //MARK: - 获得相册中Asset
    //获取相册中的所有asset
    func getAssets(fetchResult: PHFetchResult<PHAsset>, allowPickingVideo: Bool, allowPickingImage: Bool, complete: ((_ models: [DKAssetModel])->())?) {
        var photoArr = [DKAssetModel]()
        fetchResult.enumerateObjects { (obj, idx, stop) in
            let model = self.createAssetModel(asset: obj, allowPickingVideo: allowPickingVideo, allowPickingImage: allowPickingImage)
            if model != nil {
                photoArr.append(model!)
            }
        }
        if complete != nil {
            complete!(photoArr)
        }
    }
    //获取单个asset
    func getSingleAsset(fetchResult: PHFetchResult<PHAsset>, index: Int, allowPickingVideo: Bool, allowPickingImage: Bool, complete: ((_ model: DKAssetModel?)->())?) {
        if index < fetchResult.count {
            let asset = fetchResult.object(at: index)
            let model = self.createAssetModel(asset: asset, allowPickingVideo: allowPickingVideo, allowPickingImage: allowPickingImage)
            if complete != nil {
                complete!(model)
            }
        }else {
            if complete != nil {
                complete!(nil)
            }
        }
    }
    
    //获取单个asset
    func getPosterAsset(albumModel: DKAlbumModel, complete: ((_ asset: DKAssetModel?)->())?) {
        var asset = albumModel.result?.lastObject
        if !self.configModel.sortAscendingByModificationDate {
            asset = albumModel.result?.firstObject
        }
        if asset != nil {
            let model = self.createAssetModel(asset: asset!, allowPickingVideo: true, allowPickingImage: true)
            if complete != nil {
                complete!(model)
            }
        }else {
            if complete != nil {
                complete!(nil)
            }
        }
    }

    /// 获取asset的资源类型
    func getAssetType(asset: PHAsset) -> DKAssetModelMediaType {
        var type = DKAssetModelMediaType.photo;
        if asset.mediaType == PHAssetMediaType.video {
            type = .video
        } else if asset.mediaType == PHAssetMediaType.audio {
            type = .audio
        } else if asset.mediaType == PHAssetMediaType.image {
            //            if (iOS9_1VerLater) {
            //                 if (asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) type = TZAssetModelMediaTypeLivePhoto;
            //            }
            // Gif
            if let value = asset.value(forKey: "filename") as? String, value.hasSuffix("GIF") {
                type = .photoGif
            }
        }
        return type
    }
    
    //获取视频时间
    func getNewTime(from duration:Int) -> String {
        var newTime = ""
        if (duration < 10) {
            newTime = "0:0\(duration)"
        } else if (duration < 60) {
            newTime = "0:\(duration)"
        } else {
            let min = duration / 60;
            let sec = duration - (min * 60)
            if (sec < 10) {
                newTime = "\(min):0\(sec)"
            } else {
                newTime = "\(min):\(sec)"
            }
        }
        return newTime
    }
    
    //MARK: - 获得照片
    //获取封面图
    func getPosterImage(albumModel: DKAlbumModel, complete:((_ postImage: UIImage)->())?) {
        self.getPosterAsset(albumModel: albumModel) { (model) in
            if let asset = model?.asset {
                _ = IMGInstance.getPhotoNoProgress(asset: asset, photoWidth: 80, complete: { (photo, info, isDegraded) in
                    if complete != nil && photo != nil {
                        complete!(photo!)
                    }
                })
            }
        }
    }

    //通过asset获取图片
    func getPhotoNoWidthAndProgress(asset: PHAsset, complete:((_ photo: UIImage?,_ info: [AnyHashable: Any]?,_ isDegraded: Bool)->())?) -> PHImageRequestID {
        var fullScreenWidth = self.configModel.screenWidth
        if fullScreenWidth > self.configModel.photoPreviewMaxWidth {
            fullScreenWidth = self.configModel.photoPreviewMaxWidth
        }
        return self.getPhotoNoProgress(asset: asset, photoWidth: fullScreenWidth, complete: complete)
    }
    
    func getPhotoNoProgress(asset: PHAsset, photoWidth: CGFloat, complete:((_ photo: UIImage?,_ info: [AnyHashable: Any]?,_ isDegraded: Bool)->())?) -> PHImageRequestID {
        return self.getPhotoAllParams(asset: asset, photoWidth: photoWidth, networkAccessAllowed: true, progressHandler: nil, complete: complete)
    }
    
    func getPhotoNoWidth(asset: PHAsset, networkAccessAllowed: Bool, progressHandler: ((_ progress: Double,_ error: Error?,_ stop: UnsafeMutablePointer<ObjCBool>,_ info:[AnyHashable: Any]?)->())? = nil, complete: ((_ photo: UIImage?,_ info: [AnyHashable: Any]?,_ isDegraded: Bool)->())?) -> PHImageRequestID {
        var fullScreenWidth = self.configModel.screenWidth
        if fullScreenWidth > self.configModel.photoPreviewMaxWidth {
            fullScreenWidth = self.configModel.photoPreviewMaxWidth
        }
        return self.getPhotoAllParams(asset: asset, photoWidth: fullScreenWidth, networkAccessAllowed: networkAccessAllowed, progressHandler: progressHandler, complete: complete)
    }
    
    /// 获取图片 （此方法还有待测试）
    ///
    /// - Parameters:
    ///   - networkAccessAllowed: 是否从icloud下载
    ///   - progressHandler: 进度
    ///   - complete: 完成回调
    func getPhotoAllParams(asset: PHAsset, photoWidth: CGFloat, networkAccessAllowed: Bool, progressHandler: ((_ progress: Double,_ error: Error?,_ stop: UnsafeMutablePointer<ObjCBool>,_ info:[AnyHashable: Any]?)->())? = nil, complete: ((_ photo: UIImage?,_ info: [AnyHashable: Any]?,_ isDegraded: Bool)->())?) -> PHImageRequestID {
        
        var imageSize = CGSize.zero
        if photoWidth < self.configModel.screenWidth && photoWidth < self.configModel.photoPreviewMaxWidth {
            imageSize = self.configModel.thumbnailSize
        }else {
            let aspectRatio = CGFloat(asset.pixelWidth)/CGFloat(asset.pixelHeight)
            var pixelWidth = photoWidth * self.configModel.screenScale * 1.5
            //超宽图片
            if aspectRatio > 1.8 {
                pixelWidth = pixelWidth * aspectRatio
            }
            //超高图片
            if aspectRatio < 0.2 {
                pixelWidth = pixelWidth * 0.5
            }
            let pixelHeight = pixelWidth / aspectRatio
            imageSize = CGSize.init(width: pixelWidth, height: pixelHeight)
        }

        let option = PHImageRequestOptions.init()
        option.resizeMode = PHImageRequestOptionsResizeMode.fast
        let imageRequestID = PHImageManager.default().requestImage(for: asset, targetSize: imageSize, contentMode: PHImageContentMode.aspectFill, options: option) { (result, info) in
            var isCancel = false
            var hasError = false
            var isDegraded = true
            var downloadFinished = false
            var isDownLoadFromICloud = false
            if let dict = info {
                //是否取消
                if let cancel = dict[PHImageCancelledKey] as? Bool {
                    isCancel = cancel
                }
                //是否出错
                if let _ = dict[PHImageErrorKey] {
                    hasError = true
                }
                //当前图片是否是低质量的
                if let degraded = dict[PHImageResultIsDegradedKey] as? Bool {
                    isDegraded = degraded
                }
                //是否从iCloud下载
                if let icloud = dict[PHImageResultIsInCloudKey] as? Bool {
                    isDownLoadFromICloud = icloud
                }
                downloadFinished = (!isCancel && !hasError)
            }

            if result != nil {
                if downloadFinished  {
                    let image = result!.normalizedImage()
                    if complete != nil {
                        complete!(image, info, isDegraded)
                    }
                }else {
                    if complete != nil {
                        complete!(result, info, isDegraded)
                    }
                }
            }else if isDownLoadFromICloud && networkAccessAllowed {
                let options = PHImageRequestOptions.init()
                options.progressHandler = { progress, error, stop, info in
                    DispatchQueue.main.async {
                        if progressHandler != nil {
                            progressHandler!(progress, error, stop, info)
                        }
                    }
                }
                options.isNetworkAccessAllowed = true
                options.resizeMode = PHImageRequestOptionsResizeMode.fast
                PHImageManager.default().requestImageData(for: asset, options: options, resultHandler: { (imageData, dataUTI, orientation, info) in
                    if let data = imageData {
                        var resultImage = UIImage.init(data: data, scale: 0.1)
                        if let newResultImaga = resultImage {
                            let transImage = newResultImaga.normalizedImage()
                            resultImage = transImage.thumbnail(with: imageSize)
                        }
                        if complete != nil {
                            complete!(resultImage, info, false)
                        }
                    }else {
                        if complete != nil {
                            complete!(nil, info, false)
                        }
                    }
                })
            }else {
                if complete != nil {
                    complete!(result, info, isDegraded)
                }
            }
        }
        return imageRequestID
    }
    
    /// Get full Image 获取原图
    /// 如下两个方法completion一般会调多次，一般会先返回缩略图，再返回原图(详见方法内部使用的系统API的说明)，如果info[PHImageResultIsDegradedKey] 为 YES，则表明当前返回的是缩略图，否则是原图。
    func getOriginalPhoto(asset: PHAsset, complete: ((_ image: UIImage?,_ info: [AnyHashable: Any]?,_ isDegraded: Bool)->())?) {
        let option = PHImageRequestOptions.init()
        option.isNetworkAccessAllowed = true
        option.resizeMode = PHImageRequestOptionsResizeMode.fast
        PHImageManager.default().requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: PHImageContentMode.aspectFit, options: option) { (result, info) in
            var isCancel = false
            var hasError = false
            var isDegraded = true
            var downloadFinished = false
            if let dict = info {
                //是否取消
                if let cancel = dict[PHImageCancelledKey] as? Bool {
                    isCancel = cancel
                }
                //是否出错
                if let _ = dict[PHImageErrorKey] {
                    hasError = true
                }
                if let degraded = dict[PHImageResultIsDegradedKey] as? Bool {
                    isDegraded = degraded
                }
                downloadFinished = (!isCancel && !hasError)
            }
            if downloadFinished && result != nil {
                let newResult = result!.normalizedImage()
                if complete != nil  {
                    complete!(newResult, info, isDegraded)
                }
            }else {
                if complete != nil  {
                    complete!(nil, info, isDegraded)
                }
            }
        }
    }
    
    // 该方法中，completion只会走一次
    func getOriginalPhotoData(asset: PHAsset, progressHandler: ((_ progress: Double,_ error: Error?,_ stop: UnsafeMutablePointer<ObjCBool>,_ info:[AnyHashable: Any]?)->())? = nil, complete: ((_ data: Data?,_ info: [AnyHashable: Any]?,_ isDegraded: Bool)->())?) -> PHImageRequestID {
        let option = PHImageRequestOptions.init()
        option.isNetworkAccessAllowed = true
        option.resizeMode = PHImageRequestOptionsResizeMode.fast
        option.progressHandler = { progress, error, stop, info in
            DispatchQueue.main.async {
                if progressHandler != nil {
                    progressHandler!(progress, error, stop, info)
                }
            }
        }
        
        return PHImageManager.default().requestImageData(for: asset, options: option) { (imageData, dataUTI, orientation, info) in
            var isCancel = false
            var hasError = false
            var downloadFinished = false
            if let dict = info {
                //是否取消
                if let cancel = dict[PHImageCancelledKey] as? Bool {
                    isCancel = cancel
                }
                //是否出错
                if let _ = dict[PHImageErrorKey] {
                    hasError = true
                }
                downloadFinished = (!isCancel && !hasError)
            }
            if downloadFinished && imageData != nil && complete != nil {
                complete!(imageData, info, false)
            }
        }
    }

    //MARK: - 保存照片
    
    func savePhoto(image: UIImage, complete: ((_ asset: PHAsset?,_ error: Error?)->())?) {
        var localIdentifier = ""
        if #available(iOS 9.0, *) {
            PHPhotoLibrary.shared().performChanges({
                let options = PHAssetResourceCreationOptions.init()
                options.shouldMoveFile = true
                let request = PHAssetChangeRequest.creationRequestForAsset(from: image)
                localIdentifier = request.placeholderForCreatedAsset?.localIdentifier ?? ""
//                if DPLocationManager.shared.curLocation != nil {
//                    request.location = DPLocationManager.shared.curLocation!
//                }
                request.creationDate = Date()
            }) { (success, error) in
                DispatchQueue.main.async {
                    if success && complete != nil {
                        print("图片保存成功")
                        let asset = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).firstObject
                        complete!(asset, nil)
                    }else {
                        if complete != nil {
                            complete!(nil, error)
                        }
                    }
                }
            }
        }else {
            let orientation : ALAssetOrientation = ALAssetOrientation(rawValue: image.imageOrientation.rawValue)!
            
            self.assetLibrary.writeImage(toSavedPhotosAlbum: image.cgImage, orientation: orientation) { (assetURL, error) in
                if error == nil && assetURL != nil && complete != nil {
                    print("图片保存成功")
                    DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute:
                        {
                            let asset = PHAsset.fetchAssets(withALAssetURLs: [assetURL!], options: nil).firstObject
                            complete!(asset, error)
                    })
                }else if error != nil && complete != nil {
                    print("图片保存失败")
                    complete!(nil, error)
                }
            }
        }
    }

    //MARK: - 保存视频
    
    func saveVideo(url: URL, complete: ((_ asset: PHAsset?,_ error: Error?)->())?) {
        var localIdentifier = ""
        PHPhotoLibrary.shared().performChanges({
            let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            localIdentifier = request?.placeholderForCreatedAsset?.localIdentifier ?? ""
//            if DPLocationManager.shared.curLocation != nil {
//                request?.location = DPLocationManager.shared.curLocation!
//            }
            request?.creationDate = Date()
        }) { (success, error) in
            DispatchQueue.main.async {
                if success && complete != nil {
                    print("视频保存成功")
                    let asset = PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).firstObject
                    complete!(asset, nil)
                }else {
                    if complete != nil {
                        complete!(nil, error)
                    }
                }
            }
        }
    }
    
    //MARK: - 获得视频

    func getVideo(asset: PHAsset, progressHandler: ((_ progress: Double,_ error: Error?,_ stop:UnsafeMutablePointer<ObjCBool>,_ info:[AnyHashable: Any]?)->())? = nil,_ complete: ((_ playerItem: AVPlayerItem?,_ info:[AnyHashable: Any]? )->())?) {
        let option = PHVideoRequestOptions.init()
        option.isNetworkAccessAllowed = true
        option.progressHandler = { progress, error, stop, info in
            DispatchQueue.main.async {
                if progressHandler != nil {
                    progressHandler!(progress, error, stop, info)
                }
            }
        }
        PHImageManager.default().requestPlayerItem(forVideo: asset, options: option) { (playerItem, info) in
            if complete != nil {
                complete!(playerItem, info)
            }
        }

    }
//    /// Export video 导出视频
//    - (void)getVideoOutputPathWithAsset:(id)asset progress:(void(^)(double progress, NSError* error, BOOL* stop, NSDictionary* info))progress completion:(void (^)(NSString *outputPath))completion;
    
    //MARK: - 相册&相片属性
    
    func isCameraRollAlbum(collection: PHAssetCollection) -> Bool {
        return collection.assetCollectionSubtype == PHAssetCollectionSubtype.smartAlbumUserLibrary
    }
    
    func isVideoAlbum(collection: PHAssetCollection) -> Bool {
        return collection.assetCollectionSubtype == PHAssetCollectionSubtype.smartAlbumVideos
    }

    /// 检查照片大小是否满足最小要求
    func canPhotoSelectable(asset: PHAsset) -> Bool {
        let photoSize = self.photoSize(asset: asset)
        if (self.configModel.minPhotoWidthSelectable > photoSize.width ||
            self.configModel.minPhotoHeightSelectable > photoSize.height) {
            return false
        }
        return true
    }
    
    func photoSize(asset: PHAsset) -> CGSize {
        return CGSize.init(width: asset.pixelWidth, height: asset.pixelHeight)
    }
    
    //获得一组照片的大小
    func getPhotosBytes(photos: [DKAssetModel], complete: ((_ totalBytes: String, _ allPhotoByte: Int)->())?) {
        var dataLength = 0
        var assetCount = 0
        for item in photos {
            let option = PHImageRequestOptions.init()
            option.resizeMode = PHImageRequestOptionsResizeMode.fast
            PHImageManager.default().requestImageData(for: item.asset ?? PHAsset.init(), options: option) { (imageData, dataUTI, orientation, info) in
                if item.mediaType != .video {
                    dataLength += imageData?.count ?? 0
                    assetCount += 1
                    if assetCount >= photos.count {
                        let bytes = self.getBytes(dataLength: dataLength)
                        if complete != nil {
                            complete!(bytes, dataLength)
                        }
                    }
                }
            }
        }
    }

    func getBytes(dataLength: Int) -> String {
        var bytes = ""
        let length = CGFloat(dataLength)
        if length >= 0.1 * (1024 * 1024) {
            bytes = String(format: "%.1fM", length/1024.0/1024.0)
        }else if length >= 1024 {
            bytes = String(format: "%.1fK", length/1024.0)
        }else {
            bytes = String(format: "%zdB", length)
        }
        return bytes
    }
    
    //MARK:- private action
    
    private func createAlbumModel(result: PHFetchResult<PHAsset>, name: String, isCameraRoll: Bool) -> DKAlbumModel {
        let model = DKAlbumModel.init()
        model.result = result
        model.name = name
        model.isCameraRoll = isCameraRoll
        model.count = result.count
        return model
    }

    private func createAssetModel(asset: PHAsset, allowPickingVideo:Bool, allowPickingImage: Bool) -> DKAssetModel? {

        if let delegate = self.pickerDelegate, delegate.responds(to: #selector(DKImagePickerDelegate.isAssetCanSelect(asset:))) {
            if delegate.isAssetCanSelect!(asset: asset) == false {
                return nil
            }
        }
  
        let type = self.getAssetType(asset: asset)
        if (!allowPickingVideo && type == .video) {
            return nil
        }
        if (!allowPickingImage && type == .photo) {
            return nil
        }
        if (!allowPickingImage && type == .photoGif) {
            return nil
        }
            
//        if (self.configModel.hideWhenCanNotSelect) {
//            // 过滤掉尺寸不满足要求的图片
//            if !self.canPhotoSelectable(asset: asset) {
//                return nil
//            }
//        }
        var timeLength = ""
        if type == .video {
            timeLength = self.getNewTime(from: Int(asset.duration))
        }
        let model = DKAssetModel.createModel(with: asset, type: type, timeLength: timeLength)
        return model;
    }
    
    //MARK:- setter & getter
    
    lazy var configModel: DKImageConfigModel = {
        return DKImageConfigModel()
    }()
    
    @available (iOS 9.0, *)
    lazy var assetLibrary: ALAssetsLibrary = {
        return ALAssetsLibrary.init()
    }()
}

extension DKImageManager: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let type: String = info[UIImagePickerController.InfoKey.mediaType] as! String
        if type == "public.image" {
            if let photo: UIImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                IMGInstance.savePhoto(image: photo) { [weak self](asset, error) in
                    if error == nil {
                        if let ass = asset {
                            if let model = IMGInstance.createAssetModel(asset: ass, allowPickingVideo: false, allowPickingImage: true) {
                                if self?.configModel.systemImagePickerVCCompleteBlock != nil {
                                    self?.configModel.systemImagePickerVCCompleteBlock!(model)
                                }
                                //如果有代理则走代理，否则添加到所选中的数组中
                                if let delegate = self?.pickerDelegate, delegate.responds(to: #selector(DKImagePickerDelegate.imagePickerDidAddNewAsset(photo:model:))) {
                                    self?.pickerDelegate?.imagePickerDidAddNewAsset!(photo: photo, model: model)
                                }else {
                                    if self?.configModel.allowCrop == true {
                                        let vc = DKImagePreviewViewController.init()
                                        vc.models = [model]
                                        vc.curIndex = 0
                                        vc.isCropImage = true
                                        vc.fromImagePicker = true
                                        picker.pushViewController(vc, animated: true)
                                    }else {
                                        IMGInstance.addAssetModel(with: model)
                                    }
                                }
                            }
                        }
                    } else {
                        print("\(error?.localizedDescription ?? "")")
                    }
                }
            }
        } else if type == "public.movie" {
            if let videoUrl: URL = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
                IMGInstance.saveVideo(url: videoUrl) {[weak self] (asset, error) in
                    if error == nil {
                        if let ass = asset {
                            if let model = IMGInstance.createAssetModel(asset: ass, allowPickingVideo: true, allowPickingImage: false) {
                                if self?.configModel.systemImagePickerVCCompleteBlock != nil {
                                    self?.configModel.systemImagePickerVCCompleteBlock!(model)
                                }
                            }
                        }
                    } else {
                        print("\(error?.localizedDescription ?? "")")
                    }
                }
            }
        }
        //如果不需要裁剪，则直接关闭系统拍照页面
        if !self.configModel.allowCrop {
            picker.dismiss(animated: true) { [weak self] in
                self?.systemImagePicker!.delegate = nil
                self?.systemImagePicker = nil
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { [weak self] in
            self?.systemImagePicker!.delegate = nil
            self?.systemImagePicker = nil
        }
    }
}
