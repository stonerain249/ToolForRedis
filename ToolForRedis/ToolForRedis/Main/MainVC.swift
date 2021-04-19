//
//  MainVC.swift
//  RedClient
//
//  Created by swlee on 2021/01/07.
//

import Cocoa

class MainVC: NSViewController, NSWindowDelegate {

    static var progressIndicator: NSProgressIndicator!
    
    //@IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var tfServer: NSTextField!
    @IBOutlet weak var tfScanMatch: NSTextField!
    @IBOutlet weak var tvRedis: NSTableView!
    @IBOutlet weak var btnLogicalDB: NSPopUpButton!
    @IBOutlet weak var chkUTF8KeyName: NSButton!
    @IBOutlet weak var lblKeyCount: NSTextField!
    @IBOutlet weak var btnKeyspaceNoti: NSButton!
    
    @IBOutlet weak var lblKeyName: NSTextField!
    @IBOutlet weak var lblKeyValueType: NSTextField!
    @IBOutlet weak var lblKeyValueSize: NSTextField!
    
    @IBOutlet weak var lblKeyValueTtl: NSTextField!
    @IBOutlet weak var lblKeyValueTtlDesc: NSTextField!
    
    // string
    @IBOutlet weak var vValueString: NSView! // string 타입일때 보여줄 뷰.
    @IBOutlet weak var txtKeyInfoValue: NSTextView!
    @IBOutlet weak var btnSaveString: NSButton!
    
    // list, hash, zset
    @IBOutlet weak var vValueItem2: NSView! // list, hash, zset 타입일때 보여줄 뷰
    @IBOutlet weak var tvItem2: NSTableView! // list, hash, zset 타입 : 테이블뷰의 컬럼이 2개
    @IBOutlet weak var txtItem2Value1: NSTextField!
    @IBOutlet weak var txtItem2Value2: NSTextView!
    @IBOutlet weak var btnSaveItem2: NSButton!
    @IBOutlet weak var btnDeleteItem2: NSButton!
    @IBOutlet weak var btnAddItem2: NSButton!
    
    // set
    @IBOutlet weak var vValueItem1: NSView! // set 타입일때 보여줄 뷰
    @IBOutlet weak var tvItem1: NSTableView! // set 타입 : 테이블뷰의 컬럼이 1개
    @IBOutlet weak var txtItem1Value: NSTextView!
    @IBOutlet weak var btnSaveItem1: NSButton!
    @IBOutlet weak var btnDeleteItem1: NSButton!
    @IBOutlet weak var btnAddItem1: NSButton!
    
    @IBOutlet var alertAccessoryV_AddKey: AlertAccessoryV_AddKey!
    
    @IBOutlet weak var vConsole: NSView!
    @IBOutlet var tvConsole: NSTextView!
    @IBOutlet weak var vCommandCli: NSView!
    
    @IBOutlet weak var layoutBgTrailing: NSLayoutConstraint!

    internal var serverInfo:ServerInfo?
    internal var libRedis:LibRedis = LibRedis()
    internal var libRedisSub:LibRedis? // keyspace notification을 구독하기 위함.
    internal var keyInfoArray:[KeyInfo] = []
//    {
//        willSet(newValue) {
//            print("------------------------------------------ newValue = [\(newValue)]")
//        }
//        didSet(oldValue) {
//            print("------------------------------------------ oldValue = [\(oldValue)]")
//        }
//    }
    internal var keyInfoArraySelectedIndex:Int = -1
    internal var logicalDbKeyCount:[Int] = []
    internal var logicalDbNo:Int = 0 // 현재 선택된 논리적디비 번호 (select 명령어)
        
    internal var isKeyspaceNotificationOn:Bool = false {
        willSet(newValue) {
            
        }
        didSet(oldValue) {
            if isKeyspaceNotificationOn {
                btnKeyspaceNoti.doChangeTitleColor(color: NSColor.white)
                doKeyspaceNotificationConnect()
            } else {
                btnKeyspaceNoti.doChangeTitleColor(color: NSColor.lightGray)
                doKeyspaceNotificationDisconnect()
            }
        }
    }
    
    var commandCliV:CommandCliV?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MainVC.progressIndicator = NSProgressIndicator()
        MainVC.progressIndicator.frame = NSRect(x: self.view.frame.width/2-50, y: self.view.frame.height/2-50, width: 100, height: 100)
        MainVC.progressIndicator.isHidden = true
        MainVC.progressIndicator.style = .spinning
        self.view.addSubview(MainVC.progressIndicator)
                
        self.vValueString.isHidden = false
        self.vValueItem2.isHidden = true
        self.vValueItem1.isHidden = true
        vConsole.isHidden = true

        btnLogicalDB.removeAllItems()
        
        tvRedis.delegate = self
        tvRedis.dataSource = self
        tvItem2.delegate = self
        tvItem2.dataSource = self
        tvItem1.delegate = self
        tvItem1.dataSource = self
        
        LibRedisCommand.closureDisplayCommand = {(cmd:String) in
            let d = Date()
            let df = DateFormatter()
            df.dateFormat = "HH:mm:ss"
            
            self.tvConsole.string += "> [\(df.string(from: d))] \(cmd)\n"
            self.tvConsole.scrollToEndOfDocument(self)
        }
        
