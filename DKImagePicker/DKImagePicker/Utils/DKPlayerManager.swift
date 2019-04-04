//
//  DKPlayerManager.swift
//  DatePlay
//
//  Created by DU on 2018/11/22.
//  Copyright © 2018年 DU. All rights reserved.
//

import UIKit
import AVKit

/// 播放器播放状态
///
/// - stop: 暂停或者未播放
/// - playing: 正在播放
/// - loading: 正在加载/缓存
enum DKPlayerPlayStatus {
    case stop
    case playing
    case loading
}

class DKPlayerManager: NSObject {
    static let shared = DKPlayerManager()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private override init() {
        
    }
    
    //播放状态
    private(set) var playStatus = DKPlayerPlayStatus.stop {
        willSet {
            if playStatus != newValue {
                if self.playStatusChangedBlock != nil {
                    self.playStatusChangedBlock!(newValue)
                }
            }
        }
        didSet {
//            NotificationCenter.default.post(name: NSNotification.Name("playerPlayStatusChanged"), object: nil)
        }
    }
    
    private(set) var duration: CGFloat = 0 //视频的时长
    private(set) var videoSize: CGSize = CGSize.zero //视频的宽高
    var videoMaxSize: CGSize = CGSize.zero //视频最大的宽高，有parentView的时无效
    private weak var parentView: UIView? //用于显示loading和吐司，以及决定视频的videoSize
    var needLoopPlay = true //是否需要循环播放
    
    var url: URL? {
        didSet {
            if url != nil {
                self.avasset = AVAsset.init(url: self.url ?? URL.init(fileURLWithPath: ""))
            }
        }
    }
    var avasset: AVAsset? {
        didSet {
            if avasset != nil {
                self.initOrResetPlayer()
            }
        }
    }
    var playItem: AVPlayerItem?
    //播放状态改变闭包，会多次调用
    var playStatusChangedBlock: ((_ status: DKPlayerPlayStatus)->())?
    var playEndBlock: (()->())?

    //MARK:- action
    
    func isPLaying(with url: URL?, asset: AVAsset?) -> Bool {
        if url != nil && url!.path.count > 0 && url == self.url {
            return self.playStatus == .playing ? true : false
        }
        if asset != nil && asset == self.avasset {
            return self.playStatus == .playing ? true : false
        }
        return false
    }
    
    func isLoading(with url: URL?, asset: AVAsset?) -> Bool {
        if url != nil && url!.path.count > 0 && url == self.url {
            return self.playStatus == .loading ? true : false
        }
        if asset != nil && asset == self.avasset {
            return self.playStatus == .loading ? true : false
        }
        return false
    }
    
