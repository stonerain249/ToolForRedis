//
//  NSButton+Common.swift
//  RedClient
//
//  Created by swlee on 2021/02/16.
//

import Foundation
import Cocoa

extension NSButton {
    
    func doChangeTitleColor(color:NSColor) -> Void {
        let pstyle = NSMutableParagraphStyle()
        pstyle.alignment = .center
        self.attributedTitle = NSAttributedString(string: self.title, attributes: [ NSAttributedString.Key.foregroundColor : color, NSAttributedString.Key.paragraphStyle : pstyle ])
    }
    
}
