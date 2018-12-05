//
//  EmbResourceSelectVC.swift
//  Scalpel
//
//  Created by 刘杰 on 2017/12/6.
//  Copyright © 2017年 com.sz.jerry. All rights reserved.
//

import Cocoa
import Cocoa
class EmbResourceSelectVC: NSViewController {
    enum ResourceType{
        case dylib
        case arbitrary
    }
    @IBOutlet weak var _resourcePathTf: NSTextField!
    @IBOutlet weak var _embPathTf: NSTextField!
    @IBOutlet weak var _resourceSelectFlaglb: NSTextField!
    var onCanceled: (()->Void)?
    var onSelectedPathConfirmed: ((_ resourcePath: String, _ embeddedRelativePath: String)->Void)?
    let resourceType: ResourceType
    init(resourceType: ResourceType) {
        self.resourceType = resourceType
        super.init(nibName: NSNib.Name.init("EmbResourceSelectVC"), bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
 
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "资源添加"
        _embPathTf.refusesFirstResponder = true
        _embPathTf.resignFirstResponder()
    }
    
    @IBAction func onclickResourceSelectBtn(_ sender: Any) {
        let openPanel: NSOpenPanel = NSOpenPanel.init()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = true
//        openPanel.allowedFileTypes = ["dylib","framework"]
        openPanel.beginSheetModal(for: self.view.window!) { (resp: NSApplication.ModalResponse) in
            if resp == NSApplication.ModalResponse.OK{
                let chooseUrl = openPanel.url!
                let path = chooseUrl.path.removingPercentEncoding!
                self._resourcePathTf.stringValue = path
            }
        }
 
    }
   
    @IBAction func onclickOkBtn(_ sender: Any) {
        let embeddedPath: String = _embPathTf.stringValue.trimming
        if embeddedPath.isEmpty{
            NSAlert.warning("请填写存放路径")
            return
        }
        if embeddedPath.starts(with: "/"){
            NSAlert.warning("存放路径不可以以/开头")
            return
        }
        let resourcePath = _resourcePathTf.stringValue.trimming
        if resourcePath.isEmpty{
            NSAlert.warning("请选择资源路径")
            return
        }
        onSelectedPathConfirmed?(resourcePath, embeddedPath)
        
    }
    @IBAction func onclickCancelBtn(_ sender: Any) {
        onCanceled?()
    }
}
