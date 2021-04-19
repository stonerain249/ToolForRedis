//
//  MainVC+Tableview.swift
//  RedClient
//
//  Created by swlee on 2021/01/12.
//

import Cocoa

extension MainVC: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == tvRedis {
            return keyInfoArray.count
        }

        if tableView == tvItem1 {
            if keyInfoArraySelectedIndex < 0 {return 0}
            return keyInfoArray[keyInfoArraySelectedIndex].itemArraySet.count
        }
        
        if tableView == tvItem2 {
            if keyInfoArraySelectedIndex < 0 {return 0}
            let keyType:String = keyInfoArray[keyInfoArraySelectedIndex].keyType
            if keyType == RedisDataType.list.rawValue {return keyInfoArray[keyInfoArraySelectedIndex].itemArrayList.count}
            if keyType == RedisDataType.hash.rawValue {return keyInfoArray[keyInfoArraySelectedIndex].itemArrayHash.count}
            if keyType == RedisDataType.zset.rawValue {return keyInfoArray[keyInfoArraySelectedIndex].itemArrayZset.count}
        }
        
        return 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        if tableView == tvRedis {
            if tableColumn?.identifier.rawValue == "tvRedis.col1" {
                let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "tvRedis.col1Cell")
                guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
                cellView.textField?.stringValue = keyInfoArray[row].keyType
                return cellView
            }

            if tableColumn?.identifier.rawValue == "tvRedis.col2" {
                let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "tvRedis.col2Cell")
                guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
                cellView.textField?.stringValue = String(keyInfoArray[row].valueSize)
                return cellView
            }
            
            if tableColumn?.identifier.rawValue == "tvRedis.col3" {
                let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "tvRedis.col3Cell")
                guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
                cellView.textField?.stringValue = chkUTF8KeyName.state == .on ? keyInfoArray[row].keyNameUtf8 : keyInfoArray[row].keyName
                return cellView
            }
        }
        
        if tableView == tvItem2 {
            var col1:String = ""
            var col2:String = ""
            let keyType:String = keyInfoArray[keyInfoArraySelectedIndex].keyType
            if keyType == RedisDataType.list.rawValue {
                col1 = String(keyInfoArray[keyInfoArraySelectedIndex].itemArrayList[row].index)
                col2 = keyInfoArray[keyInfoArraySelectedIndex].itemArrayList[row].value
            }
            if keyType == RedisDataType.hash.rawValue {
                col1 = keyInfoArray[keyInfoArraySelectedIndex].itemArrayHash[row].hash
                col2 = keyInfoArray[keyInfoArraySelectedIndex].itemArrayHash[row].value
            }
            if keyType == RedisDataType.zset.rawValue {
                col1 = keyInfoArray[keyInfoArraySelectedIndex].itemArrayZset[row].score
                col2 = keyInfoArray[keyInfoArraySelectedIndex].itemArrayZset[row].value
            }
            
            if tableColumn?.identifier.rawValue == "tvItem2.col1" {
                let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "tvItem2.col1Cell")
                guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
                cellView.textField?.stringValue = col1
                return cellView
            }

            if tableColumn?.identifier.rawValue == "tvItem2.col2" {
                let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "tvItem2.col2Cell")
                guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
                cellView.textField?.stringValue = col2.replacingOccurrences(of: "\n", with: "\\n")
                return cellView
            }
        }
        
        if tableView == tvItem1 {
            if tableColumn?.identifier.rawValue == "tvItem1.col1" {
                let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "tvItem1.col1Cell")
                guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
                cellView.textField?.stringValue = keyInfoArray[keyInfoArraySelectedIndex].itemArraySet[row].value.replacingOccurrences(of: "\n", with: "\\n")
                return cellView
            }
        }

        return nil
    }
    
    
    // NSTableView의 Row 선택이 바뀐 후에 호출됨.
    func tableViewSelectionDidChange(_ notification: Notification) {
        print("tableViewSelectionDidChange")

        if tvRedis == notification.object as? NSTableView {
            let selectedRow:Int = tvRedis.selectedRow
            if selectedRow < 0 {return}
            keyInfoArraySelectedIndex = selectedRow
            self.doClearItemInfo()
            self.doGetKeyInfo()
        }

        if tvItem2 == notification.object as? NSTableView {
            let selectedRow:Int = tvItem2.selectedRow
            print("tableViewSelectionDidChange.selectedRow: = (\(selectedRow))")
            if selectedRow < 0 {return}
            var col1:String = ""
            var col2:String = ""
            let keyType:String = keyInfoArray[keyInfoArraySelectedIndex].keyType
            if keyType == RedisDataType.list.rawValue {
                col1 = String(selectedRow)
                col2 = keyInfoArray[keyInfoArraySelectedIndex].itemArrayList[selectedRow].value
            }
            if keyType == RedisDataType.hash.rawValue {
                col1 = keyInfoArray[keyInfoArraySelectedIndex].itemArrayHash[selectedRow].hash
                col2 = keyInfoArray[keyInfoArraySelectedIndex].itemArrayHash[selectedRow].value
            }
            if keyType == RedisDataType.zset.rawValue {
                col1 = keyInfoArray[keyInfoArraySelectedIndex].itemArrayZset[selectedRow].score
                col2 = keyInfoArray[keyInfoArraySelectedIndex].itemArrayZset[selectedRow].value
            }
            txtItem2Value1.stringValue = col1
            txtItem2Value2.string = col2
        }

        if tvItem1 == notification.object as? NSTableView {
            let selectedRow:Int = tvItem1.selectedRow
            if selectedRow < 0 {return}
            txtItem1Value.string = keyInfoArray[keyInfoArraySelectedIndex].itemArraySet[selectedRow].value
        }
    }
    
    
    // NSTableView의 Row 선택이 바뀌기 전에 호출됨.
    func selectionShouldChange(in tableView: NSTableView) -> Bool {
        let selectedRow:Int = tableView.selectedRow
        print("selectionShouldChange.selectedRow: = (\(selectedRow))")
        if selectedRow < 0 {return true}
        if tableView != tvItem1 && tableView != tvItem2 {return true}
        self.doUpdateNewValueToScankeyArray(selectedRow: selectedRow)
        return true
    }
}
