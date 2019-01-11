//
//  UIView+DKToast.swift
//  DKImagePicker
//
//  Created by 杜奎 on 2019/1/11.
//  Copyright © 2019 DU. All rights reserved.
//

import UIKit

private var kActiveToasts = "kActiveToasts"
private var kToastQueues = "kToastQueues"
private var kToastTimerKey = "kToastTimerKey"
private var kToastMessageKey = "kToastMessageKey"

extension UIView {
    
    var activeToasts: [DKToastView] {
        get {
            var views = objc_getAssociatedObject(self, &kActiveToasts) as? [DKToastView]
            if views == nil {
                views = [DKToastView]()
                objc_setAssociatedObject(self, &kActiveToasts, views, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            return views!
        }
        set {
            objc_setAssociatedObject(self, &kActiveToasts, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var toastQueue: [DKToastView] {
        get {
            var views = objc_getAssociatedObject(self, &kToastQueues) as? [DKToastView]
            if views == nil {
                views = [DKToastView]()
                objc_setAssociatedObject(self, &kToastQueues, views, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            return views!
        }
        set {
            objc_setAssociatedObject(self, &kToastQueues, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func makeToast(_ message: String) {
        if message.count <= 0 {
            return
        }
        
        var repeatedMsg = false
        
        for view in self.activeToasts {
            let msg = objc_getAssociatedObject(view, &kToastMessageKey) as? String
            if msg == message {
                repeatedMsg = true
                break
            }
        }
        
        for view in self.toastQueue {
            let msg = objc_getAssociatedObject(view, &kToastMessageKey) as? String
            if msg == message {
                repeatedMsg = true
                break
            }
        }
        
        if !repeatedMsg {
            let toast = DKToastView.init(with: message)
            objc_setAssociatedObject(toast, &kToastMessageKey, message, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            // store the completion block on the toast view
            
            if self.toastQueue.count > 0 {
                self.toastQueue.append(toast)
            } else {
                self.showToast(with: toast)
            }
        }
    }
    
    private func showToast(with toast: DKToastView) {
        toast.center = CGPoint.init(x: self.width * 0.5, y: self.height * 0.5)
        toast.isUserInteractionEnabled = false
        toast.alpha = 0.0
        
        self.activeToasts.append(toast)
        self.addSubview(toast)
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: UIView.AnimationOptions.curveEaseOut, animations: {
            toast.alpha = 1.0
        }) { (finished) in
            let timer = Timer.init(timeInterval: 2.0, target: self, selector: #selector(self.dismissToast(with:)), userInfo: toast, repeats: false)
            RunLoop.main.add(timer, forMode: .common)
            objc_setAssociatedObject(toast, &kToastTimerKey, timer, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @objc private func dismissToast(with timer: Timer?) {
        if let toast = timer?.userInfo as? DKToastView {
            UIView.animate(withDuration: 0.2, delay: 0.0, options: UIView.AnimationOptions.curveEaseIn, animations: {
                toast.alpha = 0.0
            }) { (finished) in
                toast.removeFromSuperview()
                let timer = objc_getAssociatedObject(toast, &kToastTimerKey) as? Timer
                timer?.invalidate()
                for (index, item) in self.activeToasts.reversed().enumerated() {
                    if item == toast {
                        self.activeToasts.remove(at: index)
                        break
                    }
                }
                if self.toastQueue.count > 0 {
                    if let nextToast = self.toastQueue.first {
                        self.toastQueue.removeFirst()
                        self.showToast(with: nextToast)
                    }
                }
            }
        }
    }
}
