//
//  AlertAccessoryV_AddKey.swift
//  RedClient
//
//  Created by swlee on 2021/01/28.
//

import Cocoa

class AlertAccessoryV_AddKey: NSView {

    var newKeyType:String = ""
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    
    @IBAction func doSetDataType(_ sender: NSButton) {
        newKeyType = sender.title.lowercased()
    }
    
}
