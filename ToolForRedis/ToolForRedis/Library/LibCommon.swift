//
//  LibCommon.swift
//
//  Created by swlee on 17/09/2019.
//  Copyright © 2019 Yanolja. All rights reserved.
//

import Cocoa


//let APP_DELEGATE:AppDelegate = UIApplication.shared.delegate as! AppDelegate
//let LINK_APPSTORE:String = "https://itunes.apple.com/app/id1481433239"

func doPerformClosure(withDelay sec:Double, closure:@escaping ()->Void)
{
    DispatchQueue.main.asyncAfter(
        deadline: .now() + DispatchTimeInterval.milliseconds(Int(sec * 1000)),
        execute: closure
    )
}


func doProgressIndicator(show:Bool) {
//    DispatchQueue.main.async {
//        if show {
//            ViewController.progressIndicator.isHidden = false
//            ViewController.progressIndicator.startAnimation(nil)
//        } else {
//            ViewController.progressIndicator.startAnimation(nil)
//            ViewController.progressIndicator.isHidden = true
//        }
//    }
}



@discardableResult
func doAlertShow(message:String, informativeText:String?, buttons:[String]) -> NSApplication.ModalResponse {
    let alert = NSAlert()
    alert.messageText = message
    if informativeText != nil {alert.informativeText = informativeText!}
    alert.alertStyle = .warning
    for s in buttons {
        alert.addButton(withTitle: s)
    }
    return alert.runModal()
}


/**
 * alert. 버튼 1개 (확인)
 */
//func doShowAlertController1(ownerVc:UIViewController, message:String, handler: @escaping () -> Void)
//{
//    let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
//    alertController.addAction(UIAlertAction(title: "확인", style: .default, handler: { (action) in handler() }))
//    ownerVc.present(alertController, animated: true, completion: nil)
//}


/**
* alert. 버튼 2개 (확인, 취소)
*/
//func doShowAlertController2(ownerVc:UIViewController, message:String, trueButtonTitle:String, falseButtonTitle:String, handler: @escaping (Bool) -> Void)
//{
//    let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
//    alertController.addAction(UIAlertAction(title: trueButtonTitle, style: .default, handler: { (action) in handler(true) }))
//    alertController.addAction(UIAlertAction(title: falseButtonTitle, style: .default, handler: { (action) in handler(false) }))
//    ownerVc.present(alertController, animated: true, completion: nil)
//}


/**
 * 디버그용 print 함수
 */
func doPrint(_ items: Any..., file: String = #file, line: Int = #line, function: String = #function, separator: String = " ", terminator: String = "\n")
{
    #if DEBUG
        let url = URL(fileURLWithPath: file)
        let codeInfo = "[\(url.lastPathComponent) : \(line) | \(function)] :"
        var items = items
        items.insert(codeInfo, at: 0)
        for item in items {
            print(item, terminator: " ")
            //NSLog("swlee_log"+codeInfo+"[\(item)]")
        }
        print("")
    #endif
}




/**
 * xib에서 uiview를 로드한다.
 */
func doLoadViewFromXib<T:NSView>(nibName:String, ownerView:NSView) -> T
{
    var topLevelArray: NSArray?
    Bundle.main.loadNibNamed(NSNib.Name(nibName), owner: ownerView, topLevelObjects: &topLevelArray)
    //guard let results = topLevelArray as? [Any],
    //      let foundedView = results.last(where: {$0 is T}),
          //let view = results.first as? NSView else {fatalError("NIB with name \"\(nibName)\" does not exist.")}
    let views = Array<Any>(topLevelArray!).filter { $0 is T }
    
    let v:T = views.last as! T
    ownerView.addSubview(v)
    v.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate(
        [v.topAnchor.constraint(equalTo: ownerView.topAnchor),
         v.leftAnchor.constraint(equalTo: ownerView.leftAnchor),
         v.rightAnchor.constraint(equalTo: ownerView.rightAnchor),
         v.bottomAnchor.constraint(equalTo: ownerView.bottomAnchor)]
    )
    return v
}



/**
 * view.backgroundColor = doColorGetFromRGB(0x209624)
 */
//func doColorGetFromRGB(rgbValue: UInt) -> UIColor
//{
//    return UIColor(
//        red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
//        green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
//        blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
//        alpha: CGFloat(1.0)
//    )
//}


/**
 * ViewController를 네비게이션컨트롤러에 push 하기
 */
//func doPushViewController(vcNew:UIViewController) -> Void
//{
//    let appDelegate:AppDelegate = UIApplication.shared.delegate as! AppDelegate
//    appDelegate.naviVC.pushViewController(vcNew, animated: true)
//}



/**
 * Push데이타에서 extras 안에 있는 데이타들을 꺼낸다.
 */
//func doGetExtrasInfoFromPush(userInfo:[AnyHashable:Any]) -> (placeId:String, pushboxGroupId:String, redirectUrl:String)
//{
//    var extrasInfo:(placeId:String, pushboxGroupId:String, redirectUrl:String) = ("", "", "")
//
//    extrasInfo.redirectUrl = (userInfo[PushPayloadKey.redirectUrl.rawValue] ?? "") as! String
//
//    if let extras:String = userInfo[PushPayloadKey.extras.rawValue] as? String
//    {
//        let extrasJson:JSON = JSON(parseJSON: extras)
//        extrasInfo.placeId = extrasJson[PushPayloadKey.placeId.rawValue].stringValue
//        extrasInfo.pushboxGroupId = extrasJson[PushPayloadKey.pushboxGroupId.rawValue].stringValue
//        doPrint("--- userInfo.extras FOUND = [\(extrasInfo)]")
//    }
//    else
//    {
//        doPrint("--- userInfo.extras NOT FOUND")
//    }
//
//    return extrasInfo
//}
