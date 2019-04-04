//
//  UIColor+DKExtension.swift
//  ImitationOfTodayNews
//
//  Created by DU on 2017/5/25.
//  Copyright © 2017年 DU. All rights reserved.
//

import UIKit

extension UIColor {

    static func hexColor(_ hexStr: String) -> UIColor? {
        return UIColor.hexColor(hexStr, 1.0)
    }
    
    static func hexColor(_ hexStr:String,_ a:CGFloat) -> UIColor? {

        if hexStr.isEmpty {
            return nil
        }else {
            let transHexStr = hexStr.replacingOccurrences(of: "#", with: "")
            if transHexStr.count != 6 {
                return nil
            }else {
                var red:CGFloat = 0
                var green:CGFloat = 0
                var blue:CGFloat = 0
                var arr = [Int]()
                
                for char in transHexStr {
                    arr.append(hexNumber(hexStr: String(char).lowercased()))
                }
                red = CGFloat(arr[0] * 16 + arr[1])/255.0
                green = CGFloat(arr[2] * 16 + arr[3])/255.0
                blue = CGFloat(arr[4] * 16 + arr[5])/255.0
                return UIColor.init(red: red, green: green, blue: blue, alpha: a)
            }
        }
    }
    
    private static func hexNumber(hexStr:String) -> Int {
        switch hexStr {
        case "f":
            return 15
        case "e":
            return 14
        case "d":
            return 13
        case "c":
            return 12
        case "b":
            return 11
        case "a":
            return 10
        default:
            return Int(hexStr)!
        }
    }
}
