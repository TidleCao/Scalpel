//
//  MainVC.swift
//  Scalpel
//
//  Created by jerry on 2017/11/29.
//  Copyright © 2017年 com.sz.jerry. All rights reserved.
//

import Cocoa
import Foundation
class MainVC: NSViewController, NSTableViewDelegate, NSTableViewDataSource{
    
    @IBOutlet weak var _exportBtn: NSButton!
 
    var _currentIpaHandleWorkDir: URL!
    var _rawIpaPayloadHandle: IpaPayloadHandle!
    
    /*------ Dylib link edit Tab ------*/
    var _dsOfDylibLinksTbv: [LinkItem] = []
    @IBOutlet weak var _tbvOfDylibLinks: NSTableView!
    @IBOutlet weak var _selectedIpaPathTf: NSTextField!
    
    @IBOutlet weak var _ipaSelectBtn: NSButton!
    @IBOutlet weak var _addDylibLinkBtn: NSButton!
    @IBOutlet weak var _removeDylibLinkBtn: NSButton!
    var _dylibLinkTbvDelegate: DylibLinkTbvDelegate!
    
    /*------ Ipa meta data edit Tab ------*/
    @IBOutlet weak var _isAppNameModifyCheckBox: NSButton!
    @IBOutlet weak var _appNameTf: NSTextField!
    @IBOutlet weak var _isShortVersionModifyCheckBox: NSButton!
    @IBOutlet weak var _shortVersionTf: NSTextField!
    @IBOutlet weak var _nestedAppTbv: NSTableView!
    
    
    var _nestedAppTbvDs: [EditableBundle] = []
    var _nestedAppTbvDelegate: NestedAppTbvDelegate!
    @IBOutlet weak var _nestAppDelBtn: NSButton!
    
    @IBOutlet weak var _extraResourceFlagLb: NSTextField!
    @IBOutlet weak var _tbvOfExtraResources: NSTableView!
    @IBOutlet weak var _extraResourceAddBtn: NSButton!
    @IBOutlet weak var _extraResourceRemoveBtn: NSButton!
    
    var _extraResourceTbvDelegate: ExtraResourcesTbvDelegate!
    var _dsOfExtraResourcesTbv: [ExtraResourceItem] = []
    
    /*------ Resign Tab ------*/
    @IBOutlet weak var _ppfChooseBtn: NSButton!
    @IBOutlet weak var _cerCbx: NSComboBox!
    @IBOutlet weak var _ppfTf: NSTextField!
    @IBOutlet weak var _bundleIDSettingStrategyChooseBtn: NSPopUpButton!
    
    @IBOutlet weak var _tbvOfPPFForNestedApp: NSTableView!
    var _dsOfPPFForNestedAppTbv: [PPFForNestedAppTbvDataItem] = []
    var _ppfForNestedAppTvcDelegate: PPFForNestedAppTbvDelegate!
    
 
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dylibLinkEditTabSetup()
        ipaMetadataEditTabSetup()
        resignTabSetup()
        
