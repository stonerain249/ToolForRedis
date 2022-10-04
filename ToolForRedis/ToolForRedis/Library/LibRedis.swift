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
    public var libRedisSocket:LibRedisSocket!
    
    private var closureResultConnect:CLOSURE_RESULT_CONNECT!
    private var closureResultDisconnected:CLOSURE_RESULT_DISCONNECTED!
    
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
    
    

    // MARK: - Util
    
    internal static func doViewAsRedisCli(_ d:UInt8)->String {
        if d == 0 {return #"\x00"#}
        var s = String(decoding: [d], as: UTF8.self)
        if s == #"\"# {s = #"\\"#}
        return s
    }
 

}