        commandCliV = doLoadViewFromXib(nibName: "CommandCliV", ownerView: vCommandCli) as? CommandCliV
    }

    override func viewDidAppear() {
        self.view.window?.title = Bundle.main.infoDictionary!["CFBundleName"] as! String
        self.view.window?.delegate = self
        

    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApplication.shared.terminate(self)
        return true
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    
    func doInit() {
        var LogicalDbCount = 15
        
        LibRedis.doAdd(.configGet(section: "databases", continueOnError:true) { (configs:[(configKey: String, configValue: String)]) in
            LogicalDbCount = Int(configs[configs.index(before: configs.endIndex)].configValue) ?? 0
            print("logical db count = \(LogicalDbCount)")
        })
        LibRedis.doAdd(.info(section: "keyspace", continueOnError:true) { (infos:[(infoKey:String, infoValue:String)]) in
            print("infos----------------------------------------")
            print(infos)
            print("infos----------------------------------------")
            self.btnLogicalDB.removeAllItems()
            
            for i in 0..<LogicalDbCount {
                var keyCount:String = ""
                for info in infos[infos.index(after: infos.startIndex)..<infos.endIndex] {
                    if "db\(i)" == info.infoKey {
                        keyCount = info.infoValue.components(separatedBy: ",")[0]
                        break
                    }
                }
                
                if keyCount == "" {keyCount = "0"}
                keyCount = keyCount.replacingOccurrences(of: "keys=", with: "")
                self.logicalDbKeyCount.append(Int(keyCount) ?? 0)
            }
            
            for i in 0..<LogicalDbCount {
                let item:NSMenuItem = NSMenuItem()
                item.title = "db\(i) (\(self.logicalDbKeyCount[i]) keys)"
                item.tag = i
                self.btnLogicalDB.menu?.addItem(item)
            }
        })
        self.doScan(nil)
    }

    
    internal func doClearKeyInfo() {
        self.keyInfoArraySelectedIndex = -1
        self.lblKeyName.stringValue = ""
        self.lblKeyValueType.stringValue = ""
        self.lblKeyValueSize.stringValue = ""
        self.lblKeyValueTtl.stringValue = ""
        self.txtKeyInfoValue.string = ""
        self.txtItem1Value.string = ""
        self.txtItem2Value1.stringValue = ""
        self.txtItem2Value2.string = ""
        tvItem2.reloadData()
        tvItem1.reloadData()
    }
    
    
    internal func doClearItemInfo() {
        self.txtItem1Value.string = ""
        self.txtItem2Value1.stringValue = ""
        self.txtItem2Value2.string = ""
    }
    

    internal func doGetKeyInfo() {
        let keyInfo:KeyInfo = keyInfoArray[keyInfoArraySelectedIndex]
        if keyInfo.isNew {return} // 새로 생긴 키 라면, 그냥 종료.
        
        LibRedis.doAdd(.type(keyInfo: keyInfo, continueOnError: false) { (keyType:String) in
            
            // 키가 없을때.
            if keyType == RedisDataType.none.rawValue {
                self.keyInfoArray.remove(at: self.keyInfoArraySelectedIndex)
                self.tvRedis.removeRows(at: IndexSet(integer: self.keyInfoArraySelectedIndex), withAnimation: .effectFade)
                self.doClearKeyInfo()
                self.doClearItemInfo()
                return
            }
            
            self.keyInfoArray[self.keyInfoArraySelectedIndex].keyType = keyType
                        
            if keyType == RedisDataType.string.rawValue {
                LibRedis.doAdd(.get(keyInfo: keyInfo, continueOnError:true) { (valueType:String, value:String, valueSize:Int)->Void in
                    self.keyInfoArray[self.keyInfoArraySelectedIndex].valueSize = valueSize
                    self.keyInfoArray[self.keyInfoArraySelectedIndex].valueString = value
                    self.doShowKeyInfo(keyInfo:self.keyInfoArray[self.keyInfoArraySelectedIndex])
                })
            }
            
            if keyType == RedisDataType.list.rawValue {
                LibRedis.doAdd(.lrange(keyInfo: keyInfo, startOffset: 0, continueOnError: true) { (returnValue:[String:Any]) in
                    self.keyInfoArray[self.keyInfoArraySelectedIndex].valueSize = returnValue["valueSize"] as? Int ?? 0
                    self.keyInfoArray[self.keyInfoArraySelectedIndex].itemArrayList = (returnValue["itemAry"] as? [String] ?? []).enumerated().map { (index, value) in
                        return (index, value)
                    }
                    self.keyInfoArray[self.keyInfoArraySelectedIndex].originItemArrayList = self.keyInfoArray[self.keyInfoArraySelectedIndex].itemArrayList
                    self.doShowKeyInfo(keyInfo:self.keyInfoArray[self.keyInfoArraySelectedIndex])
                })
            }
            
            if keyType == RedisDataType.set.rawValue {
                LibRedis.doAdd(.sscan(keyInfo: keyInfo, cursorIndex: 0, continueOnError: false) { (returnValue:[String : Any]) in
                    self.keyInfoArray[self.keyInfoArraySelectedIndex].valueSize = returnValue["valueSize"] as? Int ?? 0
                    self.keyInfoArray[self.keyInfoArraySelectedIndex].itemArraySet = (returnValue["itemAry"] as? [String] ?? []).enumerated().map { (index, value) in
                        return (index, value)
                    }
                    self.keyInfoArray[self.keyInfoArraySelectedIndex].originItemArraySet = self.keyInfoArray[self.keyInfoArraySelectedIndex].itemArraySet
                    self.doShowKeyInfo(keyInfo:self.keyInfoArray[self.keyInfoArraySelectedIndex])
                })
            }
            
            if keyType == RedisDataType.hash.rawValue {
                LibRedis.doAdd(.hscan(keyInfo: keyInfo, cursorIndex: 0, continueOnError: false, closureResultHscan: { (returnValue:[String : Any]) in
                    self.keyInfoArray[self.keyInfoArraySelectedIndex].valueSize = returnValue["valueSize"] as? Int ?? 0
                    self.keyInfoArray[self.keyInfoArraySelectedIndex].itemArrayHash = (returnValue["itemAry"] as? [(String, String)] ?? []).enumerated().map { (index, c) in
                        let (hash, value) = c
                        return (index, hash, value)
                    }
                    self.keyInfoArray[self.keyInfoArraySelectedIndex].originItemArrayHash = self.keyInfoArray[self.keyInfoArraySelectedIndex].itemArrayHash
                    self.doShowKeyInfo(keyInfo:self.keyInfoArray[self.keyInfoArraySelectedIndex])
                }))
            }
            
            if keyType == RedisDataType.zset.rawValue {
                LibRedis.doAdd(.zrange(keyInfo: keyInfo, startOffset: 0, continueOnError: true) { (returnValue:[String:Any]) in
                    self.keyInfoArray[self.keyInfoArraySelectedIndex].valueSize = returnValue["valueSize"] as? Int ?? 0
                    self.keyInfoArray[self.keyInfoArraySelectedIndex].itemArrayZset = (returnValue["itemAry"] as? [(String, String)] ?? []).enumerated().map { (index, c) in
                        let (score, value) = c
                        return (index, score, value)
                    }
                    self.keyInfoArray[self.keyInfoArraySelectedIndex].originItemArrayZset = self.keyInfoArray[self.keyInfoArraySelectedIndex].itemArrayZset
                    self.doShowKeyInfo(keyInfo:self.keyInfoArray[self.keyInfoArraySelectedIndex])
                })
            }
            
            LibRedis.doAdd(.ttl(keyInfo: keyInfo, continueOnError:true) { (ttl:Int) in
                print("ttl = [\(ttl)]")
                self.keyInfoArray[self.keyInfoArraySelectedIndex].valueTtl = ttl
                self.doShowKeyTtl(keyInfo:self.keyInfoArray[self.keyInfoArraySelectedIndex])
            })
        })
        LibRedis.doSend(libRedisSocket:libRedis.libRedisSocket)
    }


    internal func doShowKeyInfo(keyInfo:KeyInfo) {
        //let keyInfo:KeyInfo = keyInfoArray[keyInfoArraySelectedIndex]
        let keyName:String = keyInfo.keyName
        //let keyData:Data = keyInfo.keyData
        let keyType:String = keyInfo.keyType
        let valueSize:Int = keyInfo.valueSize
        
        self.lblKeyName.stringValue = keyName
        self.lblKeyValueSize.stringValue = String(valueSize) + (valueSize > 1 ? " bytes" : " byte")
        self.lblKeyValueType.stringValue = keyType == "zset" ? "sorted set" : keyType

        if keyType == RedisDataType.string.rawValue {
            self.txtKeyInfoValue.string = keyInfo.valueString
            self.vValueString.isHidden = false
            self.vValueItem2.isHidden = true
            self.vValueItem1.isHidden = true
        }
        
        if keyType == RedisDataType.list.rawValue {
            let columnIdentifier = NSUserInterfaceItemIdentifier(rawValue: "tvItem2.col1")
            self.tvItem2.tableColumn(withIdentifier: columnIdentifier)?.title = "Index"
            self.tvItem2.reloadData()
            self.vValueString.isHidden = true
            self.vValueItem2.isHidden = false
            self.vValueItem1.isHidden = true
            txtItem2Value1.isEditable = false // 리스트타입일때, index는 수정할수 없음.
        }
        
        if keyType == RedisDataType.set.rawValue {
            self.tvItem1.reloadData()
            self.vValueString.isHidden = true
            self.vValueItem2.isHidden = true
            self.vValueItem1.isHidden = false
            txtItem2Value1.isEditable = true
        }
        
        if keyType == RedisDataType.hash.rawValue {
            let columnIdentifier = NSUserInterfaceItemIdentifier(rawValue: "tvItem2.col1")
            self.tvItem2.tableColumn(withIdentifier: columnIdentifier)?.title = "Key"
            self.tvItem2.reloadData()
            self.vValueString.isHidden = true
            self.vValueItem2.isHidden = false
            self.vValueItem1.isHidden = true
            txtItem2Value1.isEditable = true
        }
        
        if keyType == RedisDataType.zset.rawValue {
            let columnIdentifier = NSUserInterfaceItemIdentifier(rawValue: "tvItem2.col1")
            self.tvItem2.tableColumn(withIdentifier: columnIdentifier)?.title = "Score"
            self.tvItem2.reloadData()
            self.vValueString.isHidden = true
            self.vValueItem2.isHidden = false
            self.vValueItem1.isHidden = true
            txtItem2Value1.isEditable = true
        }
        
        if keyInfo.isNew {return}
        self.tvRedis.reloadData(forRowIndexes: IndexSet(self.keyInfoArraySelectedIndex...self.keyInfoArraySelectedIndex), columnIndexes: IndexSet(0..<self.tvRedis.tableColumns.count))
    }
    
    
    internal func doShowKeyTtl(keyInfo:KeyInfo) {
        let ttl:Int = keyInfo.valueTtl
        self.lblKeyValueTtl.stringValue = String(ttl)
        if ttl < 0 {
            self.lblKeyValueTtlDesc.stringValue = "Forever"
        } else {
            let days = ttl / 86400
            let hours = (ttl % 86400) / 3600
            let minutes = (ttl % 3600) / 60
            let seconds = (ttl % 3600) % 60
            self.lblKeyValueTtlDesc.stringValue = "\(days)d \(hours)h \(minutes)m \(seconds)s"
        }
    }
    
    
    internal func doGetNewKeyName(dataType:String)->String {
        let d = Date()
        let df = DateFormatter()
        df.dateFormat = "ssSSSS"
        return "new" + dataType + "Key." + df.string(from: d)
    }


    internal func doGetNewItemName()->String {
        let d = Date()
        let df = DateFormatter()
        //df.dateFormat = "yyyyMMddHHmmssSSSS"
        df.dateFormat = "ssSSSS"
        return "NewItem." + df.string(from: d)
    }
    
    
    // 사용자가 바꾼 값을, keyInfoArray 변수에 반영한다.
    internal func doUpdateNewValueToScankeyArray(selectedRow:Int) {
        if selectedRow < 0 {return}
        let keyType:String = keyInfoArray[keyInfoArraySelectedIndex].keyType
        
        if keyType == RedisDataType.list.rawValue {
            let tableView:NSTableView = tvItem2
            let oldValue:String = keyInfoArray[keyInfoArraySelectedIndex].itemArrayList[selectedRow].value
            let newValue:String = txtItem2Value2.string
            if oldValue != newValue {
                keyInfoArray[keyInfoArraySelectedIndex].itemArrayList[selectedRow].value = newValue
                tableView.reloadData(forRowIndexes: IndexSet(selectedRow...selectedRow), columnIndexes: IndexSet(0..<tableView.tableColumns.count))
            }
        }
        
        if keyType == RedisDataType.hash.rawValue {
            let tableView:NSTableView = tvItem2
            let oldHash:String = keyInfoArray[keyInfoArraySelectedIndex].itemArrayHash[selectedRow].hash
            let oldValue:String = keyInfoArray[keyInfoArraySelectedIndex].itemArrayHash[selectedRow].value
            let newHash:String = txtItem2Value1.stringValue
            let newValue:String = txtItem2Value2.string
            if oldHash != newHash || oldValue != newValue {
                keyInfoArray[keyInfoArraySelectedIndex].itemArrayHash[selectedRow].hash = newHash
                keyInfoArray[keyInfoArraySelectedIndex].itemArrayHash[selectedRow].value = newValue
                tableView.reloadData(forRowIndexes: IndexSet(selectedRow...selectedRow), columnIndexes: IndexSet(0..<tableView.tableColumns.count))
            }
        }
        
        if keyType == RedisDataType.zset.rawValue {
            let tableView:NSTableView = tvItem2
            let oldScore:String = keyInfoArray[keyInfoArraySelectedIndex].itemArrayZset[selectedRow].score
            let oldValue:String = keyInfoArray[keyInfoArraySelectedIndex].itemArrayZset[selectedRow].value
            let newScore:String = txtItem2Value1.stringValue
            let newValue:String = txtItem2Value2.string
            if oldScore != newScore || oldValue != newValue {
                keyInfoArray[keyInfoArraySelectedIndex].itemArrayZset[selectedRow].score = newScore
                keyInfoArray[keyInfoArraySelectedIndex].itemArrayZset[selectedRow].value = newValue
                tableView.reloadData(forRowIndexes: IndexSet(selectedRow...selectedRow), columnIndexes: IndexSet(0..<tableView.tableColumns.count))
            }
        }
        
        if keyType == RedisDataType.set.rawValue {
            let tableView:NSTableView = tvItem1
            let oldValue:String = keyInfoArray[keyInfoArraySelectedIndex].itemArraySet[selectedRow].value
            let newValue:String = txtItem1Value.string
            if oldValue != newValue {
                keyInfoArray[keyInfoArraySelectedIndex].itemArraySet[selectedRow].value = newValue
                tableView.reloadData(forRowIndexes: IndexSet(selectedRow...selectedRow), columnIndexes: IndexSet(0..<tableView.tableColumns.count))
            }
        }
    }
    
    
    // ttl 을 수정했으면, expire 명령어를 보낸다.
    internal func doMakeCommandExpireOrPersist(keyInfo:KeyInfo, newTtl:Int) {
        if keyInfo.valueTtl != newTtl {
            if newTtl == -1 {
                LibRedis.doAdd(.persist(keyInfo: keyInfo, continueOnError: false) { (result:String) in
                    print("persist result [\(result)]")
                })
            } else {
                LibRedis.doAdd(.expire(keyInfo: keyInfo, sec: newTtl, continueOnError: false) { (result:String) in
                    print("expire result [\(result)]")
                })
            }

        }
    }
    
    // keyname 을 수정했으면, renamenx 명령어를 보낸다.
    internal func doMakeCommandRenamenx(keyInfo:KeyInfo, newKeyName:String) {
        if keyInfo.keyName != newKeyName {
            LibRedis.doAdd(.renamenx(keyInfo: keyInfo, newKeyName: newKeyName, continueOnError: false) { (result:String) in
                print("renamenx result [\(result)]")
                let d:Data = newKeyName.data(using: .utf8)!
                self.keyInfoArray[self.keyInfoArraySelectedIndex].keyName = d.map{ $0<32 || $0>127 ? String(format: "\\x%02x", $0) : LibRedis.doViewAsRedisCli($0)}.joined()
                self.keyInfoArray[self.keyInfoArraySelectedIndex].keyNameData = d
                self.keyInfoArray[self.keyInfoArraySelectedIndex].keyNameUtf8 = String(decoding: d, as: UTF8.self).replacingOccurrences(of: "\0", with: "")
            })
        }
    }
    
    
    
    // MARK: - IBAction
    
    @IBAction func doServerManagement(_ sender: NSButton) {
        let storyboardName = NSStoryboard.Name(stringLiteral: "ServerManagement")
        let storyboard = NSStoryboard(name: storyboardName, bundle: nil)
        let storyboardID = NSStoryboard.SceneIdentifier(stringLiteral: "serverManagementStoryboardId")
        guard let serverManagementWindowController = storyboard.instantiateController(withIdentifier: storyboardID) as? NSWindowController else {return}
        guard let serverManagementVC = serverManagementWindowController.contentViewController as? ServerManagementVC else {return}
        serverManagementWindowController.showWindow(nil)
        
        serverManagementVC.closureConnectServer = { (serverInfo:ServerInfo) in
            self.serverInfo = serverInfo
            self.tfServer.stringValue = "connecting..."
            LibRedis.doMakeConnection(libRedises: [self.libRedis],
                                      serverInfo: serverInfo) { (result:Bool, uuid:UUID) in
                // 연결 실패.
                if !result {
                    self.tfServer.stringValue = "CONNECTION FAIL !"
                    return
                }
                
                // 연결 성공.
                self.commandCliV?.libRedisSocket = self.libRedis.libRedisSocket
                self.tfServer.stringValue = serverInfo.host
                self.doInit()
            } closureResultDisconnected: { (uuid:UUID) in
                let msg:String = "The connection has been closed."
                self.keyInfoArray.removeAll()
                self.keyInfoArraySelectedIndex = -1
                self.tfServer.stringValue = msg
                self.doClearKeyInfo()
                self.doClearItemInfo()
                self.tvRedis.reloadData()
                self.tvItem2.reloadData()
                self.tvItem1.reloadData()

                doPerformClosure(withDelay: 0.1) {
                    doAlertShow(message: msg, informativeText: nil, buttons: ["OK"])
                }
            }
        }
    }

    
    @IBAction func doSelectLogicalDb(_ sender: NSPopUpButton) {
        guard let item:NSMenuItem = sender.selectedItem else {return}
        logicalDbNo = item.tag
        LibRedis.doAdd(.select(dbNo: String(logicalDbNo)) { (result:String) in
            if result != "OK" {return}
            self.doScan(nil)
        })
        LibRedis.doSend(libRedisSocket:libRedis.libRedisSocket)
    }
    
    
    
    @IBAction func doScan(_ sender: NSButton?) {
        self.doClearKeyInfo()
        LibRedis.doAdd(.scan(cursorIndex: 0, match: tfScanMatch.stringValue, continueOnError:false) { (returnValue:[String : Any]) in
            let ary:[KeyInfo] = returnValue["scanAry"] as? [KeyInfo] ?? []
            self.keyInfoArray.removeAll()
            self.keyInfoArray.append(contentsOf: ary)
            self.tvRedis.reloadData()
            self.lblKeyCount.stringValue = "\(ary.count) keys"
        })
        LibRedis.doSend(libRedisSocket:libRedis.libRedisSocket)
    }
    
    
    @IBAction func doServerInfo(_ sender: NSButton) {
        LibRedis.doAdd(.info(section: nil, continueOnError:true) { (infos:[(infoKey:String, infoValue:String)]) in
            let storyboardName = NSStoryboard.Name(stringLiteral: "ServerInfo")
            let storyboard = NSStoryboard(name: storyboardName, bundle: nil)
            let storyboardID = NSStoryboard.SceneIdentifier(stringLiteral: "serverInfoStoryboardId")
            if let serverInfoWindowController = storyboard.instantiateController(withIdentifier: storyboardID) as? NSWindowController {
                if let serverInfoVC = serverInfoWindowController.contentViewController as? ServerInfoVC {
                    serverInfoVC.infos = infos
                }
                serverInfoWindowController.showWindow(nil)
            }
        })
        LibRedis.doSend(libRedisSocket:libRedis.libRedisSocket)
    }
    
    
    @IBAction func doPubSub(_ sender: NSButton) {
        guard let serverInfo = self.serverInfo else {
            doPerformClosure(withDelay: 0.1) {
                doAlertShow(message: "NO CONNECTION", informativeText: nil, buttons: ["OK"])
            }
            return
        }
        
        let storyboardName = NSStoryboard.Name(stringLiteral: "PubSub")
        let storyboard = NSStoryboard(name: storyboardName, bundle: nil)
        let storyboardID = NSStoryboard.SceneIdentifier(stringLiteral: "PubSubStoryboardId")
        guard let pubSubWindowController = storyboard.instantiateController(withIdentifier: storyboardID) as? NSWindowController else {return}
        guard let pubSubVC = pubSubWindowController.contentViewController as? PubSubVC else {return}
        pubSubWindowController.showWindow(nil)
        pubSubVC.doInit(serverInfo: serverInfo)
    }
    
    
    @IBAction func doConsole(_ sender: NSButton) {
        let consoleSize:CGFloat = 300.0
        vConsole.isHidden = !vConsole.isHidden

//        let x = (self.view.window?.frame.origin.x)!
//        let y = (self.view.window?.frame.origin.y)!
//        let w = (self.view.window?.frame.size.width)!
//        let h = (self.view.window?.frame.size.height)!
//        let r:NSRect = CGRect(x: x, y: y, width: w + (vConsole.isHidden ? -consoleSize : consoleSize), height: h)
        
        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = 0.5
            context.allowsImplicitAnimation = true
            //self.view.window?.setFrame(r, display: true)
            layoutBgTrailing.constant = (vConsole.isHidden ? 20.0 : consoleSize+40.0)
            self.view.updateConstraints()
            self.view.layoutSubtreeIfNeeded()
        })
    }
    
    
    
    @IBAction func doConsoleClear(_ sender: NSButton) {
        tvConsole.string = ""
    }
    
    
    
    @IBAction func doUTF8KeyName(_ sender: NSButton) {
        self.tvRedis.reloadData(forRowIndexes: IndexSet(0..<keyInfoArray.count), columnIndexes: IndexSet(2...2))
    }
    
    
    @IBAction func doRefreshKey(_ sender: NSButton) {
        self.doScan(nil)
    }
    
    
    @IBAction func doDeleteKey(_ sender: NSButton) {
        if keyInfoArraySelectedIndex < 0 {return}
        let alert = NSAlert()
        alert.messageText = "Delete"
        alert.informativeText = "Are you sure ?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        // not ok
        if alert.runModal() != .alertFirstButtonReturn {return}
        
        let keyInfo:KeyInfo = keyInfoArray[keyInfoArraySelectedIndex]
        LibRedis.doAdd(.del(keyInfo: keyInfo, continueOnError: true) { (result:String) in
            print("del result [\(result)]")
            self.tvRedis.removeRows(at: IndexSet(integer: self.keyInfoArraySelectedIndex), withAnimation: .effectFade)
            self.keyInfoArraySelectedIndex = -1
        })
        LibRedis.doSend(libRedisSocket:libRedis.libRedisSocket)
    }
    
    
    @IBAction func doAddKey(_ sender: NSButton) {
        let alert = NSAlert()
        alert.messageText = "Choose datatype of new key."
        //alert.informativeText = "what kind of key ?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.accessoryView = alertAccessoryV_AddKey
        
        // not ok
        if alert.runModal() != .alertFirstButtonReturn {return}
        let newKeyType:String = alertAccessoryV_AddKey.newKeyType
        let newKeyName:String = doGetNewKeyName(dataType: newKeyType)
        print("new key datatype = [\(alertAccessoryV_AddKey.newKeyType)]")
        if newKeyType.count <= 0 {return}
        
        var newKeyInfo:KeyInfo = KeyInfo()
        newKeyInfo.keyName = newKeyName
        newKeyInfo.keyNameUtf8 = newKeyName
        newKeyInfo.keyNameData = newKeyName.data(using: .utf8)!
        newKeyInfo.keyType = newKeyType
        newKeyInfo.valueTtl = -1
        newKeyInfo.isNew = true
        keyInfoArray.append(newKeyInfo)
        keyInfoArraySelectedIndex = keyInfoArray.count-1
        doShowKeyInfo(keyInfo:newKeyInfo)
        doShowKeyTtl(keyInfo: newKeyInfo)
        
        //tvRedis.beginUpdates()
        tvRedis.insertRows(at: IndexSet(integer: tvRedis.numberOfRows), withAnimation: .effectFade)
        //tvRedis.endUpdates()
        doPerformClosure(withDelay: 0.1) {
            self.tvRedis.selectRowIndexes(IndexSet(self.keyInfoArraySelectedIndex...self.keyInfoArraySelectedIndex), byExtendingSelection: false)
            self.tvRedis.scrollRowToVisible(self.keyInfoArraySelectedIndex)
        }
    }
    
    
    @IBAction func doSaveString(_ sender: NSButton) {
        let keyInfo:KeyInfo = keyInfoArray[keyInfoArraySelectedIndex]
        let newValue = txtKeyInfoValue.string
        let newTtl:Int = -1
        let isNew:Bool = keyInfo.isNew
        
        LibRedis.doAdd(.set(keyInfo: keyInfo, value: newValue, ttl: newTtl, isNew: isNew, continueOnError: true) { (result:String) in
            print("set result [\(result)]")
        })
        self.doMakeCommandExpireOrPersist(keyInfo: keyInfo, newTtl: Int(lblKeyValueTtl.stringValue) ?? -1)
        self.doMakeCommandRenamenx(keyInfo: keyInfo, newKeyName: lblKeyName.stringValue)
        LibRedis.closureCommandFinish = {
            doPerformClosure(withDelay: 0.1) {
                self.keyInfoArray[self.keyInfoArraySelectedIndex].isNew = false
                self.doGetKeyInfo()
            }
        }
        LibRedis.doSend(libRedisSocket:libRedis.libRedisSocket)
    }
    
    
    
    @IBAction func doSaveItem1(_ sender: NSButton) {
        let keyInfo:KeyInfo = keyInfoArray[keyInfoArraySelectedIndex]
        let tvTemp:NSTableView = tvItem1
        self.doUpdateNewValueToScankeyArray(selectedRow: tvTemp.selectedRow)
        
        if keyInfo.keyType == RedisDataType.set.rawValue {
            let currList:[(index:Int, value:String)] = keyInfoArray[keyInfoArraySelectedIndex].itemArraySet
            let currValueList:[String] = currList.map { (index, value) in return value }
            let originList:[(index:Int, value:String)] = keyInfoArray[keyInfoArraySelectedIndex].originItemArraySet
            let originValueList:[String] = originList.map { (index, value) in return value }
            
            for (_, currValue) in currList {
                // 있을때
                if originValueList.firstIndex(of: currValue) != nil {continue}

                // 없을때 (추가되었을때)
                LibRedis.doAdd(.sadd(keyInfo: keyInfo, value: currValue, continueOnError: true) { (result:String) in
                    print("sadd result [\(result)]")
                })
            }
            
            for (_, originValue) in originList {
                if currValueList.firstIndex(of: originValue) != nil {continue}
                
                // 없을때 (삭제되었을때)
                LibRedis.doAdd(.srem(keyInfo: keyInfo, value: originValue, continueOnError: true) { (result:String) in
                    print("srem result [\(result)]")
                })
            }
        }
        
        self.doMakeCommandExpireOrPersist(keyInfo: keyInfo, newTtl: Int(lblKeyValueTtl.stringValue) ?? -1)
        self.doMakeCommandRenamenx(keyInfo: keyInfo, newKeyName: lblKeyName.stringValue)
        LibRedis.closureCommandFinish = {
            doPerformClosure(withDelay: 0.1) {
                self.keyInfoArray[self.keyInfoArraySelectedIndex].isNew = false
                self.doClearItemInfo()
                self.doGetKeyInfo()
            }
        }
        LibRedis.doSend(libRedisSocket:libRedis.libRedisSocket)
    }
    
    
    @IBAction func doAddItem1(_ sender: NSButton) {
        let newKeyName:String = doGetNewItemName()
        let tvTemp = tvItem1!
        keyInfoArray[keyInfoArraySelectedIndex].itemArraySet.append((index:tvTemp.numberOfRows, value:newKeyName))
        let nextSelectedRow:Int = keyInfoArray[keyInfoArraySelectedIndex].itemArraySet.count - 1
        
        tvTemp.reloadData()
        doPerformClosure(withDelay: 0.1) {
            tvTemp.selectRowIndexes(IndexSet(nextSelectedRow...nextSelectedRow), byExtendingSelection: false)
            tvTemp.scrollRowToVisible(nextSelectedRow)
        }
    }
    
    @IBAction func doDeleteItem1(_ sender: NSButton) {
        if keyInfoArraySelectedIndex < 0 {return}
        if tvItem1.selectedRow < 0 {return}
        let nextSelectedRow = tvItem1.selectedRow == 0 ? 0 : tvItem1.selectedRow-1
        keyInfoArray[keyInfoArraySelectedIndex].itemArraySet.remove(at: tvItem1.selectedRow)
        tvItem1.reloadData()
        doPerformClosure(withDelay: 0.1) {
            self.tvItem1.selectRowIndexes(IndexSet(nextSelectedRow...nextSelectedRow), byExtendingSelection: false)
            self.tvItem1.scrollRowToVisible(nextSelectedRow)
        }
    }
    
    @IBAction func doSaveItem2(_ sender: NSButton) {
        let keyInfo:KeyInfo = keyInfoArray[keyInfoArraySelectedIndex]
        let tvTemp:NSTableView = tvItem2
        self.doUpdateNewValueToScankeyArray(selectedRow: tvTemp.selectedRow)
        
        if keyInfo.keyType == RedisDataType.list.rawValue {
            let currList:[(index:Int, value:String)] = keyInfoArray[keyInfoArraySelectedIndex].itemArrayList
            let currIndexList:[Int] = currList.map { (index, value) in return index }
            //let currValueList:[String] = currList.map { (index, value) in return value }
            let originList:[(index:Int, value:String)] = keyInfoArray[keyInfoArraySelectedIndex].originItemArrayList
            let originIndexList:[Int] = originList.map { (index, value) in return index }
            let originValueList:[String] = originList.map { (index, value) in return value }
            
            for (currIndex, currValue) in currList {
                // 있을때
                if let foundIndex:Int = originIndexList.firstIndex(of: currIndex) {
                    // 수정안되었음.
                    if originValueList[foundIndex] == currValue {continue}

                    // 수정되었음.
                    LibRedis.doAdd(.lset(keyInfo: keyInfo, index: foundIndex, value: currValue, continueOnError: true) { (result:String) in
                        print("lset result [\(result)]")
                    })
                }
                // 없을때 (추가되었을때)
                else {
                    LibRedis.doAdd(.rpush(keyInfo: keyInfo, value: currValue, continueOnError: true) { (result:String) in
                        print("rpush result [\(result)]")
                    })
                }
            }
            
            for (originIndex, originValue) in originList {
                if currIndexList.firstIndex(of: originIndex) != nil {continue}

                // 없을때 (삭제되었을때)
                LibRedis.doAdd(.lrem(keyInfo: keyInfo, itemValue: originValue, continueOnError: true) { (result:String) in
                    print("lrem result [\(result)]")
                })
            }
        }
        
        if keyInfo.keyType == RedisDataType.hash.rawValue {
            let currList:[(index:Int, hash:String, value:String)] = keyInfoArray[keyInfoArraySelectedIndex].itemArrayHash
            let currHashList:[String] = currList.map { (index, hash, value) in return hash }
            let originList:[(index:Int, hash:String, value:String)] = keyInfoArray[keyInfoArraySelectedIndex].originItemArrayHash
            let originHashList:[String] = originList.map { (index, hash, value) in return hash }
            let originValueList:[String] = originList.map { (index, hash, value) in return value }
            
            for (_, currHash, currValue) in currList {
                // 있을때
                if let foundIndex:Int = originHashList.firstIndex(of: currHash) {
                    // 수정안되었음.
                    if originValueList[foundIndex] == currValue {continue}
                    
                    // 수정되었음.
                    LibRedis.doAdd(.hset(keyInfo: keyInfo, hash: currHash, value: currValue, continueOnError: true) { (result:String) in
                        print("hset result [\(result)]")
                    })
                }
                // 없을때 (추가되었을때)
                else {
                    // 수정되었음.
                    LibRedis.doAdd(.hset(keyInfo: keyInfo, hash: currHash, value: currValue, continueOnError: true) { (result:String) in
                        print("hset result [\(result)]")
                    })
                }
            }
            
            for (_, originHash, _) in originList {
                if currHashList.firstIndex(of: originHash) != nil {continue}
                
                // 없을때 (삭제되었을때)
                LibRedis.doAdd(.hdel(keyInfo: keyInfo, hash: originHash, continueOnError: true) { (result:String) in
                    print("hdel result [\(result)]")
                })
            }
        }
        
        if keyInfo.keyType == RedisDataType.zset.rawValue {
            let currList:[(index:Int, score:String, value:String)] = keyInfoArray[keyInfoArraySelectedIndex].itemArrayZset
            let currValueList:[String] = currList.map { (index, score, value) in return value }
            //let currScoreList:[String] = currList.map { (index, score, value) in return score }
            let originList:[(index:Int, score:String, value:String)] = keyInfoArray[keyInfoArraySelectedIndex].originItemArrayZset
            let originValueList:[String] = originList.map { (index, score, value) in return value }
            let originScoreList:[String] = originList.map { (index, score, value) in return score }

            for (_, currScore, currValue) in currList {
                // 있을때
                if let foundIndex:Int = originValueList.firstIndex(of: currValue) {
                    // 수정안되었음.
                    if originScoreList[foundIndex] == currScore {continue}

                    // 수정되었음.
                    LibRedis.doAdd(.zadd(keyInfo: keyInfo, score: currScore, value: currValue, continueOnError: true) { (result:String) in
                        print("zadd result [\(result)]")
                    })
                }
                // 없을때 (추가되었을때)
                else {
                    LibRedis.doAdd(.zadd(keyInfo: keyInfo, score: currScore, value: currValue, continueOnError: true) { (result:String) in
                        print("zadd result [\(result)]")
                    })
                }
            }

            for (_, _, originValue) in originList {
                if currValueList.firstIndex(of: originValue) != nil {continue}
                
                // 없을때 (삭제되었을때)
                LibRedis.doAdd(.zrem(keyInfo: keyInfo, value: originValue, continueOnError: true) { (result:String) in
                    print("zrem result [\(result)]")
                })
            }
        }
        
        self.doMakeCommandExpireOrPersist(keyInfo: keyInfo, newTtl: Int(lblKeyValueTtl.stringValue) ?? -1)
        self.doMakeCommandRenamenx(keyInfo: keyInfo, newKeyName: lblKeyName.stringValue)
        LibRedis.closureCommandFinish = {
            doPerformClosure(withDelay: 0.1) {
                self.keyInfoArray[self.keyInfoArraySelectedIndex].isNew = false
                self.doClearItemInfo()
                self.doGetKeyInfo()
            }
        }
        LibRedis.doSend(libRedisSocket:libRedis.libRedisSocket)
    }
    
    @IBAction func doAddItem2(_ sender: NSButton) {
        let keyType:String = keyInfoArray[keyInfoArraySelectedIndex].keyType
        let tvTemp:NSTableView = tvItem2
        self.doUpdateNewValueToScankeyArray(selectedRow: tvTemp.selectedRow)
        
        if keyType == RedisDataType.list.rawValue {
            let lastIndex:Int = (keyInfoArray[keyInfoArraySelectedIndex].itemArrayList.last?.index ?? 0) + 1
            let newKeyName:String = doGetNewItemName()
            keyInfoArray[keyInfoArraySelectedIndex].itemArrayList.append((index:lastIndex, value:newKeyName))
            let nextSelectedRow:Int = keyInfoArray[keyInfoArraySelectedIndex].itemArrayList.count - 1
            
            tvTemp.reloadData()
            doPerformClosure(withDelay: 0.1) {
                tvTemp.selectRowIndexes(IndexSet(nextSelectedRow...nextSelectedRow), byExtendingSelection: false)
                tvTemp.scrollRowToVisible(nextSelectedRow)
            }
        }
        
        if keyType == RedisDataType.hash.rawValue {
            let newKeyName:String = doGetNewItemName()
            keyInfoArray[keyInfoArraySelectedIndex].itemArrayHash.append((index:tvTemp.numberOfRows, hash:newKeyName, value:newKeyName))
            let nextSelectedRow:Int = keyInfoArray[keyInfoArraySelectedIndex].itemArrayHash.count - 1

            tvTemp.reloadData()
            doPerformClosure(withDelay: 0.1) {
                tvTemp.selectRowIndexes(IndexSet(nextSelectedRow...nextSelectedRow), byExtendingSelection: false)
                tvTemp.scrollRowToVisible(nextSelectedRow)
            }
        }
        
        if keyType == RedisDataType.zset.rawValue {
            let newKeyName:String = doGetNewItemName()
            keyInfoArray[keyInfoArraySelectedIndex].itemArrayZset.append((index:tvTemp.numberOfRows, score:"999", value:newKeyName))
            let nextSelectedRow:Int = keyInfoArray[keyInfoArraySelectedIndex].itemArrayZset.count - 1

            tvTemp.reloadData()
            doPerformClosure(withDelay: 0.1) {
                tvTemp.selectRowIndexes(IndexSet(nextSelectedRow...nextSelectedRow), byExtendingSelection: false)
                tvTemp.scrollRowToVisible(nextSelectedRow)
            }
        }
    }
    
    @IBAction func doDeleteItem2(_ sender: NSButton) {
        let keyType:String = keyInfoArray[keyInfoArraySelectedIndex].keyType
        let tvTemp = tvItem2!
        let selctedRow = tvTemp.selectedRow
        if keyInfoArraySelectedIndex < 0 {return}
        if selctedRow < 0 {return}
        
        if keyType == RedisDataType.list.rawValue {
            let nextSelectedRow = selctedRow == 0 ? 0 : selctedRow-1
            keyInfoArray[keyInfoArraySelectedIndex].itemArrayList.remove(at: selctedRow)
            tvTemp.reloadData()
            doPerformClosure(withDelay: 0.1) {
                tvTemp.selectRowIndexes(IndexSet(nextSelectedRow...nextSelectedRow), byExtendingSelection: false)
                tvTemp.scrollRowToVisible(nextSelectedRow)
            }
        }
        
        if keyType == RedisDataType.hash.rawValue {
            let nextSelectedRow = selctedRow == 0 ? 0 : selctedRow-1
            keyInfoArray[keyInfoArraySelectedIndex].itemArrayHash.remove(at: selctedRow)
            tvTemp.reloadData()
            doPerformClosure(withDelay: 0.1) {
                tvTemp.selectRowIndexes(IndexSet(nextSelectedRow...nextSelectedRow), byExtendingSelection: false)
                tvTemp.scrollRowToVisible(nextSelectedRow)
            }
        }
        
        if keyType == RedisDataType.zset.rawValue {
            let nextSelectedRow = selctedRow == 0 ? 0 : selctedRow-1
            keyInfoArray[keyInfoArraySelectedIndex].itemArrayZset.remove(at: selctedRow)
            tvTemp.reloadData()
            doPerformClosure(withDelay: 0.1) {
                tvTemp.selectRowIndexes(IndexSet(nextSelectedRow...nextSelectedRow), byExtendingSelection: false)
                tvTemp.scrollRowToVisible(nextSelectedRow)
            }
        }
    }
    
    
    @IBAction func doKeyspaceNotification(_ sender: NSButton) {
        isKeyspaceNotificationOn = !isKeyspaceNotificationOn
        //doKeyspaceNotificationConnect()
    }
}
