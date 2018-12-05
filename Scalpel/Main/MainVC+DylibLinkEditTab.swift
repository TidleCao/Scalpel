//
//  MainVC+DylibEditTab.swift
//  Scalpel
//
//  Created by jerry on 2018/11/18.
//  Copyright © 2018年 com.sz.jerry. All rights reserved.
//

import Foundation
import Cocoa
extension MainVC{
    class LinkItem{
        let link: String
        init(link: String) {
            self.link = link
        }
    }
    class OriginalLink: LinkItem{
        
    }
    class UserAddLink: LinkItem{
        let sourcePath: String
        let embeddedRelativePath: String
        init(link: String, sourcePath: String, embeddedRelativePath: String) {
            self.sourcePath = sourcePath
            self.embeddedRelativePath = embeddedRelativePath
            super.init(link: link)
        }
    }
    class DylibLinkTbvDelegate:NSObject, NSTableViewDelegate, NSTableViewDataSource{
        let mainVC: MainVC
        init(mainVC: MainVC) {
            self.mainVC = mainVC
        }
        //MARK: NSTableViewDataSource
        public func tableView(_ tableView: NSTableView, shouldEdit tableColumn: NSTableColumn?, row: Int) -> Bool{
            return false
        }
        public func numberOfRows(in tableView: NSTableView) -> Int{
            return mainVC._dsOfDylibLinksTbv.count
        }
        public func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any?{
            return nil
        }
        func tableView(_ tableView: NSTableView, willDisplayCell cell: Any, for tableColumn: NSTableColumn?, row: Int) {
            let cell: NSTextFieldCell = cell as! NSTextFieldCell
            cell.title = mainVC._dsOfDylibLinksTbv[row].link
        }
        public func tableViewSelectionDidChange(_ notification: Notification){
            mainVC._removeDylibLinkBtn.isEnabled = mainVC._tbvOfDylibLinks.selectedRow != -1
        }
    }
    func dylibLinkEditTabSetup(){
        _dylibLinkTbvDelegate = DylibLinkTbvDelegate.init(mainVC: self)
        _tbvOfDylibLinks.delegate = _dylibLinkTbvDelegate
        _tbvOfDylibLinks.dataSource = _dylibLinkTbvDelegate
        _addDylibLinkBtn.isEnabled = false
        _removeDylibLinkBtn.isEnabled = false
        _tbvOfDylibLinks.isEnabled = false
    }
    
    
    //MARK: 点击 '+'
    @IBAction func onclickAddDylibLinkBtn(_ sender: Any) {
        let vc = EmbResourceSelectVC.init(resourceType: .arbitrary)
        vc.onSelectedPathConfirmed = { (resourcePath: String, embeddedRelativePath: String) -> Void in
            self.dismissViewController(vc)
            let link = "@executable_path/" + embeddedRelativePath
            let linkItem = UserAddLink.init(link: link, sourcePath: resourcePath, embeddedRelativePath: embeddedRelativePath)
            self._dsOfDylibLinksTbv.append(linkItem)
            self._tbvOfDylibLinks.reloadData()
            //do at next runloop
            //select last added row
            DispatchQueue.main.async {
                let dstRow = self._dsOfDylibLinksTbv.count - 1
                self._tbvOfDylibLinks.selectRowIndexes(IndexSet.init(integer:  dstRow), byExtendingSelection: false)
                self._tbvOfDylibLinks.scrollRowToVisible(dstRow)
            }
        }
        vc.onCanceled = {
            self.dismissViewController(vc)
        }
        self.presentViewControllerAsSheet(vc)
    }
    //MARK: 点击 '-'
    @IBAction func onclickRemoveDylibLinkBtn(_ sender: Any) {
        if _tbvOfDylibLinks.selectedRow == -1{
            NSAlert.warning("请选择一个要删除的动态库链接")
            return
        }
        NSAlert.confirm("确定删除吗", cancelCallback: nil) {
            self._dsOfDylibLinksTbv.remove(at: self._tbvOfDylibLinks.selectedRow)
            self._tbvOfDylibLinks.reloadData()
        }
    }
}
