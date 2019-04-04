//
//  DKCropVideoHandlerBar.swift
//  DatePlay
//
//  Created by DU on 2018/11/6.
//  Copyright © 2018年 DU. All rights reserved.
//

import UIKit

class DKCropVideoHandlerBar: UIView, UIScrollViewDelegate {

    let singleFrameHeight: CGFloat = 48
    let maxLength: CGFloat = 270
    let minLength: CGFloat = 54
    let ptPerSecond: CGFloat = 18
    var currentLength: CGFloat = 270
    private var marginLeft: CGFloat = 0
    var duration: CGFloat = 0 {
        didSet {
            if duration < 15 {
                boundaryEndTime = duration
                currentLength = duration * ptPerSecond
                self.rightHandlerView.x =  marginLeft + currentLength + self.leftHandlerView.width
                self.layoutRelyOnHandlerBar(isLeft: true)
            }
        }
    }
    var isTracking: Bool {
        return self.scrollView.isTracking
    }
    
    var boundaryStartTime: CGFloat = 0 //播放最小时间
    var boundaryEndTime: CGFloat = 15 //播放最大时间
    var currentPlayTime: CGFloat = 0 {//当前播放的时间
        didSet {
            if playToChangeLineLocation {
                let changeTime: CGFloat = (currentPlayTime - self.boundaryStartTime)
                self.lineView.centerX = self.leftHandlerView.right + changeTime * ptPerSecond
            }
        }
    }
    
    private var playToChangeLineLocation: Bool = true //拖拽的时候不能由外面来改变竖线位置
    private var startCenterX: CGFloat = 0 //竖线拖拽，开始移动的位置
    private var leftHandlerBarCenterX: CGFloat = 0 //左把手拖拽，开始移动的位置
    private var rightHandlerBarCenterX: CGFloat = 0 //右把手拖拽，开始移动的位置
    
    // bounceToRight 往后滑动触发bounce
    var scrollBlock: ((_ bounceToRight: Bool)->())?
    var scrollDidEndDeceleratingBlock: (()->())?
    ///   - type: 1 lineview 2 leftbar 3 rightbar
    var operatorViewOperateBlock: ((_ type: Int,_ drag: Bool)->())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.marginLeft = (self.width - self.maxLength) * 0.5 - self.leftHandlerView.width
    
        self.addSubview(self.scrollView)
        self.addSubview(self.leftBgView)
        self.addSubview(self.leftHandlerView)
        self.addSubview(self.topLineView)
        self.addSubview(self.bottomLineView)
        self.addSubview(self.rightHandlerView)
        self.addSubview(self.rightBgView)
        self.addSubview(self.lineView)
        
        self.leftBgView.x = 0
        self.leftBgView.y = 20
        self.leftHandlerView.y = 18
        self.topLineView.y = 18
        self.bottomLineView.bottom = self.height - 20
        self.rightHandlerView.y = 18
        self.rightBgView.y = 20
        self.lineView.centerY = self.leftHandlerView.centerY

