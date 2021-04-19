//
//  LibRedis.swift
//  swleeTest
//
//  Created by swlee on 2020/12/17.
//

import Foundation
import Cocoa


let RESPONSE_BUFFER_SIZE:Int = 1024 * 10
//let CRLF:Data = Data([UInt8.REDIS_SEPARATER_CR, UInt8.REDIS_SEPARATER_LF])
let CRLF:String = "\r\n"
let SCAN_COUNT:Int = 1000
//let SCAN_COUNT:Int = 2


// basic
typealias CLOSURE_RESULT_CONNECT = (Bool, UUID)->Void
typealias CLOSURE_RESULT_DISCONNECTED = (UUID)->Void
typealias CLOSURE_RESULT_AUTH = (String)->Void
typealias CLOSURE_RESULT_SELECT = (String)->Void
typealias CLOSURE_RESULT_SCAN = ([String:Any])->Void
typealias CLOSURE_RESULT_TYPE = (String)->Void
typealias CLOSURE_RESULT_TTL = (Int)->Void
typealias CLOSURE_RESULT_EXPIRE = (String)->Void
typealias CLOSURE_RESULT_PERSIST = (String)->Void
typealias CLOSURE_RESULT_INFO = ([(infoKey:String, infoValue:String)])->Void
typealias CLOSURE_RESULT_CONFIG = ([(configKey:String, configValue:String)])->Void
typealias CLOSURE_RESULT_RENAMENX = (String)->Void

// list datatype
typealias CLOSURE_RESULT_LRANGE = ([String:Any])->Void
typealias CLOSURE_RESULT_LSET = (String)->Void
typealias CLOSURE_RESULT_LREM = (String)->Void
typealias CLOSURE_RESULT_RPUSH = (String)->Void

// set datatype
//typealias CLOSURE_RESULT_SMEMBERS = ([String:Any])->Void
typealias CLOSURE_RESULT_SSCAN = ([String:Any])->Void
typealias CLOSURE_RESULT_SADD = (String)->Void
typealias CLOSURE_RESULT_SREM = (String)->Void

// hash datatype
//typealias CLOSURE_RESULT_HGETALL = ([String:Any])->Void
typealias CLOSURE_RESULT_HSCAN = ([String:Any])->Void
typealias CLOSURE_RESULT_HSET = (String)->Void
typealias CLOSURE_RESULT_HDEL = (String)->Void

// zset datatype
typealias CLOSURE_RESULT_ZRANGE = ([String:Any])->Void
typealias CLOSURE_RESULT_ZADD = (String)->Void
typealias CLOSURE_RESULT_ZREM = (String)->Void

// string datatype
typealias CLOSURE_RESULT_GET = (String, String, Int)->Void
typealias CLOSURE_RESULT_SET = (String)->Void


enum RedisDataType:String {
    case string = "string"
    case list = "list"
    case set = "set"
    case zset = "zset"
    case hash = "hash"
    case stream = "stream"
    case none = "none"
}


enum RedisRespType:String {
    case simpleString = "+"
    case bulkString   = "$"
    case integer      = ":"
    case array        = "*"
    case error        = "-"
}

extension UInt8 {
    static let REDIS_SEPARATER_CR = UInt8(ascii: "\r") // 13
    static let REDIS_SEPARATER_LF = UInt8(ascii: "\n") // 10
    static let REDIS_BACKSLASH    = UInt8(ascii: "\\") //
    
    static let REDIS_RESP_SIMPLESTRING = UInt8(ascii: UnicodeScalar(RedisRespType.simpleString.rawValue)!) // + 43
    static let REDIS_RESP_BULKSTRING   = UInt8(ascii: UnicodeScalar(RedisRespType.bulkString.rawValue)!)   // $ 36
    static let REDIS_RESP_INTEGER      = UInt8(ascii: UnicodeScalar(RedisRespType.integer.rawValue)!)      // : 58
    static let REDIS_RESP_ARRAY        = UInt8(ascii: UnicodeScalar(RedisRespType.array.rawValue)!)        // * 42
    static let REDIS_RESP_ERROR        = UInt8(ascii: UnicodeScalar(RedisRespType.error.rawValue)!)        // - 45
    
    static let REDIS_INFO_SECTION = UInt8(ascii: "#") // 35
    
    
    func doGetRespTypeFromUInt8() -> String {
        if self == UInt8.REDIS_RESP_SIMPLESTRING {return RedisRespType.simpleString.rawValue}
        if self == UInt8.REDIS_RESP_BULKSTRING {return RedisRespType.bulkString.rawValue}
        if self == UInt8.REDIS_RESP_INTEGER {return RedisRespType.integer.rawValue}
        if self == UInt8.REDIS_RESP_ARRAY {return RedisRespType.array.rawValue}
        if self == UInt8.REDIS_RESP_ERROR {return RedisRespType.error.rawValue}
        return ""
    }
}


//enum DataStatus {
//    case none
//    case modified
//    case modifiedDeleted
//    case inserted
//    case insertedDeleted
//    case insertedModifyed
//    case insertedModifyedDeleted
//    case deleted
//}


struct KeyInfo {
    var keyName:String = ""
    var keyNameUtf8:String = ""
    var keyNameData:Data = Data()
    var keyType:String = "?"
    var valueSize:Int = 0
    var valueTtl:Int = -1
    var isNew:Bool = false

    // string 타입일때 값.
    var valueString:String = ""
    
    // set 타입일때 아이템을 가지고 있는 배열.
    // value : 중복 불가능.
    var itemArraySet:[(index:Int, value:String)] = []
    var originItemArraySet:[(index:Int, value:String)] = []
    
    // list 타입일때 아이템을 가지고 있는 배열.
    // index : 순번
    // value : 중복 가능.
    var itemArrayList:[(index:Int, value:String)] = []
    var originItemArrayList:[(index:Int, value:String)] = []
    
    // hash 타입일때 아이템을 가지고 있는 배열.
    // hash : 중복 불가능.
    // value : 중복 가능.
    var itemArrayHash:[(index:Int, hash:String, value:String)] = []
    var originItemArrayHash:[(index:Int, hash:String, value:String)] = []
    