        globalSetup()
    }
    func globalSetup(){
        _exportBtn.isEnabled = false
    }
    
    //MARK: - ------ Delegate ------
    //MARK: IPA选择完成
    func onChoosedToBeInjectedFile(_ ipaPath: String){
        Logger.log("choosed ipa: \(ipaPath)")
        let hud = Hud.showHudInView(self.view)
        DispatchQueue.global().async {
            hud.message = "hash calculating..."
            let fileMd5 = FileHashUtil.hashOfFile(atPath: ipaPath, algorithm: HashAlgorithm.MD5)!
            self._currentIpaHandleWorkDir = Config.WorkingDirectory.caches.appendingPathComponent("ipa\(fileMd5)")
            let upZipDir = self._currentIpaHandleWorkDir.appendingPathComponent( "rawUnzip")
            if !FileManager.default.fileExists(atPath: self._currentIpaHandleWorkDir.path){
                hud.message = "解压ipa..."
                //解压
                try! ShellCmds.unzip(filePath: ipaPath, toDirectory: upZipDir.path)
            }
            hud.message = "macho analysis..."
            self._rawIpaPayloadHandle = IpaPayloadHandle.init(payload: upZipDir.appendingPathComponent("Payload"))
            let dylibLinks = self._rawIpaPayloadHandle.getDylibLinks()
            hud.hide()
            DispatchQueue.main.async {
                //Global Panel
                self._selectedIpaPathTf.stringValue = ipaPath
                self._ipaSelectBtn.title = "重新选择"
                self._exportBtn.isEnabled = true
                
                //DylibLinkEdit Tab
                self._dsOfDylibLinksTbv = dylibLinks.map{OriginalLink.init(link: $0)}
                self._tbvOfDylibLinks.reloadData()
                self._removeDylibLinkBtn.isEnabled = dylibLinks.count > 0
                self._tbvOfDylibLinks.isEnabled = dylibLinks.count > 0
                self._tbvOfDylibLinks.deselectAll(nil)
                self._tbvOfDylibLinks.scrollRowToVisible(0)
                self._addDylibLinkBtn.isEnabled = true
                
                //IpaMetadata Edit Tab
                self._shortVersionTf.stringValue = self._rawIpaPayloadHandle!.mainBundle.shortVersion!
                self._shortVersionTf.isEnabled = false
                self._isShortVersionModifyCheckBox.isEnabled = true
                self._isShortVersionModifyCheckBox.state = .off
                
                self._appNameTf.isEnabled = false
                self._appNameTf.stringValue = self._rawIpaPayloadHandle!.mainBundle.displayName ?? self._rawIpaPayloadHandle!.mainBundle.bundleName!
                self._isAppNameModifyCheckBox.isEnabled = true
                self._isAppNameModifyCheckBox.state = .off
                
                self._extraResourceAddBtn.isEnabled = true
                self._dsOfExtraResourcesTbv = []
                self._tbvOfExtraResources.reloadData()
                
                self._nestedAppTbvDs = self._rawIpaPayloadHandle.currentNestedAppBundles()
                self._nestedAppTbv.reloadData()
                self._nestedAppTbv.isEnabled = self._nestedAppTbvDs.count > 0
                
                //Resign Tab
                self._ppfChooseBtn.isEnabled = true
                self._ppfTf.stringValue = ""
                
                self._cerCbx.isEnabled = false
                self._cerCbx.removeAllItems()
                self._cerCbx.stringValue = ""
                
                self._bundleIDSettingStrategyChooseBtn.isEnabled = true
                self._bundleIDSettingStrategyChooseBtn.selectItem(at: 0)
                self.refreshNestedAppPPFChooseList()
            }
        }
        
        
        
        
        
       
        
    }
    //MARK: - Target Action
    //MARK: 点击 '导出'
    @IBAction func onclickExportBtn(_ sender: Any) {
            let fm = FileManager.default
            //dylib link edit Tab check
            for linkItem in _dsOfDylibLinksTbv{
                if let userAddLink = linkItem as? UserAddLink{
                    if !fm.fileExists(atPath: userAddLink.sourcePath){
                        NSAlert.warning("动态库注入源文件: \(userAddLink.sourcePath) 不存在")
                        return
                    }
                }
            }
            
            //ipa metadata edit Tab check
            if _isShortVersionModifyCheckBox.state == .on{
                let newShortVersion = _shortVersionTf.stringValue.trimming
                if newShortVersion.isEmpty{
                    NSAlert.warning("请填写App版本号")
                    return
                }
            }
            
            if _isAppNameModifyCheckBox.state == .on{
                let newDisplayName = _appNameTf.stringValue.trimming
                if newDisplayName.isEmpty{
                    NSAlert.warning("请填写App名称")
                    return
                }
            }
            
            for extraResource in _dsOfExtraResourcesTbv{
                if !fm.fileExists(atPath: extraResource.resourcePath){
                    NSAlert.warning("待添加资源文件: \(extraResource.resourcePath) 不存在")
                    return
                }
            }
            
            //resign Tab check
            let ppfPath = _ppfTf.stringValue.trimming
            if ppfPath.isEmpty{
                NSAlert.warning("请选择描述文件")
                return
            }
            let signID = _cerCbx.stringValue.trimming
            if signID.isEmpty{
                NSAlert.warning("请选择证书")
                return
            }
            
            if _dsOfPPFForNestedAppTbv.count > 0{
                if let nestedBundle = _dsOfPPFForNestedAppTbv.filter({$0.selectedPPFPath == nil}).first?.appBundle{
                    NSAlert.warning("请给 Nested App: \(nestedBundle.bundleName!) 选择一个用于签名的 .mobileprovision 文件")
                    return
                }
            }
            let hud = Hud.showHudInView(self.view)
            DispatchQueue.global().async {
                do{
                    hud.message = "Preparing export Payload copy..."
                    
                    let exportCopy = self._currentIpaHandleWorkDir.appendingPathComponent("exportCopy\(UInt64(Date().timeIntervalSince1970))")
                    let exportCopyPayload = exportCopy.appendingPathComponent("Payload")
                    
                    try fm.copyItem(at: self._rawIpaPayloadHandle.payload, to: exportCopyPayload, shouldOverwrite: true, withIntermediateDirectories: true)
                    
                    let exportCopyPayloadHanlde = IpaPayloadHandle.init(payload: exportCopyPayload)
                    
                    /* ------- dylib link handle ------- */
                    for linkItem in self._dsOfDylibLinksTbv{
                        if let userAddLink = linkItem as? UserAddLink{
                            hud.message = "Inject \(userAddLink.link)"
                            Logger.log("Inject \(userAddLink.link)")
                            try exportCopyPayloadHanlde.injectDylib(dylibFilePath: userAddLink.sourcePath, embeddedRelativePath: userAddLink.embeddedRelativePath)
                        }
                    }
                    
                    /* ------- ipa metadata handle ------- */
                    
                    if forceMainSyn({self._isShortVersionModifyCheckBox.state}) == .on{
                        let newShortVersion = forceMainSyn({self._shortVersionTf.stringValue.trimming})
                        Logger.log("Update shortVersion to: \(newShortVersion)")
                        hud.message = "Update shortVersion"
                        exportCopyPayloadHanlde.mainBundle.updateShortVersion(newShortVersion)
                    }
                    
                    if forceMainSyn({self._isAppNameModifyCheckBox.state}) == .on{
                        let newDisplayName = forceMainSyn({self._appNameTf.stringValue.trimming})
                        Logger.log("Update displayName to: \(newDisplayName)")
                        hud.message = "Update displayName"
                        exportCopyPayloadHanlde.mainBundle.updateDisplayName(newDisplayName)
                    }
                    
                    if self._dsOfExtraResourcesTbv.count > 0{
                        Logger.log("Add extra resource...")
                    }
                    hud.message = "Add extra resource..."
                    for extraResource in self._dsOfExtraResourcesTbv{
                        Logger.log("Copy \(extraResource.resourcePath) -> \(extraResource.embeddedRelativePath)")
                        try exportCopyPayloadHanlde.addResource(extraResource.resourcePath,
                                                                embeddedRelativePath: extraResource.embeddedRelativePath, shouldOverwrite: true)
                    }
                    hud.message = "Remove nested app..."
                    let allNestedBundles = exportCopyPayloadHanlde.currentNestedAppBundles()
                    let remainNestedBundleIDs = self._nestedAppTbvDs.map{ $0.bundleIdentifier! }
                    for bundle in allNestedBundles{
                        if !remainNestedBundleIDs.contains(bundle.bundleIdentifier!){
                            Logger.log("Remove nested app at path: \(bundle.bundlePath)")
                            try fm.removeItem(atPath: bundle.bundlePath)
                        }
                    }
                    
                    /* ------- resign handle ------- */
                    var nestAppBundleIDToPPF: [String:String] = [:]
                    for item in self._dsOfPPFForNestedAppTbv{
                        nestAppBundleIDToPPF[item.appBundle.bundleIdentifier!] = item.selectedPPFPath!
                    }
                    Logger.log("Start resign...")
                    hud.message = "Start resign..."
                    let resignBundleIDSettingStrategy: IpaPayloadHandle.ResignBundleIDSettingStrategy = {
                        let selectedItem = forceMainSyn({self._bundleIDSettingStrategyChooseBtn.selectedItem!})
                        let allItems = forceMainSyn({self._bundleIDSettingStrategyChooseBtn.menu!.items})
                        let index = allItems.firstIndex(of: selectedItem)!
                        if index == 0{
                            return IpaPayloadHandle.ResignBundleIDSettingStrategy.autoChangeByMobileprovision
                        }else if index == 1{
                            return IpaPayloadHandle.ResignBundleIDSettingStrategy.keepRaw
                        }else{
                            assert(false)
                            return IpaPayloadHandle.ResignBundleIDSettingStrategy.keepRaw
                        }
                    }()
                    
                    let extraResignResources: [String] = self._dsOfExtraResourcesTbv.map({$0.embeddedRelativePath})
                    
                    try exportCopyPayloadHanlde.resign(mainAppNewPPFPath: ppfPath,
                                                       nestAppBundleIDToPPFPath: nestAppBundleIDToPPF,
                                                       codeSignID: signID,
                                                       extraResignResources: extraResignResources,
                                                       resignBundleIDSettingStrategy: resignBundleIDSettingStrategy,
                                                       process: { (onSignFile: String)->Void in
                                                        hud.message = "Sign " + onSignFile
                    })
                    
                    hud.message = "Zip to ipa..."
                    
                    let exportedIpa = self._currentIpaHandleWorkDir.appendingPathComponent("export_edited.ipa")
                    try fm.removeItemIfExists(at: exportedIpa)
                    
                    //压缩回 ipa
                    Logger.log("Zip to ipa: \(exportedIpa)...")
                    
                    try ShellCmds.zip(filePath: exportCopyPayload.path, toDestination: exportedIpa.path)
                    hud.message = "Clean..."
                    Logger.log("Clean...")
                    //清理
                    try fm.removeItem(at: exportCopy)
                    Logger.log("Done")
                    hud.hide()
                    //open
                    try ShellCmds.open(directory: exportedIpa.deletingLastPathComponent().path)
                }catch{
                    hud.hide()
                    Logger.log("Export failed: \(error)")
                    NSAlert.warning("导出Ipa失败, error:\(error)")
                }
            }
    }
    
    //MARK: 选择Ipa
    @IBAction func onclickChooseFileBtn(_ sender: Any) {
        let openPanel: NSOpenPanel = NSOpenPanel.init()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = ["ipa"]
        openPanel.beginSheetModal(for: self.view.window!) { (resp: NSApplication.ModalResponse) in
            if resp == NSApplication.ModalResponse.OK{
                let chooseUrl = openPanel.url!
                let path = chooseUrl.path
                self.onChoosedToBeInjectedFile(path.removingPercentEncoding!)
            }
        }
    }
}



 

