//
//  DKCropVideoViewController.swift
//  DatePlay
//
//  Created by DU on 2018/10/31.
//  Copyright © 2018年 DU. All rights reserved.
//

import UIKit
import AVKit
import Photos

class DKCropVideoViewController: UIViewController {

    var videoModel: DKAssetModel?
    var avasset: AVAsset?
    
    private var images = [UIImage]()
    private var timePoints = [CMTime]()
    private var manualStop: Bool = false
    let singleFrameHeight: CGFloat = 48
    
    private var playProgressObserver: Any?
    private var playBoundaryObserver: Any?
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.isNavigationBarHidden = true
        view.backgroundColor = UIColor.black
        view.addSubview(self.navigationBar)
        self.navigationBar.addSubview(self.backBtn)
        self.navigationBar.addSubview(self.completeBtn)
        self.completeBtn.right = self.navigationBar.width - 16
        self.completeBtn.centerY = 42.5 + kStatusSafeMargin
        self.backBtn.x = 16
        self.backBtn.centerY = self.completeBtn.centerY
        
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
        
        self.deleteFile(ouputFilePath)
        self.loadSubview()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.view.bringSubviewToFront(self.navigationBar)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true

        DKPlayerManager.shared.clearPlayer()
        if self.playBoundaryObserver != nil {
            DKPlayerManager.shared.player
                .removeTimeObserver(self.playBoundaryObserver!)
        }
        if self.playProgressObserver != nil {
            DKPlayerManager.shared.player
                .removeTimeObserver(self.playProgressObserver!)
        }
    }
    
    func loadSubview() {
        
        view.addSubview(self.playBackView)
        view.addSubview(self.playIconView)
        
        self.fetchVideoConfigInfo()
    }
    
    private func layoutSurplusView() {
        self.playBackView.layer.addSublayer(self.playerLayer)
        self.playIconView.center = self.playBackView.center
        self.view.addSubview(self.playOperateView)
        self.view.addSubview(self.selectBar)
        self.selectBar.bottom = self.view.height - 30 - kTabbarSafeBottomMargin
    }
    
    //MARK:- action
    
    @objc private func pop() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func backBtnClicked() {
        if let model = self.videoModel {
            IMGInstance.removeAssetModel(with: model)
        }
        self.pop()
    }
    
    @objc private func completeBtnClicked() {
        let index: Int = Int((self.selectBar.boundaryStartTime)/2.5)
        let imageTime = self.timePoints[index]
        let imageGenerator = AVAssetImageGenerator.init(asset: DKPlayerManager.shared.avasset!)
        imageGenerator.appliesPreferredTrackTransform = true
        self.cropVideo {[weak self] (url, success) in
            imageGenerator.generateCGImagesAsynchronously(forTimes: [imageTime] as [NSValue]) { (requestedTime, cgImg, actualTime, result, error) in
                DispatchQueue.main.async {
                    if result == .succeeded && cgImg != nil {
                        let frameImage = UIImage.init(cgImage: cgImg!)
                        print("原始封面大小:\(frameImage.size)")
                        DKLoadingView.hide()
                        if success {
                            let videoModel = DKVideoModel.init()
                            videoModel.path = self?.ouputFilePath
                            
                            videoModel.coverThumbImg = frameImage
                            videoModel.width = DKPlayerManager.shared.videoSize.width
                            videoModel.height = DKPlayerManager.shared.videoSize.height
                            let path = (NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first ?? "") + "/coverThumbImg.jpeg"
                            let imgData = videoModel.coverThumbImg?.jpegData(compressionQuality: 0.4)
                            self?.writeData(data: imgData ?? Data(), filePath: path)
                            videoModel.coverPath = path
                            NotificationCenter.default.post(name: NSNotification.Name("cropVideoSuccess"), object: videoModel)
                            self?.pop()
                        }else {
                            self?.view.makeToast("裁剪失败，请重试！")
                        }
                    } else {
                        self?.view.makeToast("裁剪失败，请重试！")
                    }
                }
            }
            
        }
    }
    
    @objc func playOperateViewTaped() {
        if self.manualStop {
            DKPlayerManager.shared.player.play()
            self.manualStop = false
            self.playIconView.isHidden = true
        }else {
            DKPlayerManager.shared.player.pause()
            self.manualStop = true
            self.playIconView.isHidden = false
        }
    }
    
    @objc func playEndNotification() {
        print("播放完了")
        self.playBackToStart(isBeginning: true)
        DKPlayerManager.shared.player.play()
    }
    
    @objc private func willResignActive() {
        self.manualStop = true
        self.playIconView.isHidden = false
    }
    
    func deleteFile(_ filePath: String) {
        if FileManager.default.fileExists(atPath: filePath) {
            do {
                try FileManager.default.removeItem(atPath: filePath)
                print("文件删除成功：\(filePath)")
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func writeData(data: Data, filePath: String) -> Void {
        FileManager.default.createFile(atPath: filePath, contents: data, attributes: nil)
    }
    //MARK: - video handle
    
    func fetchVideoConfigInfo() {
        if self.avasset == nil {
            kFrontWindow().makeToast("视频资源不存在!")
            self.pop()
            return
        }
        DKLoadingView.show()
        self.layoutSurplusView()
        self.fetchFrameImages()
    }

    func fetchFrameImages() {

        let imageGenerator = AVAssetImageGenerator.init(asset: DKPlayerManager.shared.avasset!)
        imageGenerator.appliesPreferredTrackTransform = true
        
        var images = [UIImage]()
        var points = [CMTime]()
        var curPoint: CGFloat = 0
        while curPoint + 2.5 <= DKPlayerManager.shared.duration {
            let point: CMTime = CMTimeMakeWithSeconds(Float64(curPoint), preferredTimescale: 600)
            points.append(point)
            curPoint += 2.5
        }
        if curPoint + 2.5 > DKPlayerManager.shared.duration {
            let lastPoint: CMTime = CMTimeMakeWithSeconds(Float64(DKPlayerManager.shared.duration), preferredTimescale: 600)
            points.append(lastPoint)
        }
        
        if let lastPoint = points.last {
            self.timePoints.append(contentsOf: points)
            imageGenerator.generateCGImagesAsynchronously(forTimes: points as [NSValue]) { [weak self] (requestedTime, cgImg, actualTime, result, error) in
                if result == .succeeded && cgImg != nil {
                    var frameImage = UIImage.init(cgImage: cgImg!)
                    if frameImage.size.width > frameImage.size.height  {
                        let scale = frameImage.size.width/frameImage.size.height
                        frameImage = frameImage.thumbnail(with: CGSize.init(width: 80 * scale, height: 80))
                    }else {
                        let scale = frameImage.size.height/frameImage.size.width
                        frameImage = frameImage.thumbnail(with: CGSize.init(width: 80, height: 80 * scale))
                    }
                    images.append(frameImage)
                    if requestedTime.value >= lastPoint.value {
                        self?.images.append(contentsOf: images)
                        DispatchQueue.main.async {
                            if self?.view != nil {
                                DKLoadingView.hide()
                            }
                            self?.showImagesView()
                        }
                    }
                } else {
                    DispatchQueue.main.async { [weak self] in
                        DKLoadingView.hide()
                        kFrontWindow().makeToast("数据处理失败，请重试")
                        self?.pop()
                    }
                }
            }
        }else {
            kFrontWindow().makeToast("解析视频出错，请重试")
            self.pop()
        }
    }
    
    func showImagesView() {
        if self.images.count > 0 {
            self.selectBar.duration = DKPlayerManager.shared.duration
            self.selectBar.images = self.images
            
            self.changeBoundaryObserver()
            self.playProgressObserver = DKPlayerManager.shared.player.addPeriodicTimeObserver(forInterval: CMTime.init(seconds: 0.05, preferredTimescale: 600), queue: DispatchQueue.main, using: { [weak self] (cmTime) in
                let time = CGFloat(cmTime.value)/CGFloat(cmTime.timescale)
                self?.selectBar.currentPlayTime = time
            })
            
            self.playIconView.isHidden = true
            DKPlayerManager.shared.playEndBlock = {[weak self] in
                self?.playEndNotification()
            }
            DKPlayerManager.shared.startPlay()
        }
    }
    
    /// 改变边界触发点，在右边手把位置触发，然后回到左边手把位置
    private func changeBoundaryObserver() {
        if self.playBoundaryObserver != nil {
            DKPlayerManager.shared.player
                .removeTimeObserver(self.playBoundaryObserver!)
        }
        let endCMTime = CMTime.init(seconds: Double(self.selectBar.boundaryEndTime), preferredTimescale: 600)

        self.playBoundaryObserver = DKPlayerManager.shared.player.addBoundaryTimeObserver(forTimes: [NSValue.init(time: endCMTime)], queue: DispatchQueue.main) {[weak self] in
            if let isTrack = self?.selectBar.isTracking, isTrack == false {
                self?.playBackToStart(isBeginning: true)
            }
        }
    }
    
    /// 根据手把重新调整播放开始或者结束
    private func playBackToStart(isBeginning: Bool) {
        let dragedCMTime = CMTime.init(seconds: Double(isBeginning ? self.selectBar.boundaryStartTime : (self.selectBar.boundaryEndTime - 1.5)), preferredTimescale: 600)
        DKPlayerManager.shared.player.seek(to: dragedCMTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero) { (finish) in
            
        }
    }
    
    //视频裁剪

    private func cropVideo(completionBlock: @escaping ((_ outputUrl: URL,_ isSuccess: Bool) -> Void)) {
        
        let option = PHVideoRequestOptions.init()
        option.progressHandler = { progress, error, stop, info in
            print("icloud 视频下载中 \(progress)")
        }
        option.isNetworkAccessAllowed = true
        option.deliveryMode = .mediumQualityFormat
        
        guard self.videoModel?.asset != nil else {
            self.view.makeToast("裁剪失败，请重试!")
            return
        }
        
        PHImageManager.default().requestAVAsset(forVideo: self.videoModel!.asset!, options: option) { (avasset, audioMix, info) in
            DispatchQueue.main.sync {
                if avasset != nil {
                    let outputFileUrl = URL.init(fileURLWithPath: self.ouputFilePath)
                    let compatible = AVAssetExportSession.exportPresets(compatibleWith: avasset!)
                    var supportCompatible = ""
                    if compatible.contains(AVAssetExportPreset1280x720) {
                        supportCompatible = AVAssetExportPreset1280x720
                    }else {
                        supportCompatible = AVAssetExportPresetHighestQuality
                    }
                    if let exportSession = AVAssetExportSession.init(asset: avasset!, presetName: supportCompatible) {
                        exportSession.outputURL = outputFileUrl
                        exportSession.outputFileType = AVFileType.mp4
                        exportSession.shouldOptimizeForNetworkUse = true
                        
                        let start = CMTime.init(seconds: Double(self.selectBar.boundaryStartTime), preferredTimescale: 600)
                        let duration = CMTime.init(seconds: Double(self.selectBar.boundaryEndTime - self.selectBar.boundaryStartTime), preferredTimescale: 600)

                        let range = CMTimeRange.init(start: start, duration: duration)
                        exportSession.timeRange = range
                        
                        DKLoadingView.show()
                        exportSession.exportAsynchronously(completionHandler: {
                            switch exportSession.status {
                            case .completed:
                                do {
                                    let data = try Data.init(contentsOf: URL.init(fileURLWithPath: self.ouputFilePath))
                                    print("data length \(data.count)")
                                }catch {}
                                //                    if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(self.ouputFilePath){
                                //                        UISaveVideoAtPathToSavedPhotosAlbum(self.ouputFilePath, self, #selector(self.saveVideo(videoPath:error:contextInfo:)), nil)
                                //                    }
                                
                                completionBlock(outputFileUrl, true)
                            case .failed:
                                print("合成失败：\(exportSession.error.debugDescription)")
                                completionBlock(outputFileUrl, false)
                            case .cancelled:
                                completionBlock(outputFileUrl, false)
                            default:
                                completionBlock(outputFileUrl, false)
                            }
                        })
                    }else {
                        self.view.makeToast("裁剪失败，请重试!")
                    }
                }
            }
        }
    }
    @objc private func saveVideo(videoPath: String,error: Error?, contextInfo: AnyObject) {
        if error == nil {
            print("保存到相册成功")
        }else {
            print("保存到相册失败")
        }
    }

    
    //MARK:- setter & getter
    
    private lazy var ouputFilePath: String = {
        let path = (NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first ?? "") + "/coverVideo.mp4"
        return path
    }()

    private lazy var navigationBar: UIView = {
        let view = UIView.init(frame: CGRect.init(x: 0, y: 0, width: self.view.width, height: kStatusBarAndNavigationBarHeight))
        view.backgroundColor = UIColor.white
        return view
    }()
    
    private lazy var backBtn: UIButton = {
        let btn = UIButton.init(type: UIButton.ButtonType.custom)
        btn.setImage(UIImage.init(named: "back"), for: .normal)
        btn.expandEdge = UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10)
        btn.sizeToFit()
        btn.addTarget(self, action: #selector(backBtnClicked), for: .touchUpInside)
        return btn
    }()
    
    private lazy var completeBtn: UIButton = {
        let btn = UIButton.init(type: UIButton.ButtonType.custom)
        btn.setTitle("完成", for: .normal)
        btn.setTitleColor(kGenericColor, for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        btn.sizeToFit()
        btn.addTarget(self, action: #selector(completeBtnClicked), for: .touchUpInside)
        return btn
    }()
    
    private lazy var playerLayer: AVPlayerLayer = {
        let layer = AVPlayerLayer.init(player: DKPlayerManager.shared.player)
        layer.videoGravity = AVLayerVideoGravity.resize
        layer.frame = CGRect.init(x: (self.view.width - DKPlayerManager.shared.videoSize.width) * 0.5, y: (self.view.height - DKPlayerManager.shared.videoSize.height) * 0.5, width: DKPlayerManager.shared.videoSize.width, height: DKPlayerManager.shared.videoSize.height)
        return layer
    }()
    
    private lazy var playBackView: UIView = {
        let view = UIView.init(frame: self.view.bounds)
        view.backgroundColor = UIColor.black
        return view
    }()
    
    private lazy var playIconView: UIImageView = {
        let view = UIImageView.init()
        view.image = UIImage.init(named: "ic_square_play")
        view.sizeToFit()
        return view
    }()
    
    private lazy var playOperateView: UIView = {
        let view = UIView.init(frame: self.playerLayer.frame)
        view.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(playOperateViewTaped)))
        return view
    }()
    
    private lazy var selectBar: DKCropVideoHandlerBar = {
        let view = DKCropVideoHandlerBar.init(frame: CGRect.init(x: 0, y: 0, width: self.view.width, height: 50 + 40))
        view.scrollBlock = { [weak self] bounce in
            DKPlayerManager.shared.player.pause()
            if !bounce {
                let dragedCMTime = CMTime.init(seconds: Double(self?.selectBar.currentPlayTime ?? 0), preferredTimescale: 600)
                DKPlayerManager.shared.player.seek(to: dragedCMTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero) { (finish) in
                }
            }
        }
        view.scrollDidEndDeceleratingBlock = { [weak self] in
            if self!.manualStop == false {
                self?.changeBoundaryObserver()
                DKPlayerManager.shared.player.play()
                self?.playIconView.isHidden = true
            }
        }
        view.operatorViewOperateBlock = { [weak self] type, drag in
            if drag {
                DKPlayerManager.shared.player.pause()
            }else {
                if type == 1 {
                    let dragedCMTime = CMTime.init(seconds: Double(self?.selectBar.currentPlayTime ?? 0), preferredTimescale: 600)
                    DKPlayerManager.shared.player.seek(to: dragedCMTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero) { (finish) in
                    }
                }else if type == 2 {
                    self?.changeBoundaryObserver()
                    self?.playBackToStart(isBeginning: true)
                }else if type == 3 {
                    self?.changeBoundaryObserver()
                    self?.playBackToStart(isBeginning: false)
                }
                if self!.manualStop == false {
                    DKPlayerManager.shared.player.play()
                    self?.playIconView.isHidden = true
                }
            }
        }
        return view
    }()
}