    // zset 타입일때 아이템을 가지고 있는 배열.
    // score : 중복 가능. (부동 소수점)
    // value : 중복 불가능.
    var itemArrayZset:[(index:Int, score:String, value:String)] = []
    var originItemArrayZset:[(index:Int, score:String, value:String)] = []
}


class LibRedis : LibRedisProtocol {
    // 레디스명령어들을 담을 배열.
    private static var commandArray:[LibRedisCommand] = []
    
    // 일련의 레디스명령어가 모두 끝났을때, 호출하는 클로저.
    internal static var closureCommandFinish:(()->Void)?
    
    private var arrayCount:Int = 0
//    public var libRedisStream:LibRedisStream!
    public var libRedisSocket:LibRedisSocket!
    
    private var closureResultConnect:CLOSURE_RESULT_CONNECT!
    private var closureResultDisconnected:CLOSURE_RESULT_DISCONNECTED!
    
    
//    private var scanAry:[KeyInfo] = []
//    private var scanMatch:String = ""
//    private var lrangeAry:[String] = []
//    private var lrangeValueSize:Int = 0
//    private var zrangeAry:[(String,String)] = []
//    private var zrangeValueSize:Int = 0
//    private var sscanAry:[String] = []
//    private var sscanValueSize:Int = 0
//    private var hscanAry:[(String,String)] = []
//    private var hscanValueSize:Int = 0
    
    private var host:String = ""
    private var port:Int = -1
    private var password:String = ""
    public var uuid:UUID

    init() {
        self.uuid = UUID()
        self.libRedisSocket = LibRedisSocket(libRedisProtocol:self)
    }


    // MARK: - Connection
    
    static func doMakeConnection(libRedises:[LibRedis],
                                 serverInfo:ServerInfo,
                                 closureResultConnect:@escaping CLOSURE_RESULT_CONNECT,
                                 closureResultDisconnected:@escaping CLOSURE_RESULT_DISCONNECTED) {
        for libRedis:LibRedis in libRedises {
            libRedis.host = serverInfo.host
            libRedis.port = Int(serverInfo.port) ?? 6379
            libRedis.password = serverInfo.password
            
//            libRedis.libRedisStream.inputStream = nil
//            libRedis.libRedisStream.outputStream = nil
//
//            libRedis.closureResultConnect = closureResultConnect
//            libRedis.closureResultDisconnected = closureResultDisconnected
//            Stream.getStreamsToHost(withName: libRedis.host, port: libRedis.port, inputStream: &libRedis.libRedisStream.inputStream, outputStream: &libRedis.libRedisStream.outputStream)
//            libRedis.libRedisStream.inputStream!.delegate = libRedis.libRedisStream
//            libRedis.libRedisStream.outputStream!.delegate = libRedis.libRedisStream
//            libRedis.libRedisStream.inputStream.schedule(in: .current, forMode: .common)
//            libRedis.libRedisStream.outputStream.schedule(in: .current, forMode: .common)
//            libRedis.libRedisStream.inputStream.open()
//            libRedis.libRedisStream.outputStream.open()

//            libRedis.closureResultConnect = closureResultConnect
//            libRedis.closureResultDisconnected = closureResultDisconnected
//            libRedis.libTcp = LibTCP(host: libRedis.host, port: libRedis.port)
            
            
            libRedis.closureResultConnect = closureResultConnect
            libRedis.closureResultDisconnected = closureResultDisconnected
            
            do {
                try libRedis.libRedisSocket.doConnect(host:libRedis.host, port:libRedis.port)
            } catch let error {
                print(error)
            }
        }
    }
    

    internal func doConnectResult(connResult:Bool) {
        if connResult && password.count > 0 {
            doPerformClosure(withDelay: 0.1) {
                LibRedis.doAdd(.auth(password: self.password) { (result:String) in
                    print("auth result...[\(result)]")
                    if result != "OK" {
                        self.closureResultConnect(false, self.uuid)
                        return
                    }
                    self.closureResultConnect(connResult, self.uuid)
                })
                LibRedis.doSend(libRedisSocket:self.libRedisSocket)
            }
            return
        }
        self.closureResultConnect(connResult, self.uuid)
    }
    
    
    public func doDisconnected() {
        
    }
    
    
    
    static func doAdd(_ libRedisCommand:LibRedisCommand) {
        self.commandArray.append(libRedisCommand)
    }
    
    
    
