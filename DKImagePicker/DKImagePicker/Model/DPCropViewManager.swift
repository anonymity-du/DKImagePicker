//
//  DPCropViewManager.swift
//  DatePlay
//
//  Created by 杜奎 on 2018/12/7.
//  Copyright © 2018 杜奎. All rights reserved.
//

import UIKit

class DPCropViewManager: NSObject {
    
    /// 裁剪框背景的处理
    class func overlayClipping(with view: UIView, cropRect: CGRect, containerView: UIView, needCircleCrop: Bool) {
        let path = UIBezierPath.init(rect: UIScreen.main.bounds)
        let layer = CAShapeLayer.init()
        if needCircleCrop {
            path.append(UIBezierPath.init(arcCenter: containerView.center, radius: cropRect.size.width * 0.5, startAngle: 0, endAngle: 2 * CGFloat.pi, clockwise: false))
        }else {
            path.append(UIBezierPath.init(rect: cropRect))
        }
        layer.path = path.cgPath
        layer.fillRule = CAShapeLayerFillRule.evenOdd
        layer.fillColor = UIColor.black.cgColor
        layer.opacity = 0.5
        view.layer.addSublayer(layer)
    }

    /// 获得裁剪后的图片
    class func cropImage(with imageView: UIImageView, toRect: CGRect, zoomScale: CGFloat, containerView: UIView) -> UIImage? {
        var transform = CGAffineTransform.identity
        let imageViewRect = imageView.convert(imageView.bounds, to: containerView)
        let point = CGPoint.init(x: imageViewRect.origin.x + imageViewRect.size.width * 0.5, y: imageViewRect.origin.y + imageViewRect.size.height * 0.5)
        let xMargin = containerView.width - toRect.maxX - toRect.origin.x
        let zeroPoint = CGPoint.init(x: (containerView.frame.width - xMargin) * 0.5, y: containerView.center.y)
        let translation = CGPoint.init(x: point.x - zeroPoint.x, y: point.y - zeroPoint.y)
        transform = transform.translatedBy(x: translation.x, y: translation.y)
        //缩放
        transform = transform.scaledBy(x: zoomScale, y: zoomScale)
        
        if let img = imageView.image {
            let width = toRect.width * UIScreen.main.scale
            if let imageRef = self.newTransformedImage(tranform: transform, sourceImage: img.cgImage!, sourceSize: img.size, outputWith: width, cropSize: toRect.size, imageViewSize: imageView.frame.size) {
                var cropedImage = UIImage.init(cgImage: imageRef)
                cropedImage = cropedImage.normalizedImage()
                return cropedImage
            }
        }
       
        return nil
    }
    
    class func newTransformedImage(tranform: CGAffineTransform, sourceImage: CGImage, sourceSize: CGSize, outputWith: CGFloat, cropSize: CGSize, imageViewSize: CGSize) -> CGImage? {
        if let source = self.newScaledImage(source: sourceImage, toSize: sourceSize) {
            let aspect = cropSize.height/cropSize.width
            let outputSize = CGSize.init(width: outputWith, height: outputWith * aspect)
            let context = CGContext(data: nil, width: Int(outputSize.width), height: Int(outputSize.height), bitsPerComponent: source.bitsPerComponent, bytesPerRow: 0, space: source.colorSpace!,bitmapInfo: source.bitmapInfo.rawValue)
            context?.setFillColor(UIColor.clear.cgColor)
            context?.fill(CGRect.init(x: 0, y: 0, width: outputSize.width, height: outputSize.height))
            
            var uiCoords = CGAffineTransform.init(scaleX: outputSize.width/cropSize.width, y: outputSize.height/cropSize.height)
            uiCoords = uiCoords.translatedBy(x: cropSize.width * 0.5, y: cropSize.height * 0.5)
            uiCoords = uiCoords.scaledBy(x: 1.0, y: -1.0)
            context?.concatenate(uiCoords)
            context?.concatenate(tranform)
            context?.scaleBy(x: 1.0, y: -1.0)
            context?.draw(source, in: CGRect.init(x: -imageViewSize.width * 0.5, y: -imageViewSize.height * 0.5, width: imageViewSize.width, height: imageViewSize.height))
            let result = context?.makeImage()
            return result
        }else {
            return nil
        }
    }
    
    class func newScaledImage(source: CGImage, toSize: CGSize) -> CGImage? {
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil, width: Int(toSize.width), height: Int(toSize.height), bitsPerComponent: 8, bytesPerRow: 0, space: rgbColorSpace,bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
         context?.interpolationQuality = .none
        context?.translateBy(x: toSize.width * 0.5, y: toSize.height * 0.5)
        
        context?.draw(source, in: CGRect.init(x: -toSize.width * 0.5, y: -toSize.height * 0.5, width: toSize.width, height: toSize.height))
        let result = context?.makeImage()
        return result!
    }
//    /// 获取圆形图片
//    + (UIImage *)circularClipImage:(UIImage *)image {
//    UIGraphicsBeginImageContextWithOptions(image.size, NO, [UIScreen mainScreen].scale);
//
//    CGContextRef ctx = UIGraphicsGetCurrentContext();
//    CGRect rect = CGRectMake(0, 0, image.size.width, image.size.height);
//    CGContextAddEllipseInRect(ctx, rect);
//    CGContextClip(ctx);
//
//    [image drawInRect:rect];
//    UIImage *circleImage = UIGraphicsGetImageFromCurrentImageContext();
//
//    UIGraphicsEndImageContext();
//    return circleImage;
//    }
    
}
