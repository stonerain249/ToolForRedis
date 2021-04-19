//
//  ServerManagement.swift
//  swleeTest
//
//  Created by swlee on 2020/12/24.
//

import Cocoa


struct ServerInfo:Codable {
    var name:String = ""
    var host:String = ""
    var port:String = ""
    var password:String = ""
}


class ServerDeleteCellView:NSTableCellView {
    @IBOutlet weak var btnDelete: NSButton!
}


class ServerConnectCellView:NSTableCellView {
    @IBOutlet weak var btnConnect: NSButton!
}


class ServerManagementVC: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet weak var tvServer: NSTableView!
    @IBOutlet weak var tfName: NSTextField!
    @IBOutlet weak var tfHost: NSTextField!
    @IBOutlet weak var tfPort: NSTextField!
    @IBOutlet weak var tfPassword: NSTextField!
    @IBOutlet weak var btnSave: NSButton!
    
    //public var ownerVC:MainVC?
    public var closureConnectServer:((ServerInfo)->Void)?
    private var serverInfos:[ServerInfo] = []
    private var selectedRow:Int = -1
    private let USERDEFAULT_KEY:String = "REDIS_SEVERS"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear() {
        
        if let d:Data = UserDefaults.standard.data(forKey: USERDEFAULT_KEY) {
            do {
                serverInfos = try JSONDecoder().decode([ServerInfo].self, from: d)
                print(serverInfos)
            } catch {
                print(error)
            }
        }
        
        // 초기화
        if serverInfos.count <= 0 {
            var serverInfo:ServerInfo = ServerInfo()
            serverInfo.name = "127.0.0.1"
            serverInfo.host = "127.0.0.1"
            serverInfo.port = "6379"
            serverInfos.append(serverInfo)
            self.doSaveServersAndReloadTableview()
        }
        
        tvServer.delegate = self
        tvServer.dataSource = self
    }
    
    
    private func doSaveServersAndReloadTableview() {
        let json = try! JSONEncoder().encode(serverInfos)
        UserDefaults.standard.setValue(json, forKey: USERDEFAULT_KEY)
        UserDefaults.standard.synchronize()
        tvServer.reloadData()
    }

    
    // MARK: - IBAction
    
    @IBAction func doSave(_ sender: NSButton) {
        let name:String = tfName.stringValue
        let host:String = tfHost.stringValue
        let port:String = tfPort.stringValue
        let password:String = tfPassword.stringValue

        serverInfos[selectedRow].name = name
        serverInfos[selectedRow].host = host
        serverInfos[selectedRow].port = port
        serverInfos[selectedRow].password = password
        self.doSaveServersAndReloadTableview()
    }
    
    
    @IBAction func doAdd(_ sender: NSButton) {
        let name:String = tfName.stringValue
        let host:String = tfHost.stringValue
        let port:String = tfPort.stringValue
        let password:String = tfPassword.stringValue
        
        var serverInfo:ServerInfo = ServerInfo()
        serverInfo.name = name
        serverInfo.host = host
        serverInfo.port = port
        serverInfo.password = password
        serverInfos.append(serverInfo)
        
        self.doSaveServersAndReloadTableview()
    }
    
    
    @IBAction func doDelete(_ sender: NSButton) {
        print("delete")
        
        let alert = NSAlert()
        alert.messageText = "Delete"
        alert.informativeText = "Are you sure ?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        // not ok
        if alert.runModal() != .alertFirstButtonReturn {return}
        
        serverInfos.remove(at: sender.tag)
        self.doSaveServersAndReloadTableview()
    }
    
    
    @IBAction func doConnect(_ sender: NSButton) {
        print("connect")
        //let name:String = serverInfos[sender.tag].name
        //let host:String = serverInfos[sender.tag].host
        //let port:String = serverInfos[sender.tag].port
        //ownerVC?.doConnectServer(serverInfo: serverInfos[sender.tag])
        closureConnectServer?(serverInfos[sender.tag])
        view.window?.close()
    }
    
    // MARK: - NSTableView
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return serverInfos.count
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 30.0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if tableColumn?.identifier.rawValue == "tvServer.col1" {
            let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "tvServer.col1Cell")
            guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
            cellView.textField?.stringValue = serverInfos[row].name
            return cellView
        }
        
        if tableColumn?.identifier.rawValue == "tvServer.col2" {
            let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "tvServer.col2Cell")
            guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? ServerDeleteCellView else { return nil }
            cellView.btnDelete.tag = row
            return cellView
        }
        
        if tableColumn?.identifier.rawValue == "tvServer.col3" {
            let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "tvServer.col3Cell")
            guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? ServerConnectCellView else { return nil }
            cellView.btnConnect.tag = row
            return cellView
        }
        
        return nil
    }
    
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        print("tableViewSelectionDidChange")
        guard tvServer == notification.object as? NSTableView else {return}
        selectedRow = tvServer.selectedRow
        if selectedRow < 0 {return}
        
        print(serverInfos[selectedRow].name)
        print(serverInfos[selectedRow].host)
        print(serverInfos[selectedRow].port)
        
        let name:String = serverInfos[selectedRow].name
        let host:String = serverInfos[selectedRow].host
        let port:String = serverInfos[selectedRow].port
        let password:String = serverInfos[selectedRow].password
        
        tfName.stringValue = name
        tfHost.stringValue = host
        tfPort.stringValue = port
        tfPassword.stringValue = password
    }
}
