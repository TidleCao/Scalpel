//
//  MenuHandle.swift
//  Scalpel
//
//  Created by 刘杰 on 2018/11/22.
//  Copyright © 2018年 com.sz.jerry. All rights reserved.
//

import Foundation
import Cocoa
class MenuHandle: NSObject{
    
    @IBAction func onClickOpenWorkingDirBtn(_ sender: Any) {
        try! ShellCmds.open(directory: Config.WorkingDirectory.root.path)
    }
    @IBAction func onClickCleanCachesBtn(_ sender: Any) {
        let hud = Hud.showHudInView(NSApplication.shared.keyWindow!.contentView!)
        hud.message = "Clean caches..."
        DispatchQueue.global().async {
            try! FileManager.default.removeItemIfExists(at: Config.WorkingDirectory.caches)
            try! FileManager.default.createDirectory(at: Config.WorkingDirectory.caches, withIntermediateDirectories: true, attributes: nil)
            sleep(1)
            hud.hide()
        }
        
    }
}
