//
//  CommandCli.swift
//  RedClient
//
//  Created by swlee on 2021/02/19.
//

import Cocoa

class CommandCliV: NSView,
                   NSTextFieldDelegate,
                   NSControlTextEditingDelegate,
                   NSTableViewDataSource, NSTableViewDelegate,
                   LibHTTPProtocol {

    @IBOutlet weak var vTop: NSView!
    @IBOutlet weak var tvDesc: NSTextView!
    @IBOutlet weak var tfCliGuard: NSTextField!
    @IBOutlet weak var tfCli: NSTextField!
    @IBOutlet weak var tvCli: NSTableView!
    
    // all supported commands
    private let commandAllList:[[String]] = LibRedisCommand.allList.sorted { $0[0] < $1[0] }
    
    // commands for nstableview
    private var commandCurrList:[[String]] = []
    
    private var bIsAwaked:Bool = false
    private let USERDEFAULT_KEY:String = "REDIS_COMMAND_DESC_"
    public var libRedisSocket:LibRedisSocket?
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        print("CommandCliV awakeFromNib")
        if bIsAwaked {return}
        bIsAwaked = true
        vTop.isHidden = true
        tfCli.delegate = self
        tvCli.delegate = self
        tvCli.dataSource = self
    }
    
    
    internal func doGetCommandDesc(mdFileUrl:String) -> Void {
        
        // 이미 받아놓은 명령어설명이 있으면, 바로 보여준다.
        if let desc:String = UserDefaults.standard.string(forKey: USERDEFAULT_KEY + mdFileUrl) {
            self.tvDesc.string = desc
            return
        }
        
        let libHTTP:LibHTTP = LibHTTP(libHTTPProtocol:self, flag:mdFileUrl)
        libHTTP.doHTTP(sURL: "https://raw.githubusercontent.com/redis/redis-doc/master/commands/" + mdFileUrl, dicQueryStr: nil, dicData: nil, method: LibHttpMethod.get)
    }
    

    // MARK: - IBACtion

    @IBAction func doEnter(_ sender: NSTextField) {
        print("enterenterenterenterenterenter")
        if libRedisSocket == nil {return}
        if tfCli.stringValue.count <= 0 {return}
        LibRedis.doAdd(._consoleCommand(command: tfCli.stringValue) { (result:String) in
            print("consoleCommand result -----------------------------")
            print(result)
            self.tfCli.stringValue = ""
            self.vTop.isHidden = true
        })
        LibRedis.doSend(libRedisSocket: libRedisSocket!)
    }


    // MARK: - NSTextFieldDelegate
    
    func controlTextDidChange(_ obj: Notification) {
        guard let tf = obj.object as? NSTextField else {return}
        
        if tf.stringValue.count <= 0 {
            vTop.isHidden = true
            return
        }
        
        vTop.isHidden = false

        // 입력된 텍스트를 스페이스 기준으로 짤라서 배열로 만든다.
        var inputString:[String] = tf.stringValue.components(separatedBy: " ")
        if inputString.last == "" {inputString.removeLast()}
        if inputString.count <= 0 {
            tfCliGuard.placeholderString = ""
            return
        }
        
        commandCurrList = []
        for commandSyntax:[String] in commandAllList {
            let n:Int = min(commandSyntax[0].components(separatedBy: " ").count, inputString.count)
            if !commandSyntax[0].lowercased().starts(with: inputString[0..<n].joined(separator: " ").lowercased()) {continue}
            commandCurrList.append(commandSyntax)
        }
        tvCli.reloadData()
        self.tvCli.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        
        // 전체 명령어가 저장된 배열에서, 입력된 텍스트와 앞부분이 동일한 명령어 하나를 찾아서,
        // placeholderString 배열에 넣는다.
        // 명령어 중에서 중간에 스페이스가 포함된게 있어서, 로직이 좀 지져분해졌다. (config get, pubsub channels...)
        //
        // placeholderString[0] = "auth"
        // placeholderString[0] = "scan"
        // placeholderString[0] = "config get"
        // placeholderString[0] = "pubsub channels"
        // ...
        var placeholderString:[String] = []
        for commandSyntax:[String] in commandAllList {
            let n:Int = min(commandSyntax[0].components(separatedBy: " ").count, inputString.count)
            if !commandSyntax[0].lowercased().starts(with: inputString[0..<n].joined(separator: " ").lowercased()) {continue}
            //placeholderString = commandSyntax
            placeholderString = commandSyntax.dropLast()
            //print("FIND.......... \(placeholderString)")
            break
        }
        if placeholderString.count <= 0 {
            tfCliGuard.placeholderString = ""
            return
        }

        // 입력된 텍스트 배열을 루프돌면서,
        var iii:Int = 0
        for (n, s) in inputString.enumerated() {
            
            // 0번째는,
            // placeholderString[0] 과 inpustString[0] 의 앞부분이 동일하다면,
            // inputString[0] 으로 바꿔준다 (사용자가 입력한 대문사/소문자 그대로 보이도록)
//            if n == 0 {
//                if placeholderString[n].lowercased().starts(with: s.lowercased()) {
//                    placeholderString[n] = placeholderString[n].replacingOccurrences(of: s, with: s, options: .caseInsensitive, range: nil)
//                }
//                continue
//            }
            
            if n < placeholderString[0].components(separatedBy: " ").count {
                let ss:String = inputString[0...n].joined(separator: " ")
                if placeholderString[0].lowercased().starts(with: ss.lowercased()) {
                    placeholderString[0] = placeholderString[0].replacingOccurrences(of: s, with: s, options: .caseInsensitive, range: nil)
                }
                iii = 0
                continue
            }


            iii += 1
            // 1번째 부터는, placeholderString을 입력한 텍스트로 바꿔준다.
            if iii < placeholderString.count {
                placeholderString[iii] = s
            }
        }
        tfCliGuard.placeholderString = placeholderString.joined(separator: " ")
        //print(tfCliGuard.placeholderString!)
    }
    
    

    // MARK: - NSControlTextEditingDelegate
    
    // arrow up/down key event
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if control != tfCli {return false}
        
        let selectedRow:Int = tvCli.selectedRow
        if selectedRow < 0 {return false}
        
        if commandSelector == #selector(moveUp(_:)) {
            print("up...")
            if selectedRow <= 0 {return true}
            self.tvCli.selectRowIndexes(IndexSet(integer: selectedRow-1), byExtendingSelection: false)
            return true
        }
        
        if commandSelector == #selector(moveDown(_:)) {
            print("down...")
            if selectedRow >= self.tvCli.numberOfRows-1 {return true}
            self.tvCli.selectRowIndexes(IndexSet(integer: selectedRow+1), byExtendingSelection: false)
            return true
        }
        
        return false
    }
    
    
    // MARK: - NSTableView
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return commandCurrList.count
    }
    