    static func doSend(libRedisSocket:LibRedisSocket) {
        if commandArray.count <= 0 {
            if let closureCommandFinish_ = closureCommandFinish {
                closureCommandFinish_()
                closureCommandFinish = nil
            }
            
            doProgressIndicator(show: false)
            return
        }
        let libRedisCommand:LibRedisCommand = commandArray.removeFirst()
        let commandData:Data = libRedisCommand.doCommand()
        libRedisSocket.doSendData(sendData:commandData, libRedisCommand:libRedisCommand)
    }
    
    
/*
    // MARK: - Parsing. Basic

    public func doParsingResponse_Auth(responseData:inout Data) {
        // 에러 검사
        if self.doCheckErrorResponse(responseData: responseData) {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, nil)
            responseData.removeAll()
            return
        }
        
        let sIndex:Int = responseData.index(after: responseData.startIndex)
        let eIndex:Int = responseData.index(responseData.endIndex, offsetBy: -2)
        let subData:Data = responseData.subdata(in: sIndex..<eIndex)
        let result:String = String(decoding: subData, as: UTF8.self)
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, result)
        responseData.removeAll()
    }
    

    public func doParsingResponse_Select(responseData:inout Data) {
        // 에러 검사
        if self.doCheckErrorResponse(responseData: responseData) {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, nil)
            responseData.removeAll()
            return
        }
        
        let sIndex:Int = responseData.index(after: responseData.startIndex)
        let eIndex:Int = responseData.index(responseData.endIndex, offsetBy: -2)
        let subData:Data = responseData.subdata(in: sIndex..<eIndex)
        let result:String = String(decoding: subData, as: UTF8.self)
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, result)
        responseData.removeAll()
    }
    
    
    public func doParsingResponse_Scan(responseData:inout Data) {
        let d:(oneItemDatas:[Data], valueSize:Int, needMoreData:Bool, nextCursorIndex:Int) = self.doSplitResponseType3(responseData: &responseData)
        if d.needMoreData {return}
        
        for (_, c) in d.oneItemDatas.enumerated() {
            var keyInfo:KeyInfo = KeyInfo()
            let s:String = c.map{ $0<32 || $0>127 ? String(format: "\\x%02x", $0) : LibRedis.doViewAsRedisCli($0)}.joined()

            keyInfo.keyName = s
            keyInfo.keyNameData = c
            keyInfo.keyNameUtf8 = String(decoding: c, as: UTF8.self).replacingOccurrences(of: "\0", with: "")
            scanAry.append(keyInfo)
        }
        
        if d.nextCursorIndex > 0 {
            responseData.removeAll()
            LibRedis.doAdd(.scan(cursorIndex: d.nextCursorIndex, match: LibRedisCommand.scanMatch, continueOnError:false, closureResultScan: nil))
            LibRedis.doSend(self)
            return
        }
        
        let returnValue:[String:Any] = ["cursorIndex":d.nextCursorIndex, "scanAry":scanAry]
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, returnValue)
        scanAry.removeAll()
        responseData.removeAll()
return
        
        
/*
        let onelineDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if onelineDatas.count <= 0 {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(nil)
            return
        }

        var cursorIndex:Int = -1
        var keyCount:Int = 0

        // 서버에서 받아야 할 데이타를 모두 받았는지 검사함.
        // onelineData[0] : *2 // 전체 데이타 구조가 배열 2개로 구성되어 있다는 뜻.
        // onelineData[1] : $3 // 다음 라인에 있는 데이타가 3 character 라는 뜻.
        // onelineData[2] : 123 // 다음 scan시 사용할 cursor index 값.
        // onelineData[3] : *100 // scan 해서 받아온 key 갯수.
        // onelineData[4] : $45 // 다음 라인에 있는 데이타가 45 character 라는 뜻.
        // onelineData[5] : abcdefg... // key name. 45 character.
        // 위의 index 4, 5 가 반복됨.
        var onelineData:Data = onelineDatas[3]
        var subData:Data = onelineData.subdata(in: onelineData.index(after:onelineData.startIndex)..<onelineData.endIndex)
        var tempString:String = String(decoding: subData, as: UTF8.self)
        print("key count = [\(tempString)]")
        keyCount = Int(tempString) ?? 0
        if onelineDatas.count < (keyCount * 2 + 4) {
            print("data receiving...")
            return
        }

        // parsing. start.

        // 다음 scan에 사용할 cursor index 추출.
        onelineData = onelineDatas[2]
        subData = onelineData.subdata(in: onelineData.startIndex..<onelineData.endIndex)
        let s:String = String(decoding: subData, as: UTF8.self)
        cursorIndex = Int(s) ?? -1

        // key 데이타 추출.
        //var libRedis:LibRedis = LibRedis()
        var keyInfo:KeyInfo = KeyInfo()
        for (n, c) in onelineDatas[4..<onelineDatas.endIndex].enumerated() {
            if c.count <= 0 {
                keyInfo = KeyInfo()
                keyInfo.keyName = ""
                keyInfo.keyNameData = c
                scanAry.append(keyInfo)
                continue
            }

            if n.isMultiple(of: 2) {continue}
            keyInfo = KeyInfo()

            // 127 초과하면, 16진수로 바꿔서 표시함.
            // tempString = String(decoding: subData, as: UTF8.self)
            // 그냥 위 문장으로 문자열로 변환하면, 일부 글자가 깨진다.
            // 아마 레디스에 키 생성할때 잘못한거 같음 (\x)
            // 데이타 하나씩 검사해서 ascii 코드 범위(33~127)이면 utf8로 인코딩하고, ascii코드범위를 벗어나면 16진수로 바꿔서 표시함.
            //subData = onelineData.subdata(in: onelineData.startIndex..<onelineData.endIndex)
            ////tempString = subData.map{ $0<32 || $0>127 ? String(format: "\\x%02x", $0) : String(decoding: [$0], as: UTF8.self)}.joined()
            //tempString = String(decoding: subData, as: UTF8.self)
            //tempString = String(decoding: onelineData, as: UTF8.self)
            //tempString = onelineData.reduce("", { $0 + String(format: "%c", $1)})
            //tempString = onelineData.reduce("", {$0 + String(UnicodeScalar($1))})
            //tempString = onelineData.map{ $0<32 || $0>127 ? String(format: "\\x%02x", $0) : String(decoding: [$0], as: UTF8.self)}.joined()
            //tempString = String(decoding: onelineData, as: UTF8.self)
            //tempString = String(data: onelineData, encoding: .utf8) ?? "INVALID UTF-8 CHARACTERS"
            //92
//            let doViewAsRedisCli:(UInt8)->String = { (d:UInt8) in
//                if d == 0 {return #"\x00"#}
//                var s = String(decoding: [d], as: UTF8.self)
//                if s == #"\"# {s = #"\\"#}
//                return s
//            }
            tempString = c.map{ $0<32 || $0>127 ? String(format: "\\x%02x", $0) : doViewAsRedisCli($0)}.joined()

            keyInfo.keyName = tempString
            keyInfo.keyNameData = c
            //keyInfo.keyNameUtf8 = String(data: onelineData, encoding: .utf8) ?? "INVALID UTF-8 CHARACTERS"
            keyInfo.keyNameUtf8 = String(decoding: c, as: UTF8.self).replacingOccurrences(of: "\0", with: "")
            scanAry.append(keyInfo)
        }
        print("parsing end. cursorIndex=[\(cursorIndex)]")

        if cursorIndex > 0 {
            responseData.removeAll()
            LibRedis.doAdd(.scan(cursorIndex: cursorIndex, match: LibRedisCommand.scanMatch, continueOnError:false, closureResultScan: nil))
            LibRedis.doSend()
            return
        }

        let returnValue:[String:Any] = ["cursorIndex":cursorIndex, "scanAry":scanAry]
        self.libRedisStream.libRedisCommand?.doRunResultClosure(returnValue)
        scanAry.removeAll()
        responseData.removeAll()
*/
    }
    
    
    public func doParsingResponse_Type(responseData:inout Data) {
        // 에러 검사
        if self.doCheckErrorResponse(responseData: responseData) {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, nil)
            responseData.removeAll()
            return
        }
        
        let sIndex:Int = responseData.index(after: responseData.startIndex)
        let eIndex:Int = responseData.index(responseData.endIndex, offsetBy: -2)
        let subData:Data = responseData.subdata(in: sIndex..<eIndex)
        let type:String = String(decoding: subData, as: UTF8.self)
        print("******************************* type = (\(type))")
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, type)
        responseData.removeAll()
    }
    
    
    public func doParsingResponse_Ttl(responseData:inout Data) {
        // 에러 검사
        if self.doCheckErrorResponse(responseData: responseData) {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, nil)
            responseData.removeAll()
            return
        }
        
        let sIndex:Int = responseData.index(after: responseData.startIndex)
        let eIndex:Int = responseData.index(responseData.endIndex, offsetBy: -2)
        let subData:Data = responseData.subdata(in: sIndex..<eIndex)
        let s:String = String(decoding: subData, as: UTF8.self)
        let ttl:Int = Int(s) ?? 0
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, ttl)
        responseData.removeAll()
    }
    
    
    // return value : integer
    // 1 : ok. 타임아웃 설정 성공.
    // 0 : fail. 키가 없음.
    public func doParsingResponse_Expire(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, s == ":1" ? s : nil)
        responseData.removeAll()
    }
    

    // return value : integer
    // 1 : ok. 타임아웃 제거 성공.
    // 0 : fail. 키가 없음. 또는 타임아웃이 설정안되어 있는 키.
    // persist 명령어는 리턴값이 1 이던 0 이던, 상관없다.
    public func doParsingResponse_Persist(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, s)
        responseData.removeAll()
    }
    
    
    public func doParsingResponse_Info(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, nil)
            return
        }
        
        var ary:[(String,String)] = []
        let onelineData:Data = oneItemDatas[oneItemDatas.startIndex]
        var subData:Data = onelineData.subdata(in: onelineData.index(after:onelineData.startIndex)..<onelineData.endIndex)
        var tempString:String = String(decoding: subData, as: UTF8.self)
        let dataSize:Int = Int(tempString) ?? 0
        print(dataSize)
        
        for onelineData:Data in oneItemDatas[oneItemDatas.index(after: oneItemDatas.startIndex)..<oneItemDatas.endIndex] {
            if onelineData.count < 2 {continue}
            
            if onelineData[onelineData.startIndex] == UInt8.REDIS_INFO_SECTION {
                subData = onelineData.subdata(in: onelineData.index(after:onelineData.startIndex)..<onelineData.endIndex)
                tempString = String(decoding: subData, as: UTF8.self)
                ary.append(("*" + tempString, ""))
                continue
            }
            
            let info:[Data] = onelineData.split(separator: UInt8.REDIS_RESP_INTEGER)
            let infoKey = String(decoding: info[info.startIndex], as: UTF8.self)
            let infoValue = String(decoding: info[info.index(before: info.endIndex)], as: UTF8.self)
            print(infoKey + ": [" + infoValue + "]")
            ary.append((infoKey, infoValue))
        }
        
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, ary)
        responseData.removeAll()
    }
    
    
    public func doParsingResponse_ConfigGet(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, nil)
            return
        }
        
        var ary:[(String,String)] = []
        let onelineData:Data = oneItemDatas[oneItemDatas.startIndex]
        var subData:Data = onelineData.subdata(in: onelineData.index(after:onelineData.startIndex)..<onelineData.endIndex)
        var tempString:String = String(decoding: subData, as: UTF8.self)
        let dataSize:Int = Int(tempString) ?? 0
        print(dataSize)
        
        for onelineData:Data in oneItemDatas[oneItemDatas.index(after: oneItemDatas.startIndex)..<oneItemDatas.endIndex] {
            if onelineData.count < 2 {continue}
            
            if onelineData[onelineData.startIndex] == UInt8.REDIS_INFO_SECTION {
                subData = onelineData.subdata(in: onelineData.index(after:onelineData.startIndex)..<onelineData.endIndex)
                tempString = String(decoding: subData, as: UTF8.self)
                ary.append(("*" + tempString, ""))
                continue
            }
            
            let info:[Data] = onelineData.split(separator: UInt8.REDIS_RESP_INTEGER)
            let infoKey = String(decoding: info[info.startIndex], as: UTF8.self)
            let infoValue = String(decoding: info[info.index(before: info.endIndex)], as: UTF8.self)
            print(infoKey + ": [" + infoValue + "]")
            ary.append((infoKey, infoValue))
        }
        
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, ary)
        responseData.removeAll()
    }


    public func doParsingResponse_ConfigSet(responseData:inout Data) {
        // 에러 검사
        if self.doCheckErrorResponse(responseData: responseData) {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, nil)
            responseData.removeAll()
            return
        }
        
        let sIndex:Int = responseData.index(after: responseData.startIndex)
        let eIndex:Int = responseData.index(responseData.endIndex, offsetBy: -2)
        let subData:Data = responseData.subdata(in: sIndex..<eIndex)
        let result:String = String(decoding: subData, as: UTF8.self)
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, result)
        responseData.removeAll()
    }


    // return value : integer
    // 1 : ok. 이름변경 성공.
    // 0 : fail. 새로운키 이름이 이미 있음.
    public func doParsingResponse_Renamenx(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, s == ":1" ? s : nil)
        responseData.removeAll()
    }

    
    // return value : integer
    // 삭제된 키 갯수
    public func doParsingResponse_Del(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, s)
        responseData.removeAll()
    }
    
    
    
    // MARK: - Parsing. String
    
    public func doParsingResponse_Get(responseData:inout Data) {
        let d:(oneItemDatas:[Data], valueSize:Int, needMoreData:Bool) = self.doSplitResponseType2(responseData: &responseData)
        if d.needMoreData {return}
        if d.oneItemDatas.count <= 0 {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, nil)
            return
        }
  
        var keyInfo:(valueType:String, value:String, valueSize:Int) = ("", "", d.valueSize)
        keyInfo.value = String(decoding: d.oneItemDatas[d.oneItemDatas.startIndex], as: UTF8.self)
        
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, keyInfo.valueType, keyInfo.value, keyInfo.valueSize)
        responseData.removeAll()
    }
    
    
    public func doParsingResponse_Set(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, s == "+OK" ? s : nil)
        responseData.removeAll()
    }
    

    // MARK: - Parsing. List
    
    public func doParsingResponse_Lrange(responseData:inout Data) {
        let d:(oneItemDatas:[Data], valueSize:Int, needMoreData:Bool) = self.doSplitResponseType2(responseData: &responseData)
        if d.needMoreData {return}
        var ary:[String] = []

        for (_, c) in d.oneItemDatas.enumerated() {
            let s:String = String(decoding: c, as: UTF8.self)
            ary.append(s)
        }
        lrangeAry.append(contentsOf: ary)
        lrangeValueSize += d.valueSize

        if ary.count > SCAN_COUNT {
            responseData.removeAll()
            LibRedis.doAdd(.lrange(keyInfo: LibRedisCommand.lrangeKeyInfo,
                                          startOffset: LibRedisCommand.lrangeStartOffset+SCAN_COUNT+1,
                                          continueOnError: true,
                                          closureResultLrange: nil))
            LibRedis.doSend(self)
            return
        }

        let returnValue:[String:Any] = ["valueSize":lrangeValueSize, "itemAry":lrangeAry]
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, returnValue)
        lrangeAry.removeAll()
        lrangeValueSize = 0
        responseData.removeAll()
    }
    
    
    public func doParsingResponse_Lset(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, s == "+OK" ? s : nil)
        responseData.removeAll()
    }
    

    public func doParsingResponse_Rpush(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        //self.libRedisStream.libRedisCommand?.doRunResultClosure(s == ":0" ? s : nil)
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, s)
        responseData.removeAll()
    }
    
    
    public func doParsingResponse_Lrem(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, s == ":0" ? s : nil)
        responseData.removeAll()
    }
    
    

    // MARK: - Parsing. Set
    
    public func doParsingResponse_Smembers(responseData:inout Data) {
        let d:(oneItemDatas:[Data], valueSize:Int, needMoreData:Bool) = self.doSplitResponseType2(responseData: &responseData)
        if d.needMoreData {return}
        var ary:[String] = []
        
        for (_, c) in d.oneItemDatas.enumerated() {
            let s:String = String(decoding: c, as: UTF8.self)
            ary.append(s)
        }
        let returnValue:[String:Any] = ["valueSize":d.valueSize, "itemAry":ary]
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, returnValue)
        responseData.removeAll()
    }


    public func doParsingResponse_Sscan(responseData:inout Data) {
        let d:(oneItemDatas:[Data], valueSize:Int, needMoreData:Bool, nextCursorIndex:Int) = self.doSplitResponseType3(responseData: &responseData)
        if d.needMoreData {return}
        
        for (_, c) in d.oneItemDatas.enumerated() {
            let s:String = String(decoding: c, as: UTF8.self)
            sscanAry.append(s)
        }
        
        if d.nextCursorIndex > 0 {
            responseData.removeAll()
            LibRedis.doAdd(.sscan(keyInfo: LibRedisCommand.sscanKeyInfo, cursorIndex: d.nextCursorIndex, continueOnError: false, closureResultSscan: nil))
            LibRedis.doSend(self)
            return
        }
        
        let returnValue:[String:Any] = ["cursorIndex":d.nextCursorIndex, "itemAry":sscanAry]
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, returnValue)
        sscanAry.removeAll()
        responseData.removeAll()
    }
    
    
    // return value : integer
    // 추가된 아이템갯수
    public func doParsingResponse_Sadd(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, s)
        responseData.removeAll()
    }

    
    // return value : integer
    // 삭제된 아이템갯수
    public func doParsingResponse_Srem(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, s)
        responseData.removeAll()
    }
    
    
    // MARK: - Parsing. Hash
    
    public func doParsingResponse_Hgetall(responseData:inout Data) {
        let d:(oneItemDatas:[Data], valueSize:Int, needMoreData:Bool) = self.doSplitResponseType2(responseData: &responseData)
        if d.needMoreData {return}
        var ary:[(String,String)] = []
        var keyName:String = ""
        var keyValue:String = ""
        
        for (n, c) in d.oneItemDatas.enumerated() {
            let s:String = String(decoding: c, as: UTF8.self)
            if n.isMultiple(of: 2) {
                keyName = s
                continue
            }
            
            keyValue = s
            ary.append((keyName, keyValue))
            keyName = ""
            keyValue = ""
        }
        let returnValue:[String:Any] = ["valueSize":d.valueSize, "itemAry":ary]
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, returnValue)
        responseData.removeAll()
    }
    
    
    public func doParsingResponse_Hscan(responseData:inout Data) {
        let d:(oneItemDatas:[Data], valueSize:Int, needMoreData:Bool, nextCursorIndex:Int) = self.doSplitResponseType3(responseData: &responseData)
        if d.needMoreData {return}
        var keyName:String = ""
        var keyValue:String = ""
        
        for (n, c) in d.oneItemDatas.enumerated() {
            let s:String = String(decoding: c, as: UTF8.self)
            if n.isMultiple(of: 2) {
                keyName = s
                continue
            }
            
            keyValue = s
            hscanAry.append((keyName, keyValue))
            keyName = ""
            keyValue = ""
        }
        
        if d.nextCursorIndex > 0 {
            responseData.removeAll()
            LibRedis.doAdd(.hscan(keyInfo: LibRedisCommand.hscanKeyInfo, cursorIndex: d.nextCursorIndex, continueOnError: false, closureResultHscan: nil))
            LibRedis.doSend(self)
            return
        }
        
        let returnValue:[String:Any] = ["valueSize":d.valueSize, "itemAry":hscanAry]
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, returnValue)
        hscanAry.removeAll()
        responseData.removeAll()
    }
    
    // return value : integer
    // 추가된 아이템갯수
    public func doParsingResponse_Hset(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, s)
        responseData.removeAll()
    }
    
    // return value : integer
    // 삭제된 아이템갯수
    public func doParsingResponse_Hdel(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, s)
        responseData.removeAll()
    }
    
    
    // MARK: - Parsing. Zset
    
    public func doParsingResponse_Zrange(responseData:inout Data) {
        let d:(oneItemDatas:[Data], valueSize:Int, needMoreData:Bool) = self.doSplitResponseType2(responseData: &responseData)
        if d.needMoreData {return}
        var ary:[(String,String)] = []
        var keyScore:String = ""
        var keyValue:String = ""
        
        for (n, c) in d.oneItemDatas.enumerated() {
            let s:String = String(decoding: c, as: UTF8.self)
            if n.isMultiple(of: 2) {
                keyValue = s
                continue
            }
            
            keyScore = String(format:"%.3f", round((Double(s) ?? 0.0) * 1000) / 1000) //s
            ary.append((keyScore, keyValue))
            keyScore = ""
            keyValue = ""
        }
        zrangeAry.append(contentsOf: ary)
        zrangeValueSize += d.valueSize
        
        if ary.count > SCAN_COUNT {
            responseData.removeAll()
            LibRedis.doAdd(.zrange(keyInfo: LibRedisCommand.zrangeKeyInfo,
                                          startOffset: LibRedisCommand.zrangeStartOffset+SCAN_COUNT+1,
                                          continueOnError: true,
                                          closureResultZrange: nil))
            LibRedis.doSend(self)
            return
        }
        
        let returnValue:[String:Any] = ["valueSize":zrangeValueSize, "itemAry":zrangeAry]
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, returnValue)
        zrangeAry.removeAll()
        zrangeValueSize = 0
        responseData.removeAll()
    }
    
    
    // return value : integer
    // 추가된 아이템갯수
    public func doParsingResponse_Zadd(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, s)
        responseData.removeAll()
    }
    

    // return value : integer
    // 삭제된 아이템갯수
    public func doParsingResponse_Zrem(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, s)
        responseData.removeAll()
    }
    
    
    // MARK: - Pub/Sub
    
    public func doParsingResponse_PubSubChannels(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 2 {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, nil)
            return
        }
        
        var activeChannelArray:[String] = []
        for (_, c) in oneItemDatas.enumerated() {
            print(String(decoding: c, as: UTF8.self))
            if c.first == UInt8.REDIS_RESP_ARRAY {continue}
            if c.first == UInt8.REDIS_RESP_BULKSTRING {continue}
            let s:String = String(decoding: c, as: UTF8.self)
            //print(s)
            activeChannelArray.append(s)
        }
        
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, activeChannelArray)
        responseData.removeAll()
    }
    
    
    /*
     subscribe test
     *3
     $9
     subscribe
     $4
     test
     :1
     
     
     *3
     $7
     message
     $4
     test
     $22
     aaaaabbbbbbbbbbbbbbbbb
     */
    public func doParsingResponse_Subscribe(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        //let ss:String = String(decoding: responseData, as: UTF8.self)
        //print("----------------------------------SUB.Warning....................")
        //print(ss)

        if oneItemDatas.count <= 3 {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, nil)
            return
        }

        let kind:String = String(decoding: oneItemDatas[2], as: UTF8.self)
        let channelName:String = String(decoding: oneItemDatas[4], as: UTF8.self)
        
        // subscribe 명령을 실행했을때.
        if kind == "subscribe" {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, (kind, channelName, ""))
            responseData.removeAll()
            return
        }

        // subscribe 메세지를 받았을때.
        if kind == "message" {
            let s:String = String(decoding: oneItemDatas.last!, as: UTF8.self)
            print("----------------------------------SUB")
            print(channelName + ":" + s)
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, (kind, channelName, s))
            responseData.removeAll()
            return
        }

        // psubscribe 명령을 실행했을때.
        if kind == "psubscribe" {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, [(kind, channelName, "", "")])
            responseData.removeAll()
            return
        }
        
        // psubscribe 메세지를 받았을때.
        if kind == "pmessage" {
            var keyName:String = String(decoding: oneItemDatas[6], as: UTF8.self)
            var cmd:String = String(decoding: oneItemDatas[8], as: UTF8.self)
            var pmsgInfo:[(kind:String, channelName:String, keyName:String, cmd:String)] = []
            pmsgInfo.append((kind: kind, channelName: channelName, keyName: keyName, cmd: cmd))
            if oneItemDatas.count >= 18 {
                keyName = String(decoding: oneItemDatas[15], as: UTF8.self)
                cmd = String(decoding: oneItemDatas[17], as: UTF8.self)
                pmsgInfo.append((kind: kind, channelName: channelName, keyName: keyName, cmd: cmd))
            }
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, pmsgInfo)
            responseData.removeAll()
            return
        }
        
        // 이게 실행되면 이상한건데...
        let s:String = String(decoding: responseData, as: UTF8.self)
        print("----------------------------------SUB.Warning...")
        print(s)
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, ("", "", ""))
        responseData.removeAll()
    }
    
    
    public func doParsingResponse_Unsubscribe(responseData:inout Data) {
        let s:String = String(decoding: responseData, as: UTF8.self)
        //print("----------------------------------UNSUB")
        //print(s)
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, s)
        responseData.removeAll()
    }
    
    
    public func doParsingResponse_Publish(responseData:inout Data) {
        var s:String = String(decoding: responseData, as: UTF8.self)
        print("----------------------------------PUB")
        print("[\(s)]")
        
        if responseData.first == UInt8.REDIS_RESP_INTEGER {
            let _ = responseData.popFirst()
            let _ = responseData.popLast()
            let _ = responseData.popLast()
            s = String(decoding: responseData, as: UTF8.self)
            print("[\(s)]")
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, s)
        }
        else {
            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, nil)
        }
        
        responseData.removeAll()
    }
    
    
    // MARK: - Console Command
    
    public func doParsingResponse_ConsoleCommand(responseData:inout Data) {
        let s:String = String(decoding: responseData, as: UTF8.self)
        print("----------------------------------ConsoleCommand")
        print("[\(s)]")
        self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, s)
        //case _consoleCommand(command:String, closureConsoleCommand:(String)->Void)
        
