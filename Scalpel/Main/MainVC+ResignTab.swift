//
//  MainVC+ResignTab.swift
//  Scalpel
//
//  Created by jerry on 2018/11/18.
//  Copyright © 2018年 com.sz.jerry. All rights reserved.
//

import Foundation
import Cocoa
import SnapKit
extension MainVC{
    class ExtraResourceItem{
        let resourcePath: String
        let embeddedRelativePath: String
        init(resourcePath: String, embeddedRelativePath: String) {
            self.resourcePath = resourcePath
            self.embeddedRelativePath = embeddedRelativePath
        }
    }
    class PPFForNestedAppTbvDataItem{
        let appBundle: EditableBundle
        var selectedPPFPath: String?
        init(appBundle: EditableBundle) {
            self.appBundle = appBundle
        }
    }
    class PPFForNestedAppTbvDelegate:NSObject, NSTableViewDelegate, NSTableViewDataSource{
        let mainVC: MainVC
        init(mainVC: MainVC) {
            self.mainVC = mainVC
        }
        //MARK: NSTableViewDataSource
        func numberOfRows(in tableView: NSTableView) -> Int{
            return mainVC._dsOfPPFForNestedAppTbv.count
        }
        func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
            return 20
        }
        func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
            return false
        }
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            let dataItem = mainVC._dsOfPPFForNestedAppTbv[row]
            let columnId = tableColumn!.identifier.rawValue
            if columnId.elementsEqual("NestedApp"){
                let ctnView = NSView()
                let lb = NSTextField.init(labelWithString: dataItem.appBundle.bundleName!)
                lb.identifier = NSUserInterfaceItemIdentifier(rawValue: "nestedAppNameLb")
                lb.stringValue = dataItem.appBundle.bundleName!
                ctnView.addSubview(lb)
                lb.snp.makeConstraints { (maker) in
                    maker.leading.trailing.equalToSuperview()
                    maker.centerY.equalToSuperview()
                }
                return ctnView
            }else if columnId.elementsEqual("SignMobileprovision"){
                let ctnView = NSView()
                ctnView.identifier = NSUserInterfaceItemIdentifier(rawValue: "ppfChooseView")
                if let selectedPPF = dataItem.selectedPPFPath{
                    let chooseBtn = NSButton.init(title: "", target: mainVC, action: #selector(onClickNestedAppPPFChooseBtn))
                    chooseBtn.bezelStyle = .regularSquare
                    chooseBtn.isBordered = false
                    chooseBtn.image = NSImage.init(named: NSImage.Name("reChoose"))
                    chooseBtn.tag = row
                    
                    ctnView.addSubview(chooseBtn)
                    chooseBtn.snp.makeConstraints { (maker) in
                        maker.centerY.equalToSuperview()
                        maker.trailing.equalToSuperview()
                        maker.width.height.equalTo(20)
                    }
                    
                    let lb = NSTextField.init(labelWithString: selectedPPF)
                    lb.lineBreakMode = .byTruncatingTail
                    ctnView.addSubview(lb)
                    lb.snp.makeConstraints { (maker) in
                        maker.leading.equalToSuperview()
                        maker.centerY.equalToSuperview()
                        maker.trailing.equalTo(chooseBtn.snp.leading).inset(-10)
                    }
                    
                }else{
                    let chooseBtn = NSButton.init(title: "选择", target: mainVC, action: #selector(onClickNestedAppPPFChooseBtn))
                    chooseBtn.tag = row
                    chooseBtn.bezelStyle = .regularSquare

                    chooseBtn.isBordered = false
                    chooseBtn.image = NSImage.init(named: NSImage.Name("choose"))
                    chooseBtn.tag = row
                    ctnView.addSubview(chooseBtn)
                    chooseBtn.snp.makeConstraints { (maker) in
                        maker.width.height.equalTo(15)
                        maker.centerY.equalToSuperview()
                        maker.leading.equalToSuperview()
                    }
                }
                return ctnView
            }
            assert(false)
            return nil
        }
        
        public func tableViewSelectionDidChange(_ notification: Notification){
            mainVC._nestAppDelBtn.isEnabled = mainVC._nestedAppTbv.selectedRow != -1
        }
        public func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool{
            return false
        }
    }
    
    func resignTabSetup(){
        _tbvOfPPFForNestedApp.tableColumns.forEach { (c) in
            _tbvOfPPFForNestedApp.removeTableColumn(c)
        }
        
        let columnW = _tbvOfDylibLinks.frame.width / 2
        _tbvOfPPFForNestedApp.addTableColumn({
            let c = NSTableColumn.init(identifier: NSUserInterfaceItemIdentifier.init("NestedApp"))
            c.title = "Nested App"
            c.width = columnW
            return c
        }())
        
        _tbvOfPPFForNestedApp.addTableColumn({
            let c = NSTableColumn.init(identifier: NSUserInterfaceItemIdentifier.init("SignMobileprovision"))
            c.title = "Sign Mobileprovision"
            c.width = columnW
            return c
            }())
        
        _ppfForNestedAppTvcDelegate = PPFForNestedAppTbvDelegate(mainVC: self)
        _tbvOfPPFForNestedApp.delegate = _ppfForNestedAppTvcDelegate
        _tbvOfPPFForNestedApp.dataSource = _ppfForNestedAppTvcDelegate
        
      
    }
    func refreshNestedAppPPFChooseList(){
        let bundles = _rawIpaPayloadHandle.currentNestedAppBundles()
        _dsOfPPFForNestedAppTbv = bundles.map{PPFForNestedAppTbvDataItem.init(appBundle: $0)}
        _tbvOfPPFForNestedApp.reloadData()
    }
    //MARK: Target-Action
    @objc func onClickNestedAppPPFChooseBtn(button: NSButton){
        let row = button.tag
        let openPanel: NSOpenPanel = NSOpenPanel.init()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = ["mobileprovision"]
        openPanel.begin { (resp: NSApplication.ModalResponse) in
            if resp != NSApplication.ModalResponse.OK{
                return
            }
            let chooseUrl = openPanel.url!
            self._dsOfPPFForNestedAppTbv[row].selectedPPFPath = chooseUrl.path
            self._tbvOfPPFForNestedApp.reloadData(forRowIndexes: [row], columnIndexes: [1])
        }
    }
    @IBAction func onClickPPFChooseBtn(_ sender: Any) {
        let openPanel: NSOpenPanel = NSOpenPanel.init()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedFileTypes = ["mobileprovision"]
        openPanel.begin { (resp: NSApplication.ModalResponse) in
            if resp != NSApplication.ModalResponse.OK{
                return
            }
        
            guard let selectedUrl = openPanel.url else{
                return
            }
            let ppfPath = selectedUrl.path
            self._ppfTf.stringValue = ppfPath
            guard let ppfModel = PPFModel.init(mobileprovisionFilePath: ppfPath) else{
                NSAlert.warning("描述文件解析失败")
                return
            }
            let cerNames = ppfModel.mdCertificates.map{ $0.commonName }
            if cerNames.count <= 0{
                NSAlert.warning("描述文件无效: 未包含任何关联证书")
                return
            }
            self._cerCbx.isEnabled = true
            self._cerCbx.removeAllItems()
            self._cerCbx.addItems(withObjectValues: cerNames)
            self._cerCbx.selectItem(at: 0)
        }
    }
  
    @IBAction func onAppNameCheckBoxStateChanged(_ sender: NSButton) {
        _appNameTf.isEnabled = sender.state == .on
        if sender.state != .on{
            self._appNameTf.stringValue = _rawIpaPayloadHandle.mainBundle.displayName ?? _rawIpaPayloadHandle.mainBundle.bundleName!
        }
    }
    @IBAction func onShortVersionCheckBoxStateChanged(_ sender: NSButton) {
        _shortVersionTf.isEnabled = sender.state == .on
        if sender.state != .on{
            self._shortVersionTf.stringValue = _rawIpaPayloadHandle.mainBundle.shortVersion!
        }
    }
}
