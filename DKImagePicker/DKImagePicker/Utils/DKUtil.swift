//
//  DKUtil.swift
//  DKImagePicker
//
//  Created by 杜奎 on 2019/1/10.
//  Copyright © 2019 DU. All rights reserved.
//

import UIKit

let kScreenWidth = UIScreen.main.bounds.width
let kScreenHeight = UIScreen.main.bounds.height
let kScreenScale = UIScreen.main.scale

// iPhone X
func isIPhoneXType() -> Bool {
    guard #available(iOS 11.0, *) else {
        return false
    }
    return UIApplication.shared.windows.first?.safeAreaInsets.bottom != 0
}
let kIPhoneX: Bool = isIPhoneXType()
let kStatusBarHeight: CGFloat = kIPhoneX ? 44.0 : 20.0
let kNaviBarHeight: CGFloat = 44.0
let kTabbarHeight: CGFloat = kIPhoneX ? (49.0 + 34.0) : 49.0
let kTabbarSafeBottomMargin: CGFloat = kIPhoneX ? 34.0 : 0.0
let kStatusSafeMargin: CGFloat = kIPhoneX ? 24.0 : 0.0
let kStatusBarAndNavigationBarHeight: CGFloat = kIPhoneX ? 88.0 : 64.0

let kAdaptiveScale: CGFloat = UIScreen.main.bounds.size.height < 569 ? 0.7 : 1.0
let K320Scale: CGFloat = UIScreen.main.bounds.size.height < 569 ? 320.0 / 375.0 : 1.0

//MARK: - notification name

extension Notification.Name {
    static let photoPreviewCollectionViewDidScroll = NSNotification.Name("photoPreviewCollectionViewDidScroll")
}

//MARK: - 适配iOS11

func adjustsScrollViewInsets(scrollView: UIScrollView) {
    if #available(iOS 11.0, *) {
        scrollView.contentInsetAdjustmentBehavior = .never
    }
}

func kFrontWindow() -> UIWindow {
    return (UIApplication.shared.delegate as! AppDelegate).window!
}

//MARK: - 文字大小

func MULTILINE_TEXT_SIZE(text: String, font: UIFont, maxSize: CGSize) -> CGSize {
    let content = text as NSString
    var size = content.boundingRect(with: maxSize, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: font], context: nil).size
    size = CGSize.init(width: ceil(size.width), height: ceil(size.height))
    return size
}

//控制器

func kTopViewController() -> UIViewController? {
    return kTopViewController(root: kFrontWindow().rootViewController)
}

func kTopViewController(root: UIViewController?) -> UIViewController? {
    if root is UINavigationController {
        let nav = root as! UINavigationController
        return kTopViewController(root:nav.viewControllers.last)
    }
    if root is UITabBarController {
        let tab = root as! UITabBarController
        return kTopViewController(root:tab.selectedViewController)
    }
    if root?.presentedViewController != nil {
        return kTopViewController(root:root?.presentedViewController)
    }
    return root
}
