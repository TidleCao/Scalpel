//
//  NSAlert.swift
//  LJLib
//
//  Created by jerry on 2017/12/7.
//  Copyright © 2017年 com.sz.jerry. All rights reserved.
//

import Foundation
import AppKit
extension NSAlert{
    public static func info(_ infomation: String){
        showAlert(messageText: "提示", informativeText: infomation, style: .informational, buttonTitles: ["知道了"], onClickBtn: {_ in })
    }
    public static func warning(_ infomation: String){
        showAlert(messageText: "警告", informativeText: infomation, style: .warning, buttonTitles: ["知道了"], onClickBtn: {_ in })
    }
    public static func confirm(_ infomation: String, cancelCallback: (()->Void)?, confirmCallback:  (()->Void)?){
        showAlert(messageText: "提示", informativeText: infomation, style: .informational, buttonTitles: ["取消","确定"], onClickBtn: { (index)->Void in
            if index == 0{
                cancelCallback?()
            }else if index == 1{
                confirmCallback?()
            }
        })
    }
    
    
    static func showAlert(messageText: String,
                          informativeText: String,
                          style: NSAlert.Style = .informational,
                          window: NSWindow = NSApplication.shared.windows[0],
                          buttonTitles: [String],
                          onClickBtn:@escaping (_ index: Int)->Void){
        forceMainAsyn {
            let alert = NSAlert.init()
            for title in buttonTitles.reversed(){
                alert.addButton(withTitle: title)
            }
            alert.alertStyle = .warning
            alert.informativeText = informativeText
            alert.messageText = messageText
            let btnCount =  buttonTitles.count
            
            alert.beginSheetModal(for: NSApplication.shared.keyWindow!) { (rsp: NSApplication.ModalResponse) in
                onClickBtn(btnCount - (rsp.rawValue - 1000) - 1)
            }
        }
    }
}

