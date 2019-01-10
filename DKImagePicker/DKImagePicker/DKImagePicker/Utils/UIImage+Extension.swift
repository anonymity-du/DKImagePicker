//
//  UIImage+Extension.swift
//  DKImagePicker
//
//  Created by 杜奎 on 2019/1/10.
//  Copyright © 2019 DU. All rights reserved.
//

import UIKit

extension UIImage {
    /// 调整图片方向
    /// adjust the direction of the pic
    func normalizedImage() -> UIImage {
        if self.imageOrientation == .up {
            return  self
        }
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.draw(in: CGRect.init(origin: CGPoint.init(x: 0, y: 0), size: self.size))
        let normalizedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return normalizedImage
    }
    /// 缩略图 thumbnail
    ///
    /// - Parameter size: 目标大小 target size
    func thumbnail(with size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, true, 0)
        self.draw(in: CGRect.init(x: 0, y: 0, width: size.width, height: size.height))
        let newimage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!;
        UIGraphicsEndImageContext();
        return newimage;
    }
    
    /// 保持图片长宽比的缩放
    
    func thumbnailFitToMaxSize(maxSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.draw(in: CGRect.init(origin: CGPoint.init(x: 0, y: 0), size: self.size))
        let normalizedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        let width = self.size.width
        let heigth = self.size.height
        var nWidth: CGFloat = 0
        var nHeight: CGFloat = 0
        if width > heigth {
            nWidth = maxSize.width
            nHeight = heigth * nWidth / width
        } else {
            nHeight = maxSize.height
            nWidth = width * nHeight / heigth
        }
        let size = CGSize.init(width: nWidth, height: nHeight)
        let thumImage = normalizedImage.thumbnail(with: size)
        return thumImage
    }
    
    ///根据颜色生成图片
    static func imageWithColor(color: UIColor ,size: CGSize) -> UIImage {
        let rect: CGRect = CGRect.init(x: 0.0,y: 0.0, width: size.width,height: size.height);
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0);
        let context:CGContext = UIGraphicsGetCurrentContext()!
        context.setFillColor(color.cgColor)
        context.fill(rect);
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    ///改变图片的颜色
    func changeImageWithColor(color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        context.translateBy(x: 0, y: self.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(.normal)
        let rect: CGRect = CGRect.init(x: 0, y: 0, width: self.size.width, height: self.size.height)
        context.clip(to: rect, mask: self.cgImage!)
        color.setFill()
        context.fill(rect)
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    //图片裁圆
    func circleImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale);
        let ref = UIGraphicsGetCurrentContext()
        ref?.addArc(center: CGPoint.init(x: self.size.width * 0.5, y: self.size.height * 0.5), radius: self.size.width * 0.5, startAngle: 0, endAngle: CGFloat(Double.pi * 2), clockwise: true)
        ref?.clip()
        self.draw(in: CGRect.init(x: 0, y: 0, width: self.size.width, height: self.size.height))
        
        let newimage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newimage
    }
}
