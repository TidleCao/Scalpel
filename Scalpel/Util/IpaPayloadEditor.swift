//
//  IpaPayloadEditor.swift
//  Scalpel
//
//  Created by jerry on 2018/11/21.
//  Copyright © 2018年 com.sz.jerry. All rights reserved.
//

import Foundation
import MachoHandle

private func descriptionError(_ errorDescription: String) -> NSError{
    return NSError.init(domain: "0", code: 0, userInfo: [NSLocalizedDescriptionKey : errorDescription])
}

class IpaPayloadHandle{
    enum ResignBundleIDSettingStrategy{
        case keepRaw
        case autoChangeByMobileprovision
    }
    let fm: FileManager = FileManager.default
    let payload: URL
    let machoHandler: MachoHandle!
    let mainBundle: EditableBundle!
    init(payload: URL) {
        self.payload = payload
        let mainAppPath = { () -> String in
            let opt = FileSearcher.SearchOption()
            opt.maxResultNumbers = 1
            opt.searchItemType = [.directory]
            return FileSearcher.searchItems(nameMatchPattern: "app$", inDirectory: payload.path, option: opt).first!
        }()
        self.mainBundle = EditableBundle.init(path: mainAppPath)
        self.machoHandler = MachoHandle.init(machoPath: self.mainBundle.executablePath!)
        
    }
    
    //MARK: - Macho Dylib link Handle
    func getDylibLinks() -> [String]{
        let fatArchs = machoHandler.getFatArchs()
        var dylibCmds: [DylibCommand] = []
        if fatArchs.count > 0{
            for arch in fatArchs{
                dylibCmds = machoHandler.getDylibCommand(in: arch)
                break
            }
        }else{
            dylibCmds = machoHandler.getDylibCommand(in: nil)
        }
        return dylibCmds.map{ machoHandler.getLinkName(forDylibCmd: $0)}
    }
    
