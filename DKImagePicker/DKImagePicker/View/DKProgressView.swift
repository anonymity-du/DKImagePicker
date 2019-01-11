//
//  DKProgressView.swift
//  DKImagePicker
//
//  Created by 杜奎 on 2019/1/11.
//  Copyright © 2019 DU. All rights reserved.
//

import UIKit

class DKProgressView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
 
    
    override func draw(_ rect: CGRect) {
        let center = CGPoint.init(x: rect.width * 0.5, y: rect.height * 0.5)
        let radius = rect.width * 0.5
        let startA = -CGFloat.pi * 0.5
        let endA = -CGFloat.pi * 0.5 + CGFloat.pi * 2 * self.progress
        
        self.progressLayer.frame = self.bounds
        let path = UIBezierPath.init(arcCenter: center, radius: radius, startAngle: startA, endAngle: endA, clockwise: true)
        self.progressLayer.path = path.cgPath
        self.progressLayer.removeFromSuperlayer()
        self.layer.addSublayer(self.progressLayer)
    }

    //MARK:- setter & getter
    
    var progress: CGFloat = 0 {
        didSet {
            self.setNeedsDisplay()
        }
    }
    
    private var progressLayer: CAShapeLayer = {
        let layer = CAShapeLayer.init()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.white.cgColor
        layer.opacity = 1
        layer.lineCap = CAShapeLayerLineCap.round
        layer.lineWidth = 5.0
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize.init(width: 1, height: 1)
        layer.shadowOpacity = 0.5
        layer.shadowRadius = 2.0
        return layer
    }()
    
}
