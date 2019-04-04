//
//  DKLoadingView.swift
//  DKImagePicker
//
//  Created by DU on 2019/1/22.
//  Copyright © 2019 DU. All rights reserved.
//

import UIKit

class DKLoadingView: UIView {

    class func showMessage(message: String) {
        let view = DKLoadingView.init(frame: UIScreen.main.bounds, message: message)
        view.tag = 10000
        view.alpha = 0
        view.startAnimation()
        kFrontWindow().addSubview(view)
        UIView.animate(withDuration: 0.3) {
            view.alpha = 1
        }
    }
    
    class func show() {
        self.showMessage(message: "")
    }
    
    class func hide() {
        let view =  kFrontWindow().viewWithTag(10000) as? DKLoadingView
        view?.alpha = 0
        view?.endAnimation()
        view?.removeFromSuperview()
    }
    
    convenience init(frame: CGRect, message: String?) {
        self.init(frame: frame)
        
        if let count = message?.count, count > 0 {
            self.labTips.text = message
            self.contentView.addSubview(self.labTips)
            
            self.imgIndicator.centerY = self.contentView.height * 0.5 - 5
            self.labTips.centerX = self.contentView.width * 0.5
            self.labTips.centerY = self.imgIndicator.centerY + 39
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(self.viewHud)
        self.addSubview(self.contentView)
        self.contentView.centerX = self.width * 0.5
        self.contentView.centerY = self.height * 0.5
        
        self.contentView.addSubview(self.imgIndicator)
        self.imgIndicator.centerX = self.contentView.width * 0.5
        self.imgIndicator.centerY = self.contentView.height * 0.5
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startAnimation() {
        let animation = CABasicAnimation.init(keyPath: "transform.rotation")
        animation.toValue = Double.pi * 2
        animation.duration = 2
        animation.repeatCount = MAXFLOAT
        animation.isRemovedOnCompletion = false
        imgIndicator.layer.add(animation, forKey: nil)
        imgIndicator.transform = CGAffineTransform.init(rotationAngle: CGFloat(Double.pi * 2))
    }
    
    func endAnimation() {
        imgIndicator.layer.removeAllAnimations()
    }
    
    
    //MARK:- setter & getter
    
    private lazy var viewHud: UIView = {
        let view: UIView = UIView.init(frame: self.bounds)
        view.backgroundColor = .black
        view.alpha = 0.15
        return view
    }()
    
    private lazy var contentView: UIView = {
        let view: UIView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 110, height: 110))
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        return view
    }()
    
    private lazy var imgIndicator : UIImageView = {
        var imgView = UIImageView.init(frame: CGRect.init(x: 0, y: 0, width: 34, height: 34))
        imgView.image = UIImage.init(named: "ic_loading")
        return imgView
    }()
    
    private lazy var labTips : UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = UIColor.hexColor("A3A3A3")
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()
}
