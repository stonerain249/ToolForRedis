//
//  PubSubVC.swift
//  RedClient
//
//  Created by swlee on 2021/02/02.
//

import Cocoa

class SubscribeCellView:NSTableCellView {
    @IBOutlet weak var chkSubscribe: NSButton!
    @IBOutlet weak var btnNewCount: NSButton!
}


class PubSubVC: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    @IBOutlet var tvSubscribe: NSTextView!
    @IBOutlet weak var tfMessage: NSTextField!
    @IBOutlet weak var btnPublish: NSButton!
    @IBOutlet weak var lblStatus: NSTextField!
    @IBOutlet weak var tvChannel: NSTableView!
    
    @IBOutlet var alertAccessoryView_NewChannel: AlertAccessoryView_NewChannel!
    
    
    private var libRedisPub:LibRedis = LibRedis()
    private var libRedisSub:LibRedis = LibRedis()
    private var libRedisChannel:LibRedis = LibRedis()
    private var activeChannels:[(channelName:String, isSubscribe:Bool, message:String, newCount:Int)] = []
    private var selectedChannelIndex:Int = -1
    private var timerActiveChannel:Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("PubSubVC.viewDidLoad")
        tvChannel.delegate = self
        tvChannel.dataSource = self
        lblStatus.stringValue = ""
    }
    
    override func viewDidAppear() {
        self.view.window?.title = "Publish/Subscribe"
    }
    
    override func viewDidDisappear() {
        print("PubSubVC.viewDidDisappear")
        timerActiveChannel?.invalidate()
        timerActiveChannel = nil
        
        
        let lastSubscribeChannelName = activeChannels.filter {
            (channelName: String, isSubscribe: Bool, message: String, newCount: Int) -> Bool in
            isSubscribe
        }.last?.channelName

        for (channelName, isSubscribe, _, _) in activeChannels {
            if !isSubscribe {continue}
            LibRedis.doAdd(.unsubscribe(channelName: channelName) { (result:String) in
                print("unsubscribe result [\(result)]")
                if channelName == lastSubscribeChannelName {
                    //self.libRedisPub.libRedisSocket = nil
                    //self.libRedisSub.libRedisSocket = nil
                    //self.libRedisChannel.libRedisSocket = nil
                }
            })
        }
        LibRedis.doSend(libRedisSocket: self.libRedisSub.libRedisSocket)
    }
    
    
    func doInit(serverInfo:ServerInfo) {
        LibRedis.doMakeConnection(libRedises: [libRedisPub, libRedisSub, libRedisChannel],
                                  serverInfo: serverInfo) {[self] (result:Bool, uuid:UUID) in
            // 연결 실패.
            // libRedisPub, libRedisSub, libRedisChannel 중에서 하나라도 연결실패하면 종료.
            if !result {
                var s:String?
                if uuid == libRedisPub.uuid {s = "pub"}
                if uuid == libRedisSub.uuid {s = "sub"}
                if uuid == libRedisChannel.uuid {s = "channel"}
                print(s ?? "" + ".CONNECTION FAIL !")
                doAlertShow(message: "Connection Fail !", informativeText: s, buttons: ["OK"])
                return
            }
            
            // 연결 성공.
            if uuid == libRedisPub.uuid {}
            if uuid == libRedisSub.uuid {}
            if uuid == libRedisChannel.uuid {
                self.doRefreshChannelList()
            }
        } closureResultDisconnected: {[self] (uuid:UUID) in
            var s:String?
            if uuid == libRedisPub.uuid {s = "pub"}
            if uuid == libRedisSub.uuid {s = "sub"}
            if uuid == libRedisChannel.uuid {s = "channel"}
            print(s ?? "" + ".The connection has been closed.")
            doAlertShow(message: "The connection has been closed.", informativeText: s, buttons: ["OK"])
            return
        }
    }
    
    
    // pubsub channels 명령어를 주기적으로 보내서,
    // 활성화된 채널리스트를 받아온다.
    private func doRefreshChannelList() {
        LibRedis.doAdd(.pubsubChannels { (result:[String]) in
            let activeChannelNames:[String] = self.activeChannels.map { (channelName: String, isSubscribe: Bool, message: String, newCount: Int) in return channelName }
            if activeChannelNames == result {return}

            // 새로운 채널은 추가하고.
            let newChannels:[String] = result.filter { (s:String) in !activeChannelNames.contains(s)}
            for c in newChannels {
                self.activeChannels.append((channelName: c, isSubscribe: false, message: "", newCount: 0))
            }

            // 없어진 채널은 삭제하고.
            let deletedChannels:[String] = activeChannelNames.filter { (s:String) in !result.contains(s)}
            for c in deletedChannels {
                self.activeChannels.removeAll { (channelName: String, isSubscribe: Bool, message: String, newCount: Int) in c == channelName }
            }

            doPerformClosure(withDelay: 0.1) {
                if self.selectedChannelIndex >= 0 {
                    self.tvChannel.selectRowIndexes(IndexSet(self.selectedChannelIndex...self.selectedChannelIndex), byExtendingSelection: false)
                    self.tvChannel.scrollRowToVisible(self.selectedChannelIndex)
                }
                self.tvChannel.reloadData()
            }
        })
        LibRedis.doSend(libRedisSocket: self.libRedisChannel.libRedisSocket)
        
//        timerActiveChannel = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { (Timer) in
//            LibRedis.doAdd(.pubsubChannels { (result:[String]) in
//                let activeChannelNames:[String] = self.activeChannels.map { (channelName: String, isSubscribe: Bool, message: String, newCount: Int) in return channelName }
//                if activeChannelNames == result {return}
//
//                // 새로운 채널은 추가하고.
//                let newChannels:[String] = result.filter { (s:String) in !activeChannelNames.contains(s)}
//                for c in newChannels {
//                    self.activeChannels.append((channelName: c, isSubscribe: false, message: "", newCount: 0))
//                }
//
//                // 없어진 채널은 삭제하고.
//                let deletedChannels:[String] = activeChannelNames.filter { (s:String) in !result.contains(s)}
//                for c in deletedChannels {
//                    self.activeChannels.removeAll { (channelName: String, isSubscribe: Bool, message: String, newCount: Int) in c == channelName }
//                }
//
//                doPerformClosure(withDelay: 0.1) {
//                    self.tvChannel.selectRowIndexes(IndexSet(self.selectedChannelIndex...self.selectedChannelIndex), byExtendingSelection: false)
//                    self.tvChannel.scrollRowToVisible(self.selectedChannelIndex)
//                    self.tvChannel.reloadData()
//                }
//            })
//            LibRedis.doSend(libRedisStream: self.libRedisChannel.libRedisStream)
//        }
    }
    

    
    private func doSubscribe(channelName:String) {
        LibRedis.doAdd(.subscribe(channelName: channelName) { [self] (kind:String, channelName:String, message:String) in
            
            var msg:String = ""
            var channelIndex:Int = -1
            for (n, c) in activeChannels.enumerated() {
                if channelName != c.channelName {continue}
                channelIndex = n
                break
            }
            
            // 구독 처음 시작할때.
            if kind == "subscribe" {
                msg = "\(channelName) subscribed.\n"
                activeChannels[channelIndex].isSubscribe = true
                activeChannels[channelIndex].message += msg
                activeChannels[channelIndex].newCount = 1
                doPerformClosure(withDelay: 0.1) {
                    tvChannel.reloadData()
                }
            }
            
            // 메세지를 받았을때.
            if kind == "message" {
                msg = "\(message)\n"
                self.doShowNewMessage(idx: channelIndex, countClear: false, msg: msg)
            }
            
        })
        LibRedis.doSend(libRedisSocket: self.libRedisSub.libRedisSocket)
    }
    
    
    private func doUnsubscribe(unsubscribeChannelName:String) {
        LibRedis.doAdd(.unsubscribe(channelName: unsubscribeChannelName) { (result:String) in
            print("unsubscribe result [\(result)]")
            var unsubscribeChannelIndex = -1
            for (n, c) in self.activeChannels.enumerated() {
                if !c.isSubscribe {continue}
                if unsubscribeChannelName != c.channelName {continue}
                unsubscribeChannelIndex = n
                break
            }
            
            self.activeChannels[unsubscribeChannelIndex].isSubscribe = false
            //self.activeChannels[unsubscribeChannelIndex].message += "\(unsubscribeChannelName) unsubscribed\n"
            let msg:String = "\(unsubscribeChannelName) unsubscribed\n"
            self.doShowNewMessage(idx: unsubscribeChannelIndex, countClear: false, msg: msg)
        })
        LibRedis.doSend(libRedisSocket: self.libRedisSub.libRedisSocket)
    }


    private func doPublish() {
        if selectedChannelIndex < 0 {
            self.lblStatus.stringValue = "Select channel in left channel list to publishing."
            return
        }
        
        let msg:String = tfMessage.stringValue
        let channelName = activeChannels[selectedChannelIndex].channelName
        LibRedis.doAdd(.publish(channelName: channelName, message: msg, closurePublish: { (result:String) in
            self.tfMessage.stringValue = ""
            let subscribeCount = Int(result) ?? 0
            //self.lblStatus.stringValue = "\(subscribeCount) 명에게 메세지 전달됨."
            self.lblStatus.stringValue = "Published to \(subscribeCount) " + (subscribeCount > 1 ? "subscribers." : "subscriber.")
            print("Published to \(subscribeCount) " + (subscribeCount > 1 ? "subscribers." : "subscriber."))
        }))
        LibRedis.doSend(libRedisSocket: self.libRedisPub.libRedisSocket)
    }
    
    
    private func doShowNewMessage(idx:Int, countClear:Bool, msg:String?) {
        if idx < 0 {return}
        if idx >= activeChannels.count {return}
        
        if msg != nil {activeChannels[idx].message += msg!}
        if idx == selectedChannelIndex {
            self.tvSubscribe.string = activeChannels[idx].message
            self.tvSubscribe.scrollToEndOfDocument(self)
        } else {
            activeChannels[idx].newCount += 1
        }
        
        if countClear {activeChannels[idx].newCount = 0}
        self.tvChannel.reloadData(forRowIndexes: IndexSet(idx...idx), columnIndexes: IndexSet(0...0))
    }
    
    
    // MARK: - IBAction
    
    @IBAction func doEnter(_ sender: NSTextField) {
        self.doPublish()
    }
    
    
    @IBAction func doSend(_ sender: NSButton) {
        self.doPublish()
    }
    
    
    @IBAction func doCheckSubscribe(_ sender: NSButton) {
        let channelName:String = activeChannels[sender.tag].channelName
        if sender.state == .on {
            self.doSubscribe(channelName: channelName)
        }
        
        if sender.state == .off {
            self.doUnsubscribe(unsubscribeChannelName: channelName)
        }
    }
    
    
    @IBAction func doAddChannel(_ sender: NSButton) {
        let alert = NSAlert()
        alert.messageText = "New channel name."
        //alert.informativeText = "what kind of key ?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        alert.accessoryView = alertAccessoryView_NewChannel
        
        // not ok
        if alert.runModal() != .alertFirstButtonReturn {return}
        let newChannelName:String = alertAccessoryView_NewChannel.tfNewChannelName.stringValue
        if newChannelName.count <= 0 {return}
        
        activeChannels.append((channelName: newChannelName, isSubscribe: false, message: "", newCount: 0))
        self.doSubscribe(channelName: newChannelName)
    }
    
    
    @IBAction func doRefreshChannel(_ sender: NSButton) {
        self.doRefreshChannelList()
    }
    
    
    
    // MARK: - NSTableview
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return activeChannels.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let channelName:String = activeChannels[row].channelName
        let isSubscribe:Bool = activeChannels[row].isSubscribe
        let newCount:Int = activeChannels[row].newCount
        
        if tableColumn?.identifier.rawValue == "tvChannel.col1" {
            let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "tvChannel.col1Cell")
            guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? SubscribeCellView else { return nil }
            cellView.chkSubscribe.state = (isSubscribe ? .on : .off)
            cellView.chkSubscribe.tag = row
            cellView.btnNewCount.title = String(newCount)
            cellView.btnNewCount.isHidden = newCount <= 0
            return cellView
        }
        
        if tableColumn?.identifier.rawValue == "tvChannel.col2" {
            let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "tvChannel.col2Cell")
            guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
            cellView.textField?.stringValue = channelName
            return cellView
        }

        return nil
    }
    
    
    // NSTableView의 Row 선택이 바뀐 후에 호출됨.
    func tableViewSelectionDidChange(_ notification: Notification) {
        print("tableViewSelectionDidChange")
        if tvChannel == notification.object as? NSTableView {
            selectedChannelIndex = tvChannel.selectedRow
            let channelName:String = activeChannels[selectedChannelIndex].channelName
            self.doShowNewMessage(idx: selectedChannelIndex, countClear: true, msg: nil)
            tfMessage.placeholderString = "publishing to \(channelName)."
        }
    }
    
    
    // NSTableView의 Row 선택이 바뀌기 전에 호출됨.
//    func selectionShouldChange(in tableView: NSTableView) -> Bool {
//        let selectedRow:Int = tableView.selectedRow
//        print("selectionShouldChange.selectedRow: = (\(selectedRow))")
////        if selectedRow < 0 {return true}
////        if tableView != tvItem1 && tableView != tvItem2 {return true}
////        self.doUpdateNewValueToScankeyArray(selectedRow: selectedRow)
//
//        return true
//    }
}
