//
//  UIScrollView+Extension.swift
//  DatePlay
//
//  Created by 杜奎 on 2018/10/16.
//  Copyright © 2018年 AimyMusic. All rights reserved.
//

import UIKit

private var kEndEditAvoidViewArrayKey = "kEndEditAvoidViewArrayKey"

extension UIScrollView {
    
    var endEditAvoidViewArray: [UIView]? {
        get {
            return objc_getAssociatedObject(self, &kEndEditAvoidViewArrayKey) as? [UIView]
        }
        set {
            objc_setAssociatedObject(self, &kEndEditAvoidViewArrayKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    open override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if let view = hitView  {
            var isAvoid = false
            if !isEditingWithView(view: view) && self.endEditAvoidViewArray?.count ?? 0 > 0 {
                for itemView in self.endEditAvoidViewArray! {
                    if itemView.isEqual(view) {
                        isAvoid = true
                    }
                }
            }
            if !isAvoid {
                endEditing(true)
                superview?.endEditing(true)
            }
        }
        return hitView
    }

    func isEditingWithView(view: UIView) -> Bool {
        if ((view is UITextView) || (view is UITextField) || (view.superview is UITextView)) {
            return true
        }
        return false
    }
}