//        if responseData.first == UInt8.REDIS_RESP_INTEGER {
//            let _ = responseData.popFirst()
//            let _ = responseData.popLast()
//            let _ = responseData.popLast()
//            s = String(decoding: responseData, as: UTF8.self)
//            print("[\(s)]")
//            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, s)
//        }
//        else {
//            self.libRedisStream.libRedisCommand?.doRunResultClosure(libRedisStream:libRedisStream, nil)
//        }
        
        responseData.removeAll()
    }
    
    // MARK: - Response Data에 대한 기본 파싱


    /**
     응답을 한 라인 씩 분리한다. (\r\n)
     info
     config
     */
    private func doSplitResponseType1(responseData:inout Data)->[Data] {
        // 에러 검사
        if self.doCheckErrorResponse(responseData: responseData) {
            //self.libRedisStream.libRedisCommand?.doRunResultClosure(nil)
            responseData.removeAll()
            return []
        }
        
        // 작업실패 검사
        if self.doCheckFailResponse(responseData: responseData) {
            //self.libRedisStream.libRedisCommand?.doRunResultClosure(nil)
            responseData.removeAll()
            return []
        }
        
        // 먼저 서버에서 받은 데이타를 \n 으로 짤라서 배열로 만든다.
        var oneItemDatas:[Data] = responseData.split(separator: UInt8.REDIS_SEPARATER_LF)

        // 위에 \n 으로 짤랐으니까, 제일뒤에 붙어 있는 \r 을 제거한다.
        var i:Int = 0
        while i < oneItemDatas.count {
            if oneItemDatas[i][oneItemDatas[i].index(before: oneItemDatas[i].endIndex)] == UInt8.REDIS_SEPARATER_CR {
                oneItemDatas[i].remove(at: oneItemDatas[i].index(before: oneItemDatas[i].endIndex))
            }
            i += 1
        }
        return oneItemDatas
    }
    
    
    /**
     응답을 한 아이템 씩 분리한다. (아이템의 길이 만큼 분리)
     lrange
     smembers
     hgetall
     zrange
     */
    private func doSplitResponseType2(responseData:inout Data)->(oneItemDatas:[Data], valueSize:Int, needMoreData:Bool) {
        // 에러 검사
        if self.doCheckErrorResponse(responseData: responseData) {
            //self.libRedisStream.libRedisCommand?.doRunResultClosure(nil)
            responseData.removeAll()
            return ([], 0, true)
        }

        // 작업실패 검사
        if self.doCheckFailResponse(responseData: responseData) {
            //self.libRedisStream.libRedisCommand?.doRunResultClosure(nil)
            responseData.removeAll()
            return ([], 0, true)
        }
        
        //var copyedData:Data = Data(responseData)
        var oneItemDatas:[Data] = []
        var valueSize:Int = 0
        var itemCount:Int = 0
        var needDataSize:Int = 0
        
        // 서버에서 받아야 할 데이타를 모두 받았는지 검사함.1
        if responseData[responseData.startIndex] == UInt8.REDIS_RESP_ARRAY {
            guard let r:Range<Data.Index> = responseData.range(of: Data([UInt8.REDIS_SEPARATER_CR]), options: [], in: responseData.startIndex..<responseData.endIndex) else {return ([], 0, true)}
            let s:String = String(decoding: responseData.subdata(in: responseData.index(after: responseData.startIndex)..<r.index(before: r.endIndex)), as: UTF8.self)
            print("item count = [\(s)]")
            itemCount = Int(s) ?? 0
            needDataSize += s.count + 3 // *, CR, LF
            //print("needDataSize=[\(needDataSize)]")
        }

        // 서버에서 받아야 할 데이타를 모두 받았는지 검사함.2
        var sIndex:Data.Index = responseData.startIndex
        while true {
            if sIndex > responseData.count {break}
            guard let r1:Range<Data.Index> = responseData.range(of: Data([UInt8.REDIS_RESP_BULKSTRING]), options: [], in: sIndex..<responseData.endIndex) else {break}
            guard let r2:Range<Data.Index> = responseData.range(of: Data([UInt8.REDIS_SEPARATER_CR]), options: [], in: r1.endIndex..<responseData.endIndex) else {break}
            let s:String = String(decoding: responseData.subdata(in: r1.endIndex..<r2.startIndex), as: UTF8.self)
            let bytes:Int = Int(s) ?? 0
            valueSize += bytes
            sIndex = r2.endIndex + bytes
            
            needDataSize += s.count + 3 // $, CR, LF
            needDataSize += bytes + 2
            
            // $-1 : 값없음
            if bytes < 0 {needDataSize = 0}
            //print("needDataSize=[\(needDataSize)]")
        }
        
        // 필요한데이타양 > 서버에서받은데이타양 : 그냥 리턴
        print("needDataSize=[\(needDataSize)] realSize=[\(responseData.count)]")
        if needDataSize > responseData.count {return ([], 0, true)}
        
        while responseData.count > 0 {
            guard let r1:Range<Data.Index> = responseData.range(of: Data([UInt8.REDIS_RESP_BULKSTRING])) else {break}
            guard let r2:Range<Data.Index> = responseData.range(of: Data([UInt8.REDIS_SEPARATER_CR]), options: [], in: r1.endIndex..<responseData.endIndex) else {break}
            let s:String = String(decoding: responseData.subdata(in: r1.endIndex..<r2.startIndex), as: UTF8.self)
            let bytes:Int = Int(s) ?? 0

            let sIndex:Int = responseData.index(after: r2.endIndex)
            if responseData.count < sIndex+bytes {return ([], 0, true)}
            let eIndex:Int = responseData.index(sIndex, offsetBy: bytes)
            let subData:Data = responseData.subdata(in: sIndex..<eIndex)
            oneItemDatas.append(subData)
            responseData.removeSubrange(responseData.startIndex..<responseData.index(eIndex, offsetBy: 2))

            //let ss:String = String(decoding: subData, as: UTF8.self)
            //print("-----------------------------------------")
            //print("[\(ss)]")
        }
        
        if itemCount > oneItemDatas.count {return ([], 0, true)}
        responseData.removeAll()
        return (oneItemDatas, valueSize, false)
    }
    
    
    /**
     응답을 한 아이템 씩 분리한다. (아이템의 길이 만큼 분리)
     scan
     sscan
     */
    private func doSplitResponseType3(responseData:inout Data)->(oneItemDatas:[Data], valueSize:Int, needMoreData:Bool, nextCursorIndex:Int) {
        var returnValue:([Data], Int, Bool, Int) = ([], 0, true, -1)

        // 에러 검사
        if self.doCheckErrorResponse(responseData: responseData) {
            //self.libRedisStream.libRedisCommand?.doRunResultClosure(nil)
            responseData.removeAll()
            return returnValue
        }

        // 작업실패 검사
        if self.doCheckFailResponse(responseData: responseData) {
            //self.libRedisStream.libRedisCommand?.doRunResultClosure(nil)
            responseData.removeAll()
            return returnValue
        }
        
        var oneItemDatas:[Data] = []
        var valueSize:Int = 0
        var itemCount:Int = 0
        var needDataSize:Int = 0
        var nextCursorIndex:Int = -1
        var keyDataStartIndex:Data.Index = 0
        
        // 서버에서 받아야 할 데이타를 모두 받았는지 검사함.1
        if responseData[responseData.startIndex] == UInt8.REDIS_RESP_ARRAY {
            guard let r1:Range<Data.Index> = responseData.range(of: Data([UInt8.REDIS_SEPARATER_CR]), options: [], in: responseData.startIndex..<responseData.endIndex) else {return returnValue}
            var s:String = String(decoding: responseData.subdata(in: responseData.index(after: responseData.startIndex)..<r1.index(before: r1.endIndex)), as: UTF8.self)
            needDataSize += s.count + 3 // *, CR, LF
            
            guard let r2:Range<Data.Index> = responseData.range(of: Data([UInt8.REDIS_SEPARATER_CR]), options: [], in: responseData.index(after: r1.endIndex)..<responseData.endIndex) else {return returnValue}
            s = String(decoding: responseData.subdata(in: responseData.index(r1.endIndex, offsetBy: 2)..<r2.index(before: r2.endIndex)), as: UTF8.self)
            needDataSize += s.count + 3 // $, CR, LF
            
            guard let r3:Range<Data.Index> = responseData.range(of: Data([UInt8.REDIS_SEPARATER_CR]), options: [], in: responseData.index(after: r2.endIndex)..<responseData.endIndex) else {return returnValue}
            s = String(decoding: responseData.subdata(in: responseData.index(r2.endIndex, offsetBy: 1)..<r3.index(before: r3.endIndex)), as: UTF8.self)
            nextCursorIndex = Int(s) ?? 0
            needDataSize += s.count + 2 // CR, LF
            
            guard let r4:Range<Data.Index> = responseData.range(of: Data([UInt8.REDIS_SEPARATER_CR]), options: [], in: responseData.index(after: r3.endIndex)..<responseData.endIndex) else {return returnValue}
            s = String(decoding: responseData.subdata(in: responseData.index(r3.endIndex, offsetBy: 2)..<r4.index(before: r4.endIndex)), as: UTF8.self)
            itemCount = Int(s) ?? 0
            needDataSize += s.count + 3 // *, CR, LF
            keyDataStartIndex = responseData.index(r4.endIndex, offsetBy: 1)
        }
        
        // 서버에서 받아야 할 데이타를 모두 받았는지 검사함.2
        //var sIndex:Data.Index = responseData.startIndex
        var sIndex:Data.Index = keyDataStartIndex
        while true {
            if sIndex > responseData.count {break}
            guard let r1:Range<Data.Index> = responseData.range(of: Data([UInt8.REDIS_RESP_BULKSTRING]), options: [], in: sIndex..<responseData.endIndex) else {break}
            guard let r2:Range<Data.Index> = responseData.range(of: Data([UInt8.REDIS_SEPARATER_CR]), options: [], in: r1.endIndex..<responseData.endIndex) else {break}
            let s:String = String(decoding: responseData.subdata(in: r1.endIndex..<r2.startIndex), as: UTF8.self)
            let bytes:Int = Int(s) ?? 0
            valueSize += bytes
            sIndex = r2.endIndex + bytes
            
            needDataSize += s.count + 3 // $, CR, LF
            needDataSize += bytes + 2
            
            // $-1 : 값없음
            if bytes < 0 {needDataSize = 0}
            //print("needDataSize=[\(needDataSize)]")
        }
        
        // 필요한데이타양 > 서버에서받은데이타양 : 그냥 리턴
        print("needDataSize=[\(needDataSize)] realSize=[\(responseData.count)]")
        if needDataSize > responseData.count {return returnValue}
        
        responseData.removeSubrange(responseData.startIndex..<keyDataStartIndex)
        while responseData.count > 0 {
            guard let r1:Range<Data.Index> = responseData.range(of: Data([UInt8.REDIS_RESP_BULKSTRING])) else {break}
            guard let r2:Range<Data.Index> = responseData.range(of: Data([UInt8.REDIS_SEPARATER_CR]), options: [], in: r1.endIndex..<responseData.endIndex) else {break}
            let s:String = String(decoding: responseData.subdata(in: r1.endIndex..<r2.startIndex), as: UTF8.self)
            let bytes:Int = Int(s) ?? 0

            let sIndex:Int = responseData.index(after: r2.endIndex)
            if responseData.count < sIndex+bytes {return returnValue}
            let eIndex:Int = responseData.index(sIndex, offsetBy: bytes)
            let subData:Data = responseData.subdata(in: sIndex..<eIndex)
            oneItemDatas.append(subData)
            responseData.removeSubrange(responseData.startIndex..<responseData.index(eIndex, offsetBy: 2))
        }
        
        if itemCount > oneItemDatas.count {return returnValue}
        responseData.removeAll()
        returnValue = (oneItemDatas, valueSize, false, nextCursorIndex)
        return returnValue
    }
    
    
    
    // MARK: - Response Error Check
    
    private func doCheckErrorResponse(responseData:Data)->Bool {
        if responseData[responseData.startIndex] != UInt8.REDIS_RESP_ERROR {return false}
        let informativeText:String = String(decoding: responseData[responseData.startIndex..<responseData.endIndex], as: UTF8.self)
        print("informativeText=" + informativeText)
        doPerformClosure(withDelay: 0.1) {
            let alert = NSAlert()
            alert.messageText = "ERROR"
            alert.informativeText = informativeText
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
        return true
    }
    
    
    private func doCheckFailResponse(responseData:Data)->Bool {
        let failData:Data = "$-1\(CRLF)".data(using: .utf8)!
        if responseData.prefix(failData.count) != failData {return false}
        let informativeText:String = "실패 응답 받음."
        doPerformClosure(withDelay: 0.1) {
            let alert = NSAlert()
            alert.messageText = "FAIL"
            alert.informativeText = informativeText
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
        return true
    }
     */

    // MARK: - Util
    
    internal static func doViewAsRedisCli(_ d:UInt8)->String {
        if d == 0 {return #"\x00"#}
        var s = String(decoding: [d], as: UTF8.self)
        if s == #"\"# {s = #"\\"#}
        return s
    }
 

}
