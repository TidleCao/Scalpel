//
//  MainVC+IpaMetadataEditTab.swift
//  Scalpel
//
//  Created by jerry on 2018/11/18.
//  Copyright © 2018年 com.sz.jerry. All rights reserved.
//

import Foundation
import Cocoa
extension MainVC{
    class NestedAppTbvDelegate:NSObject, NSTableViewDelegate, NSTableViewDataSource{
        let mainVC: MainVC
        init(mainVC: MainVC) {
            self.mainVC = mainVC
        }
        //MARK: NSTableViewDataSource
        func numberOfRows(in tableView: NSTableView) -> Int{
            return mainVC._nestedAppTbvDs.count
        }
        func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any?{
            return nil
        }
        
        func tableView(_ tableView: NSTableView, willDisplayCell cell: Any, for tableColumn: NSTableColumn?, row: Int) {
            let cell: NSTextFieldCell = cell as! NSTextFieldCell
            cell.title = mainVC._nestedAppTbvDs[row].bundleURL.lastPathComponent
        }
        public func tableViewSelectionDidChange(_ notification: Notification){
            mainVC._nestAppDelBtn.isEnabled = mainVC._nestedAppTbv.selectedRow != -1
        }
        public func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool{
            return false
        }
    }
    class ExtraResourcesTbvDelegate:NSObject, NSTableViewDelegate, NSTableViewDataSource{
        let mainVC: MainVC
        init(mainVC: MainVC) {
            self.mainVC = mainVC
        }
        //MARK: NSTableViewDataSource
        func numberOfRows(in tableView: NSTableView) -> Int{
            return mainVC._dsOfExtraResourcesTbv.count
        }
        func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any?{
            return nil
        }
        func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
            return 20
        }
        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            let dataItem = mainVC._dsOfExtraResourcesTbv[row]
            let columnId = tableColumn!.identifier.rawValue
            let ctnView = NSView()
            let lb = NSTextField.init(labelWithString: "")
            lb.identifier = NSUserInterfaceItemIdentifier(rawValue: "nestedAppNameLb")
            ctnView.addSubview(lb)
            lb.snp.makeConstraints { (maker) in
                maker.leading.trailing.equalToSuperview()
                maker.centerY.equalToSuperview()
            }
            if columnId.elementsEqual("ResourcePath"){
                lb.stringValue = dataItem.resourcePath
            }else if columnId.elementsEqual("EmbeddedRelativePath"){
                lb.stringValue = dataItem.embeddedRelativePath
            }else{
                assert(false)
            }
            return ctnView
        }
        
        public func tableViewSelectionDidChange(_ notification: Notification){
            mainVC._extraResourceRemoveBtn.isEnabled = mainVC._tbvOfExtraResources.selectedRow != -1
        }
        public func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool{
            return false
        }
    }
    func ipaMetadataEditTabSetup(){
        _nestedAppTbvDelegate = NestedAppTbvDelegate(mainVC: self)
        _nestedAppTbv.delegate =  _nestedAppTbvDelegate
        _nestedAppTbv.dataSource = _nestedAppTbvDelegate
        
        _extraResourceTbvDelegate = ExtraResourcesTbvDelegate(mainVC: self)
        _tbvOfExtraResources.delegate = _extraResourceTbvDelegate
        _tbvOfExtraResources.dataSource = _extraResourceTbvDelegate
        _tbvOfExtraResources.tableColumns.forEach { (c) in
            _tbvOfExtraResources.removeTableColumn(c)
        }
        
        let columnW = _tbvOfExtraResources.frame.width / 2
        _tbvOfExtraResources.addTableColumn({
            let c = NSTableColumn.init(identifier: NSUserInterfaceItemIdentifier.init("ResourcePath"))
            c.title = "资源文件"
            c.width = columnW
            return c
            }())
        
        _tbvOfExtraResources.addTableColumn({
            let c = NSTableColumn.init(identifier: NSUserInterfaceItemIdentifier.init("EmbeddedRelativePath"))
            c.title = "存放路径(相对于main bundle)"
            c.width = columnW
            return c
            }())
    }
    @IBAction func onClickNestedAppDeleteBtn(_ sender: Any) {
        do{
            let selectRow = _nestedAppTbv.selectedRow
            if selectRow == -1{
                NSAlert.warning("请选择一个要删除的NestedApp")
                return
            }
            let toDelNestedAppBundle = self._nestedAppTbvDs[selectRow]
            
            self._nestedAppTbvDs.removeAll { (bundle) -> Bool in
                return bundle.bundleIdentifier!.elementsEqual(toDelNestedAppBundle.bundleIdentifier!)
            }
            self._nestedAppTbv.reloadData()
            self._nestedAppTbv.isEnabled = self._nestedAppTbvDs.count > 0
            
            self._dsOfPPFForNestedAppTbv.removeAll(where: { (item) -> Bool in
                return item.appBundle.bundleIdentifier!.elementsEqual(toDelNestedAppBundle.bundleIdentifier!)
            })
            self._tbvOfPPFForNestedApp.reloadData()
        }catch{
            NSAlert.warning("删除Nested App 失败, error:\(error)")
        }
        
    }
   
    
    //MARK: - Extra Resource Edit
    @IBAction func onclickExtraResourceAddBtn(_ sender: Any) {
        let vc = EmbResourceSelectVC.init(resourceType: .arbitrary)
        vc.onSelectedPathConfirmed = { (resourcePath: String, embeddedRelativePath: String) -> Void in
            self.dismissViewController(vc)
            let absEmbeddedPath = self._rawIpaPayloadHandle.mainBundle.bundleURL.appendingPathComponent(embeddedRelativePath)
            if FileManager.default.fileExists(atPath: absEmbeddedPath.path){
                NSAlert.confirm("目标路径(\(embeddedRelativePath))已经存在文件,是否要覆盖？", cancelCallback: nil, confirmCallback: {
                    let item = ExtraResourceItem.init(resourcePath: resourcePath, embeddedRelativePath: embeddedRelativePath)
                    self._dsOfExtraResourcesTbv.append(item)
                    self._tbvOfExtraResources.reloadData()
                })
            }else{
                let item = ExtraResourceItem.init(resourcePath: resourcePath, embeddedRelativePath: embeddedRelativePath)
                self._dsOfExtraResourcesTbv.append(item)
                self._tbvOfExtraResources.reloadData()
            }
        }
        vc.onCanceled = {
            self.dismissViewController(vc)
        }
        self.presentViewControllerAsModalWindow(vc)
    }
    
    @IBAction func onclickExtraResourceRemoveBtn(_ sender: Any) {
        let selectRow = _tbvOfExtraResources.selectedRow
        if selectRow == -1{
            NSAlert.warning("请选择一个要删除的资源")
            return
        }
        self._dsOfExtraResourcesTbv.remove(at: selectRow)
        self._tbvOfExtraResources.reloadData()
    }
}