    func startPlay() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.playEndNotification), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.playItem)
        self.proximityStateDidChange()
        self.playStatus = .loading
        self.player.play()
    }
    
    private func initOrResetPlayer() {
        self.needLoopPlay = true
        self.clearPlayer()

        self.playItem = AVPlayerItem.init(asset: self.avasset!)
        self.playItem?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        self.playItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
        self.playItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
        self.playItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
        
        self.player.replaceCurrentItem(with: self.playItem)
        
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    func clearPlayer() {
        self.playEndBlock = nil
        self.showOrHideLoadingView(show: false)
        self.player.pause()
        self.playStatus = .stop
        NotificationCenter.default.removeObserver(self, name: UIDevice.proximityStateDidChangeNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        UIDevice.current.isProximityMonitoringEnabled = false
        
        if let item = self.playItem {
            item.cancelPendingSeeks()
            item.asset.cancelLoading()
            
            item.removeObserver(self, forKeyPath: "status")
            item.removeObserver(self, forKeyPath: "loadedTimeRanges")
            item.removeObserver(self, forKeyPath: "playbackBufferEmpty")
            item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        }
        self.playItem = nil
    }
    
    @objc func proximityStateDidChange() {
        if !UIDevice.current.proximityState {
            print("有物品离开")
            AVAudioSession.sharedInstance()
                .perform(NSSelectorFromString("setCategory:error:"), with: AVAudioSession.Category.playback)
            do {
                try AVAudioSession.sharedInstance().setActive(true, options: [])
            } catch {}
        } else {
            print("有物品靠近")
            AVAudioSession.sharedInstance()
                .perform(NSSelectorFromString("setCategory:error:"), with: AVAudioSession.Category.playAndRecord)
            do {
                try AVAudioSession.sharedInstance().setActive(true, options: [])
            } catch {}
        }
    }
    
    @objc func playEndNotification() {
        print("播放完了")
        if self.playEndBlock != nil {
            self.playEndBlock!()
        }else {
            self.showOrHideLoadingView(show: false)
            self.playStatus = .stop
    
            if needLoopPlay {
                let dragedCMTime = CMTime.init(seconds: 0.0, preferredTimescale: 600)
                self.player.seek(to: dragedCMTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero) { [weak self](finish) in
                    self?.player.play()
                }
            }else if UIDevice.current.isProximityMonitoringEnabled == true {
                UIDevice.current.isProximityMonitoringEnabled = false
            }
        }
    }
    
    func fetchVideoInfo(time: CMTime, videoTracks: [AVAssetTrack]?, audioTracks: [AVAssetTrack]?) {
        self.duration = CGFloat(time.value)/CGFloat(time.timescale)
        
        var videoWidth: CGFloat = parentView?.width ?? self.videoMaxSize.width
        var videoHeight: CGFloat = parentView?.height ?? self.videoMaxSize.height
        if let count = videoTracks?.count, count > 0 {
            let videoTrack = videoTracks?[0]
            if let track = videoTrack {
                let size = kChangeVideoDirection(videoTrack: track)
                if size.width != 0 && size.height != 0 {
                    if size.height > size.width {
                        videoWidth = videoHeight * (size.width/size.height)
                    }else {
                        videoHeight = videoWidth * (size.height/size.width)
                    }
                }
            }
            UIDevice.current.isProximityMonitoringEnabled = false
        }else if let count = audioTracks?.count, count > 0 {
            UIDevice.current.isProximityMonitoringEnabled = true
            NotificationCenter.default.addObserver(self, selector: #selector(proximityStateDidChange), name: UIDevice.proximityStateDidChangeNotification, object: nil)
        }
        self.videoSize = CGSize.init(width: videoWidth, height: videoHeight)
    }
    
    func fetchVideoProperty(complete: ((_ time: CMTime,_ videoTracks: [AVAssetTrack]?,_ audioTracks: [AVAssetTrack]?)->())?) {
        let keys = ["tracks", "duration"]
        self.avasset?.loadValuesAsynchronously(forKeys: keys, completionHandler: { [weak self] in
            var time = CMTime.zero
            var videoTracks: [AVAssetTrack]?
            var audioTracks: [AVAssetTrack]?

            for key in keys {
                let status = self?.avasset?.statusOfValue(forKey: key, error: nil)
                if status == .loaded {
                    if key == "duration" {
                        time = self?.avasset?.duration ?? CMTime.zero
                    }
                    if key == "tracks" {
                        videoTracks = self?.avasset?.tracks(withMediaType: AVMediaType.video)
                        audioTracks = self?.avasset?.tracks(withMediaType: AVMediaType.audio)
                    }
                }
            }
            if complete != nil {
                complete!(time, videoTracks, audioTracks)
            }
        })
    }
    
    private func showOrHideLoadingView(show: Bool) {
        if show {
            if parentView != nil {
                _ = DKLoadingView.show()
            }
        }else {
            if parentView != nil {
                DKLoadingView.hide()
            }
        }
    }
    
    @objc func willResignActive() {
        self.player.pause()
        self.playStatus = .stop
    }
    
    //MARK:- observe
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let playerItem = object as! AVPlayerItem
        if keyPath == "status" {
            if playerItem.status == .readyToPlay {
                print("准备开始播放了")
            }else if playerItem.status == .failed || playerItem.status == .unknown {
                if self.playEndBlock != nil {
                    self.playEndBlock!()
                    return
                }
                self.player.pause()
                self.playStatus = .stop
                parentView?.makeToast("播放失败")
            }
        }else if keyPath == "loadedTimeRanges" {
            print("loadedTimeRanges \(String(describing: change))")
        }else if keyPath == "playbackBufferEmpty" {
            print("缓冲不足了 \(String(describing: change))")
            self.showOrHideLoadingView(show: true)
            self.playStatus = .loading
        }else if keyPath == "playbackLikelyToKeepUp" {
            self.showOrHideLoadingView(show: false)
            if let new = change?[.newKey] as? Bool, new == true {
                if self.playStatus == .loading {
                    self.playStatus = .playing
                }
            }
            print("缓存达到可播放程度了 \(String(describing: change))")
        }
    }
    
    //MARK:- setter & getter
    
    private(set) lazy var player: AVPlayer = {
        let p = AVPlayer.init(playerItem: self.playItem)
        return p
    }()
}
