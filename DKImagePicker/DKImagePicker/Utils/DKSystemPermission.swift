//
//  DKSystemPermission.swift
//  DKImagePicker
//
//  Created by 杜奎 on 2019/1/24.
//  Copyright © 2019 DU. All rights reserved.
//

import UIKit
import PhotosUI

class DKSystemPermission: NSObject {
    //MARK:- 相册权限
    static func photoAblumHasAuthority(needAlert: Bool? = true,complete:((_ success: Bool) -> Void)? = nil) -> Bool {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization { (status) in
                if status == .authorized {
                    DispatchQueue.main.async {
                        if complete != nil {
                            complete!(true)
                        }
                    }
                } else {
                    if complete != nil {
                        complete!(false)
                    }
                }
            }
        } else {
            if status == .authorized {
                DispatchQueue.main.async {
                    if complete != nil {
                        complete!(true)
                    }
                }
                return true
            } else {
                if complete != nil {
                    complete!(false)
                }
                if needAlert == true {
                    let alert = DKAlertView.init(title: "无法访问相册", message: "请在系统设置里打开相册权限", buttonTitles: ["我再看看", "前往授权"], leftBtnActionBlock: nil) {
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(URL.init(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                        }else {
                            UIApplication.shared.openURL(URL.init(string: UIApplication.openSettingsURLString)!)
                        }
                    }
                    alert.show()
                }
            }
        }
        return false
    }
    //MARK:- 相机权限
    func cameraAblumHasAuthority(needAlert: Bool? = true, complete:((_ success: Bool) -> Void)?) -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { (suc) in
                if suc {
                    DispatchQueue.main.async {
                        DispatchQueue.main.async {
                            if complete != nil {
                                complete!(true)
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        if complete != nil {
                            complete!(false)
                        }
                    }
                }
            }
        } else {
            if status == .authorized {
                DispatchQueue.main.async {
                    if complete != nil {
                        complete!(true)
                    }
                }
                return true
            } else {
                if complete != nil {
                    complete!(false)
                }
                if needAlert == true {
                    let alert = DKAlertView.init(title: "无法启动相机", message: "请前往系统设置里为开放相机权限", buttonTitles: ["我再看看", "前往授权"], leftBtnActionBlock: nil) {
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(URL.init(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                        }else {
                            UIApplication.shared.openURL(URL.init(string: UIApplication.openSettingsURLString)!)
                        }
                    }
                    alert.show()
                }
            }
        }
        return false
    }
}
