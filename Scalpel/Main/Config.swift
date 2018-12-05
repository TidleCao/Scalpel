//
//  Config.swift
//  Scalpel
//
//  Created by jerry on 2018/11/22.
//  Copyright © 2018年 com.sz.jerry. All rights reserved.
//

import Foundation
class Config{
    class WorkingDirectory {
        static let root = URL.init(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support/Scalpel")
        static let caches = root.appendingPathComponent("Caches")
    }
 
    static func initialize(){
        try! FileManager.default.createDirectory(at: Config.WorkingDirectory.root, withIntermediateDirectories: true, attributes: nil)
    }
}
