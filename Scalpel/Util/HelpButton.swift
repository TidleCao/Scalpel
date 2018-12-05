//
//  HelpButton.swift
//  Scalpel
//
//  Created by 刘杰 on 2018/11/20.
//  Copyright © 2018年 com.sz.jerry. All rights reserved.
//

import Foundation
import AppKit
@IBDesignable
class HelpButton: NSButton{
    @IBInspectable var hint: String = ""
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.bezelStyle = .regularSquare
        self.image = NSImage.init(named: NSImage.Name.init("helpIcon"))
        self.isBordered = false
        self.target = self
        self.action = #selector(onClicked)
    }
    
    @objc func onClicked(){
        assert(!hint.isEmpty, "请设置 hint")
        NSAlert.info(hint)
    }
}