        self.leftHandlerView.x = marginLeft
        self.rightHandlerView.right = self.width - marginLeft
        self.layoutRelyOnHandlerBar(isLeft: true)
    }
    
    private func layoutRelyOnHandlerBar(isLeft: Bool) {//根据手把来重新布局
        self.leftBgView.width = self.leftHandlerView.x
        self.topLineView.width = self.rightHandlerView.x - self.leftHandlerView.right
        self.topLineView.x = self.leftHandlerView.right
        self.bottomLineView.width = self.topLineView.width
        self.bottomLineView.x = self.topLineView.x
        self.rightBgView.width = self.width - self.rightHandlerView.right
        self.rightBgView.right = self.width
        self.lineView.centerX = isLeft ? self.leftHandlerView.right : self.rightHandlerView.x
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - action
    
    @objc func lineViewPanAction(gesture: UIPanGestureRecognizer) {
        let minCenterX: CGFloat = self.leftHandlerView.right - self.lineView.width * 0.5
        let maxCenterX: CGFloat = self.rightHandlerView.x + self.lineView.width * 0.5
        let changePoint = gesture.translation(in: self)
        
        print("\(minCenterX),\(maxCenterX),\(changePoint)")
        switch gesture.state {
        case .began:
            self.changeUserInteraction(type: 2, anti: true)
            self.startCenterX = self.lineView.centerX
            if self.operatorViewOperateBlock != nil {
                self.operatorViewOperateBlock!(1,true)
            }
        case .changed:
            let afterCenterX = self.startCenterX + changePoint.x
            if afterCenterX < minCenterX {
                self.lineView.centerX = minCenterX
            }else if afterCenterX > maxCenterX {
                self.lineView.centerX = maxCenterX
            }else {
                self.lineView.centerX = self.startCenterX + changePoint.x
            }
            self.currentPlayTime = (self.lineView.centerX + self.scrollView.contentOffset.x)/self.ptPerSecond
            if self.scrollBlock != nil {
                self.scrollBlock!(false)
            }
        case .ended:
            self.currentPlayTime = (self.lineView.centerX + self.scrollView.contentOffset.x)/self.ptPerSecond
            self.changeUserInteraction(type: 2, anti: false)
            if self.operatorViewOperateBlock != nil {
                self.operatorViewOperateBlock!(1,false)
            }
        default:
            print("")
        }
    }
    
    @objc func handleBarPanAction(gesture: UIPanGestureRecognizer) {
        var isLeft = true
        if gesture.view == self.rightHandlerView {
            isLeft = false
        }
    
        var minCenterX: CGFloat = 0
        var maxCenterX: CGFloat = 0
        //最小3秒，54pt
        if isLeft {
            minCenterX = marginLeft + self.leftHandlerView.width * 0.5
            maxCenterX = self.rightHandlerView.x - self.minLength - self.leftHandlerView.width * 0.5
        }else {
            maxCenterX = marginLeft + self.leftHandlerView.width * 1.5 + currentLength
            minCenterX = self.leftHandlerView.right + self.minLength + self.leftHandlerView.width * 0.5
        }
        let changePoint = gesture.translation(in: self)

        print("\(minCenterX),\(maxCenterX),\(changePoint)")
        switch gesture.state {
        case .began:
            self.changeUserInteraction(type: isLeft ? 3 : 4, anti: true)
            if isLeft {
                self.leftHandlerBarCenterX = self.leftHandlerView.centerX
            }else {
                self.rightHandlerBarCenterX = self.rightHandlerView.centerX
            }
            if self.operatorViewOperateBlock != nil {
                self.operatorViewOperateBlock!(isLeft ? 2 : 3,true)
            }
        case .changed:
            print("")
            if isLeft {
                let afterCenterX = self.leftHandlerBarCenterX + changePoint.x
                if afterCenterX < minCenterX {
                    self.leftHandlerView.centerX = minCenterX
                }else if afterCenterX > maxCenterX {
                    self.leftHandlerView.centerX = maxCenterX
                }else {
                    self.leftHandlerView.centerX = self.leftHandlerBarCenterX + changePoint.x
                }
            }else {
                let afterCenterX = self.rightHandlerBarCenterX + changePoint.x
                if afterCenterX < minCenterX {
                    self.rightHandlerView.centerX = minCenterX
                }else if afterCenterX > maxCenterX {
                    self.rightHandlerView.centerX = maxCenterX
                }else {
                    self.rightHandlerView.centerX = self.rightHandlerBarCenterX + changePoint.x
                }
            }
            self.layoutRelyOnHandlerBar(isLeft: isLeft)
            if isLeft {
                self.boundaryStartTime = (self.scrollView.contentOffset.x + self.leftHandlerView.right)/self.ptPerSecond
                self.currentPlayTime = self.boundaryStartTime
            }else {
                self.boundaryEndTime = (self.scrollView.contentOffset.x + self.rightHandlerView.x)/self.ptPerSecond
                self.currentPlayTime = self.boundaryEndTime
            }
            if self.scrollBlock != nil {
                self.scrollBlock!(false)
            }
        case .ended:
            self.changeUserInteraction(type: isLeft ? 3 : 4, anti: false)
            if self.operatorViewOperateBlock != nil {
                self.operatorViewOperateBlock!(isLeft ? 2 : 3,false)
            }
        default:
            print("")
        }
        
    }
    
    /// - Parameters:
    ///   - type: 1 scrollview 2 lineview 3 leftbar 4rightbar
    ///   - anti: 阻止与否
    private func changeUserInteraction(type: Int, anti: Bool) {
        if type == 1 {
            self.lineView.isUserInteractionEnabled = !anti
            self.leftHandlerView.isUserInteractionEnabled = !anti
            self.rightHandlerView.isUserInteractionEnabled = !anti
        }else if type == 2 {
            self.scrollView.isScrollEnabled = !anti
            self.leftHandlerView.isUserInteractionEnabled = !anti
            self.rightHandlerView.isUserInteractionEnabled = !anti
        }else if type == 3 {
            self.scrollView.isScrollEnabled = !anti
            self.lineView.isUserInteractionEnabled = !anti
            self.rightHandlerView.isUserInteractionEnabled = !anti
        }else if type == 4 {
            self.scrollView.isScrollEnabled = !anti
            self.leftHandlerView.isUserInteractionEnabled = !anti
            self.lineView.isUserInteractionEnabled = !anti
        }
        self.playToChangeLineLocation = !anti
    }
    
    //MARK: - delegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentOffsetX = scrollView.contentOffset.x
        let contentWidth = self.duration * self.ptPerSecond
        if contentOffsetX >= -self.leftHandlerView.right && contentOffsetX <= contentWidth {
            let startScale = (contentOffsetX + self.leftHandlerView.right)/contentWidth
            self.currentPlayTime = (self.lineView.centerX + self.scrollView.contentOffset.x)/self.ptPerSecond
            let offsetTime = self.boundaryEndTime - self.boundaryStartTime
            self.boundaryStartTime = self.duration * startScale
            self.boundaryEndTime = self.boundaryStartTime + offsetTime
            if self.scrollBlock != nil {
                self.scrollBlock!(false)
            }
        }else {
            if self.scrollBlock != nil {
                self.scrollBlock!(true)
            }
        }
        if scrollView.isTracking {
            self.changeUserInteraction(type: 1, anti: true)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        print("哈哈哈")
        self.changeUserInteraction(type: 1, anti: false)
        if self.scrollDidEndDeceleratingBlock != nil {
            self.scrollDidEndDeceleratingBlock!()
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false {
            self.changeUserInteraction(type: 1, anti: false)
            if self.scrollDidEndDeceleratingBlock != nil {
                self.scrollDidEndDeceleratingBlock!()
            }
        }
    }
    
    //MARK: - setter & getter
    
    var images: [UIImage]? {
        didSet {
            if let imageArray = images {
                for subview in self.scrollView.subviews {
                    subview.removeFromSuperview()
                }
                var offsetX: CGFloat = 0
                let itemWidth = (self.duration * self.ptPerSecond - self.singleFrameHeight)/CGFloat(imageArray.count - 1)
                for item in imageArray {
                    let itemView = UIImageView.init(frame: CGRect.init(x: offsetX, y: 0, width: self.singleFrameHeight, height: self.singleFrameHeight))
                    itemView.image = item
                    itemView.clipsToBounds = true
                    itemView.contentMode = .scaleAspectFill
                    self.scrollView.addSubview(itemView)
                    offsetX += itemWidth
                }
                self.scrollView.contentSize = CGSize.init(width: self.duration * self.ptPerSecond, height: self.singleFrameHeight)
            }
        }
    }
    
    private(set) lazy var scrollView: UIScrollView = {
        let view = UIScrollView.init(frame: CGRect.init(x: 0, y: 20, width: self.width, height: self.singleFrameHeight))
        view.backgroundColor = UIColor.clear
        view.contentInset = UIEdgeInsets.init(top: 0, left: marginLeft + self.leftHandlerView.width, bottom: 0, right: marginLeft + self.leftHandlerView.width)
        view.delaysContentTouches = false
        view.expandEdge = UIEdgeInsets.init(top: 10, left: 10, bottom: 10, right: 10)
        view.delegate = self
        return view
    }()
    
    private lazy var leftHandlerView: UIImageView = {
        let view = UIImageView.init()
        view.expandEdge = UIEdgeInsets.init(top: 10, left: 15, bottom: 10, right: 15)
        view.image = UIImage.init(named: "ic_lefthandle")
        view.sizeToFit()
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(UIPanGestureRecognizer.init(target: self, action: #selector(handleBarPanAction(gesture:))))
        return view
    }()
    
    private lazy var rightHandlerView: UIImageView = {
        let view = UIImageView.init()
        view.expandEdge = UIEdgeInsets.init(top: 10, left: 15, bottom: 10, right: 15)
        view.image = UIImage.init(named: "ic_righthandle")
        view.sizeToFit()
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(UIPanGestureRecognizer.init(target: self, action: #selector(handleBarPanAction(gesture:))))
        return view
    }()
    
    private lazy var topLineView: UIView = {
        let view = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: 2))
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.hexColor("A28DFF")
        return view
    }()
    
    private lazy var bottomLineView: UIView = {
        let view = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: 2))
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.hexColor("A28DFF")
        return view
    }()
    
    private lazy var leftBgView: UIView = {
        let view = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: self.singleFrameHeight))
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.init(white: 0, alpha: 0.4)
        return view
    }()
    
    private lazy var rightBgView: UIView = {
        let view = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: self.singleFrameHeight))
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.init(white: 0, alpha: 0.4)
        return view
    }()
    
    private lazy var lineView: UIView = {
        let view = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 2, height: 70))
        view.backgroundColor = UIColor.hexColor("#A28DFF")
        view.expandEdge = UIEdgeInsets.init(top: 20, left: 15, bottom: 20, right: 15)
        view.addGestureRecognizer(UIPanGestureRecognizer.init(target: self, action: #selector(lineViewPanAction(gesture:))))
        return view
    }()
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        let frame = CGRect.init(x: self.lineView.x - 15, y: self.lineView.y - 20, width: self.lineView.width + 30, height: self.lineView.height + 40)
        if frame.contains(point) {
            print("在里面")
            return self.lineView
        }else {
            print("在外面")
        }
        
        return view
    }
}