//    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
//        return 30.0
//    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if tableColumn?.identifier.rawValue == "tvCli.col1" {
            let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "tvCli.col1Cell")
            guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
            cellView.textField?.stringValue = commandCurrList[row][0]
            return cellView
        }
        
//        if tableColumn?.identifier.rawValue == "tvServer.col2" {
//            let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "tvServer.col2Cell")
//            guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? ServerDeleteCellView else { return nil }
//            cellView.btnDelete.tag = row
//            return cellView
//        }
//
//        if tableColumn?.identifier.rawValue == "tvServer.col3" {
//            let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "tvServer.col3Cell")
//            guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? ServerConnectCellView else { return nil }
//            cellView.btnConnect.tag = row
//            return cellView
//        }
        
        return nil
    }
    
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        print("tableViewSelectionDidChange")
        guard tvCli == notification.object as? NSTableView else {return}
        
        let selectedRow:Int = tvCli.selectedRow
        if selectedRow < 0 {return}
        if let mdFileUrl:String = commandCurrList[selectedRow].last {
            print(mdFileUrl)
            self.doGetCommandDesc(mdFileUrl:mdFileUrl)
        }
    }
    
    
    // MARK: - LibHTTPProtocol
    
    func doHTTPDataDidReceive(flag:String?, httpResponseCode:Int, data:Data?) -> Void
    {
        doPrint("------------ LibAPI.doHTTPDataDidReceive")
        if data == nil {return}
        let result:String = String(decoding: data!, as: UTF8.self)
        //print(result)
        self.tvDesc.string = result
        
        if flag != nil {
            UserDefaults.standard.setValue(result, forKey: USERDEFAULT_KEY + flag!)
            UserDefaults.standard.synchronize()
        }

        
        if data == nil || data!.count <= 0
        {
            doPrint("서버에서 받은 데이타가 없습니다. data == nil")
            //closureApiDone(true, "", nil)
            return
        }
    }


    func doHTTPDataDidError(flag:String?, error:Error?, data:Data?) -> Void
    {
        doPrint("------------ LibAPI.doHTTPDataDidError")
        if data == nil {return}
        let result:String = String(decoding: data!, as: UTF8.self)
        print(result)
        self.tvDesc.string = result
    }
}
