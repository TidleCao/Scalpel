//
//  AppDelegate.swift
//  Scalpel
//
//  Created by jerry on 2017/11/23.
//  Copyright © 2017年 com.sz.jerry. All rights reserved.
//

import Cocoa

@NSApplicationMain

class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var window: NSWindow!
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Config.initialize()
        self.window.contentViewController = MainVC()
        self.window.styleMask.remove(.resizable)
        self.window.styleMask.remove(.fullScreen)
    }
}

