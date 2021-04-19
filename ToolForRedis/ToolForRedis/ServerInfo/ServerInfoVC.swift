//
//  ServerInfoViewController.swift
//  swleeTest
//
//  Created by swlee on 2020/12/22.
//

import Cocoa

class ServerInfoVC: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet weak var tvServerInfo: NSTableView!
    
    var infos:[(infoKey:String, infoValue:String)] = []

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    override func viewDidAppear() {
        tvServerInfo.delegate = self
        tvServerInfo.dataSource = self
    }


    // MARK: - NSTableView
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return infos.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        if tableColumn?.identifier.rawValue == "tvServerinfo.col1" {
            //print("col1")
            let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "tvServerinfo.col1Cell")
            guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
            cellView.textField?.stringValue = infos[row].infoKey
            
            // section 일때는 노란색으로 표시
            if infos[row].infoKey.hasPrefix("*") {
                cellView.textField?.textColor = .yellow
            } else {
                cellView.textField?.textColor = .controlTextColor
            }
            return cellView
        }

        if tableColumn?.identifier.rawValue == "tvServerinfo.col2" {
            //print("col2")
            let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "tvServerinfo.col2Cell")
            guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
            cellView.textField?.stringValue = infos[row].infoValue
            return cellView
        }

        return nil
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        print("tableViewSelectionDidChange")
        guard tvServerInfo == notification.object as? NSTableView else {return}
        let selectedRow:Int = tvServerInfo.selectedRow
        if selectedRow < 0 {return}
        print(infos[selectedRow].infoValue)
    }
}