    func injectDylib(dylibFilePath: String, embeddedRelativePath: String) throws{
        let absEmbedPath = self.mainBundle.bundleURL.appendingPathComponent(embeddedRelativePath)
        if FileManager.default.fileExists(atPath: absEmbedPath.path){
            throw descriptionError("指定的 embedPath:\(embeddedRelativePath) 已经有文件存在")
        }
        //copy to bundle
        try FileManager.default.createDirectory(at: absEmbedPath.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        try FileManager.default.copyItem(atPath: dylibFilePath, toPath: absEmbedPath.path)
        if let bundle = Bundle.init(path: dylibFilePath),
           let execuableName = bundle.executableURL?.lastPathComponent{
            //add link to macho
            self.machoHandler.addDylibLink("@executable_path/\(embeddedRelativePath)/\(execuableName)")
        }else{
            //add link to macho
            self.machoHandler.addDylibLink("@executable_path/\(embeddedRelativePath)")
        }
    }
    
    func addDylibLink(link: String){
        self.machoHandler.addDylibLink(link)
    }
    
    func deleteDylibLink(link: String) throws{
        //remove link
        self.machoHandler.removeLinkedDylib(link)
        //remove embedPath (if exists)
        if link.starts(with: "@executable_path"){
            let embeddedRelativePath = link.replacingOccurrences(of: "@executable_path/", with: "")
            try fm.removeItem(at: mainBundle.bundleURL.appendingPathComponent(embeddedRelativePath))
        }
    }
    
    //MARK: - Metadata Edit
    func currentNestedAppBundles() -> [EditableBundle]{
        guard let pluginsDir = mainBundle.builtInPlugInsPath else{
            return []
        }
        if !fm.fileExists(atPath: pluginsDir){
            return []
        }
        let searchOpt = FileSearcher.SearchOption.init()
        searchOpt.maxSearchDepth = 1
        return FileSearcher.searchItems(nameMatchPattern: "(.*\\.app)|(.*\\.appex)", inDirectory: pluginsDir, option: searchOpt).map{ EditableBundle.init(path: $0) }
    }
    func removeNestedAppBundle(_ nestedAppBundle: Bundle) throws{
        try FileManager.default.removeItem(at: nestedAppBundle.bundleURL)
    }
    func addResource(_ resourceFilePath: String, embeddedRelativePath: String, shouldOverwrite: Bool) throws{
        let absEmbeddedPath = self.mainBundle.bundleURL.appendingPathComponent(embeddedRelativePath).path
        try self.fm.copyItem(atPath: resourceFilePath, toPath: absEmbeddedPath, shouldOverwrite: shouldOverwrite, withIntermediateDirectories: true)
    }
    
    func removeResource(_ embeddedRelativePath: String, shouldRemoveEmptyParent: Bool = true) throws{
        let dstPath = self.mainBundle.bundleURL.appendingPathComponent(embeddedRelativePath)
        if self.fm.fileExists(atPath: dstPath.path){
            try self.fm.removeItem(atPath: dstPath.path)
        }
        if shouldRemoveEmptyParent{
            var parentDir = dstPath.deletingLastPathComponent()
            let mainBundlePath = self.mainBundle.bundlePath
            while !parentDir.path.elementsEqual(mainBundlePath) {
                if try self.fm.contentsOfDirectory(atPath: parentDir.path).count <= 0{
                    try self.fm.removeItem(at: parentDir)
                }
                parentDir = parentDir.deletingLastPathComponent()
            }
        }
    }
    //MARK: - Resign
    //返回：resignedIpaPath
    func resign(mainAppNewPPFPath: String,
                nestAppBundleIDToPPFPath: [String:String],
                codeSignID: String,
                extraResignResources: [String],
                resignBundleIDSettingStrategy: ResignBundleIDSettingStrategy,
                process: ((_ onSignFile: String) -> Void)?) throws{
        let nestedAppPaths = self.currentNestedAppBundles().map{$0.bundlePath}
        /*
         优先对用户指定的文件进行签名, 可能这些文件会放在nested app下面，如果在 nestedapp 签名过后再对这些文件签名，
         那么nested app的签名校验就无法通过。
         */
        //dylib 注入的
        var injectedFiles = self.getDylibLinks().filter({$0.starts(with: "@executable_path")})
            .map{$0.replacingOccurrences(of: "@executable_path/", with: "")}
            .map{URL.init(fileURLWithPath: self.mainBundle.bundlePath).appendingPathComponent($0).path}
        injectedFiles.append(contentsOf: extraResignResources.map{self.mainBundle.bundleURL.appendingPathComponent($0).path})
        for injectFile in injectedFiles{
            Logger.log("sign \(injectFile)")
            process?(injectFile)
            try ShellCmds.cmdCodeSign(filePath: injectFile,
                                      signID: codeSignID, entitlementFilePath: nil)
        }
        for nestedAppPath in nestedAppPaths{
            try self.sign(appPath: URL.init(fileURLWithPath: nestedAppPath),
                          isMainApp: false,
                          mainAppNewPPFPath: mainAppNewPPFPath,
                          nestAppBundleIDToPPFPath: nestAppBundleIDToPPFPath,
                          codeSignID: codeSignID,
                          resignBundleIDSettingStrategy: resignBundleIDSettingStrategy,
                          process: process)
        }
        
        try self.sign(appPath: self.mainBundle!.bundleURL,
                      isMainApp: true,
                      mainAppNewPPFPath: mainAppNewPPFPath,
                      nestAppBundleIDToPPFPath: nestAppBundleIDToPPFPath,
                      codeSignID: codeSignID,
                      resignBundleIDSettingStrategy:resignBundleIDSettingStrategy,
                      process: process)
    }
    
    func sign(appPath: URL,
              isMainApp: Bool,
              mainAppNewPPFPath: String,
              nestAppBundleIDToPPFPath: [String:String],
              codeSignID: String,
              resignBundleIDSettingStrategy: ResignBundleIDSettingStrategy,
              process: ((_ onSignFile: String) -> Void)?) throws{
        let infoPlistPath = appPath.appendingPathComponent("Info.plist")
        let infoPlistData = try Data.init(contentsOf: infoPlistPath, options:[])
        let rawInfoDic = Dictionary<String,Any>.dictionaryWith(plistData: infoPlistData)!
        
        let rawBundleID = rawInfoDic["CFBundleIdentifier"] as! String
        
        guard let newPPFPath = isMainApp ? mainAppNewPPFPath : nestAppBundleIDToPPFPath[rawBundleID] else{
            throw descriptionError("请给 \(appPath) 配置一个 mobileprovision")
        }
        guard let newPPFModel = PPFModel.init(mobileprovisionFilePath: newPPFPath) else {
            throw descriptionError("描述文件 \(newPPFPath) 解析失败")
        }
        let applicationIdentifierPrefix = newPPFModel.applicationIdentifierPrefix[0]
        let bundleIDInPPF = newPPFModel.entitlements.applicationIdentifier.replacingOccurrences(of: "\(applicationIdentifierPrefix).", with: "")
        
        var finalBundleID: String!
        switch resignBundleIDSettingStrategy {
        case .autoChangeByMobileprovision:
            //wildcard
            if bundleIDInPPF.contains("*"){
                if bundleIDInPPF.elementsEqual("*"){
                    finalBundleID = rawBundleID
                }else{
                    let p = bundleIDInPPF.replacingOccurrences(of: ".", with: "\\.").replacingOccurrences(of: "*", with: ".*")
                    if rawBundleID.isMatch(p){
                        finalBundleID = rawBundleID
                    }else{
                        finalBundleID = bundleIDInPPF.replacingOccurrences(of: "*", with: String.randomStringOfLength(length: 4).lowercased())
                    }
                }
            }else{
                finalBundleID = bundleIDInPPF
            }
        case .keepRaw:
            finalBundleID = rawBundleID
        }
        
        //更新 Info.plist
        if !finalBundleID.elementsEqual(rawBundleID){
            let bundle = EditableBundle.init(url: appPath)
            bundle.updateBundleID(finalBundleID)
        }
        
        //描述文件BundleID 和 待设置BundleID的一致性校验
        //        let p = bundleIDInPPF.replacingOccurrences(of: ".", with: "\\.").replacingOccurrences(of: "*", with: ".*")
        //        if !newBundleID.isMatch(p){
        //            throw IpaHandler.common("App(\(appPath.path)) 待设置BundleID:\(newBundleID) 与 mobileprovision 文件中的(\(bundleIDInPPF))不一致")
        //        }
        
        
        //替换 embedded.mobileprovision
        let embeddedPPFPath = appPath.appendingPathComponent("embedded.mobileprovision")
        if FileManager.default.fileExists(atPath: embeddedPPFPath.path){
            try FileManager.default.removeItem(at: embeddedPPFPath)
        }
        try FileManager.default.copyItem(at: URL.init(fileURLWithPath: newPPFPath), to: embeddedPPFPath)
        
        //从 ppf 中导出 entitlements 文件
        let newEntitlements = URL(fileURLWithPath: "/tmp/new(\(newPPFModel.name)).entitlements")
        let newEntitlementsDic = newPPFModel.entitlementsDictionay
        try PropertyListSerialization.data(fromPropertyList: newEntitlementsDic,
                                           format: PropertyListSerialization.PropertyListFormat.xml,
                                           options: 0).write(to: newEntitlements)
        
        //对App内的特殊文件进行单独签名
        let extrySignExtensions: [String] = ["framework","dylib"]
        let opt = FileSearcher.SearchOption()
        opt.excludedSearchDirectoryNamePattern = "(.*\\.app$)|(.*\\.appex$)|(.*\\.framework$)|(^_CodeSignature$)"
        let namePattern = extrySignExtensions.map { (item) -> String in
            return "(.*\\.\(item)$)"
            }.joined(separator: "|")
        
        let toSignFiles = FileSearcher.searchItems(nameMatchPattern: namePattern, inDirectory: appPath.path, option: opt)
        
        for f in toSignFiles{
            Logger.log("sign \(f)")
            process?(f)
            try ShellCmds.cmdCodeSign(filePath: f, signID: codeSignID, entitlementFilePath: nil)
        }
        //对App进行签名
        Logger.log("sign \(appPath.path)")
        process?(appPath.path)
        try ShellCmds.cmdCodeSign(filePath: appPath.path, signID: codeSignID, entitlementFilePath: newEntitlements.path)
    }
    
   
}
