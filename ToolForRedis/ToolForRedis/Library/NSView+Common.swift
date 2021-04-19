//
//  NSView+Common.swift
//  RedClient
//
//  Created by swlee on 2021/02/08.
//

import Foundation
import Cocoa

extension NSView {
    
    /**
     * 뷰의 모서리를 둥글게 만들어준다
     */
    func doMakeRoundView(cornerRadius cr:CGFloat, borderColor bc:NSColor, borderWidth bw:CGFloat) -> Void
    {
        guard let layer = self.layer else {return}
        layer.masksToBounds = true
        layer.cornerRadius = cr
        layer.borderColor = bc.cgColor
        layer.borderWidth = bw
    }
}
