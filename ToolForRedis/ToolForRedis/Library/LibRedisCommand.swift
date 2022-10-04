//
//  LibRedisCommand.swift
//  swleeTest
//
//  Created by swlee on 2020/12/24.
//

import Cocoa

enum LibRedisCommand {
    // basic commands
    case auth(password:String, closureResultAuth:CLOSURE_RESULT_AUTH)
    case select(dbNo:String, closureResultSelect:CLOSURE_RESULT_SELECT)
    case scan(cursorIndex:Int, match:String, continueOnError:Bool, closureResultScan:CLOSURE_RESULT_SCAN?)
    case type(keyInfo:KeyInfo, continueOnError:Bool, closureResultType:CLOSURE_RESULT_TYPE)
    case ttl(keyInfo:KeyInfo, continueOnError:Bool, closureResultTtl:CLOSURE_RESULT_TTL)
    case expire(keyInfo:KeyInfo, sec:Int, continueOnError:Bool, closureResultExpire:CLOSURE_RESULT_EXPIRE)
    case persist(keyInfo:KeyInfo, continueOnError:Bool, closureResultPersist:CLOSURE_RESULT_PERSIST)
    case info(section:String?, continueOnError:Bool, closureResultInfo:CLOSURE_RESULT_INFO)
    case configGet(section:String?, continueOnError:Bool, closureResultConfig:CLOSURE_RESULT_CONFIG)
    case configSet(configCmd:String, configOption:String?, continueOnError:Bool, closureResultConfig:(String)->Void)
    case renamenx(keyInfo:KeyInfo, newKeyName:String, continueOnError:Bool, closureResultRenamenx:CLOSURE_RESULT_RENAMENX)
    case del(keyInfo:KeyInfo, continueOnError:Bool, closureResultDel:(String)->Void)

    // string datatype commands
    case get(keyInfo:KeyInfo, continueOnError:Bool, closureResultGet:CLOSURE_RESULT_GET)
    case set(keyInfo:KeyInfo, value:String, ttl:Int, isNew:Bool, continueOnError:Bool, closureResultSet:CLOSURE_RESULT_SET)
    
    // list datatype commands
    case lrange(keyInfo:KeyInfo, startOffset:Int, continueOnError:Bool, closureResultLrange:CLOSURE_RESULT_LRANGE?)
    case lset(keyInfo:KeyInfo, index:Int, value:String, continueOnError:Bool, closureResultLset:CLOSURE_RESULT_LSET)
    case rpush(keyInfo:KeyInfo, value:String, continueOnError:Bool, closureResultRpush:CLOSURE_RESULT_RPUSH) // 리스트 맨 뒤에 추가
    case lrem(keyInfo:KeyInfo, itemValue:String, continueOnError:Bool, closureResultLrem:CLOSURE_RESULT_LREM)

    // set datatype commands
    case sscan(keyInfo:KeyInfo, cursorIndex:Int, continueOnError:Bool, closureResultSscan:CLOSURE_RESULT_SSCAN?)
    case sadd(keyInfo:KeyInfo, value:String, continueOnError:Bool, closureResultSadd:CLOSURE_RESULT_SADD)
    case srem(keyInfo:KeyInfo, value:String, continueOnError:Bool, closureResultSrem:CLOSURE_RESULT_SREM)
    
    // hash datatype commands
    case hscan(keyInfo:KeyInfo, cursorIndex:Int, continueOnError:Bool, closureResultHscan:CLOSURE_RESULT_HSCAN?)
    case hset(keyInfo:KeyInfo, hash:String, value:String, continueOnError:Bool, closureResultHset:CLOSURE_RESULT_HSET)
    case hdel(keyInfo:KeyInfo, hash:String, continueOnError:Bool, closureResultHdel:CLOSURE_RESULT_HDEL)

    // zset datatype commands
    case zrange(keyInfo:KeyInfo, startOffset:Int, continueOnError:Bool, closureResultZrange:CLOSURE_RESULT_ZRANGE?)
    case zadd(keyInfo:KeyInfo, score:String, value:String, continueOnError:Bool, closureResultZadd:CLOSURE_RESULT_ZADD)
    case zrem(keyInfo:KeyInfo, value:String, continueOnError:Bool, closureResultZrem:CLOSURE_RESULT_ZREM)
    
    // pub/sub/KeyspaceNotifications
    case pubsubChannels(closurePubsubChannels:([String])->Void)
    case subscribe(channelName:String, closureSubscribe:((kind:String, channelName:String, message:String))->Void)
    case psubscribe(pattern:String, closurePsubscribe:([(kind:String, channelName:String, key:String, cmd:String)])->Void)
    case unsubscribe(channelName:String, closureUnsubscribe:(String)->Void)
    case punsubscribe(pattern:String, closurePunsubscribe:(String)->Void)
    case publish(channelName:String, message:String, closurePublish:(String)->Void)

    // console command
    case _consoleCommand(command:String, closureConsoleCommand:(String)->Void)




    static var scanMatch:String = ""
    static var lrangeKeyInfo:KeyInfo = KeyInfo()
    static var lrangeStartOffset:Int = 0
    static var zrangeKeyInfo:KeyInfo = KeyInfo()
    static var zrangeStartOffset:Int = 0
    static var sscanKeyInfo:KeyInfo = KeyInfo()
    static var hscanKeyInfo:KeyInfo = KeyInfo()
    static var commandArray:[LibRedisCommand] = []
    static var closureResultScan:CLOSURE_RESULT_SCAN?
    static var closureResultLrange:CLOSURE_RESULT_LRANGE?
    static var closureResultZrange:CLOSURE_RESULT_ZRANGE?
    static var closureResultSscan:CLOSURE_RESULT_SSCAN?
    static var closureResultHscan:CLOSURE_RESULT_HSCAN?
    
    // 일련의 레디스명령어가 모두 끝났을때, 호출하는 클로저.
    //static var closureCommandFinish:(()->Void)?
    
    // 화면에 보여줄 명령어를 위한 변수들.
    static var closureDisplayCommand:((String)->Void)?
    static var displayCommandArray:[String] = [] {
        didSet {
            //print("***************.displayCommandArray")
            //print(displayCommandArray.last)
            guard let c:String = displayCommandArray.last else {return}
            closureDisplayCommand?(c)
        }
    }
    

//    static func doAdd(_ libRedisCommand:LibRedisCommand) {
//        self.commandArray.append(libRedisCommand)
//    }
//
//
//    static func doSend(libRedisSocket:LibRedisSocket) {
//        if commandArray.count <= 0 {
//            if let closureCommandFinish_ = closureCommandFinish {
//                closureCommandFinish_()
//                closureCommandFinish = nil
//            }
//
//            doProgressIndicator(show: false)
//            return
//        }
//        commandArray.removeFirst().doCommand(libRedisSocket:libRedisSocket)
//    }
    
    
    func doRunResultClosure(libRedisSocket:LibRedisSocket, _ args:Any?...) {
        var isContinueOnError:Bool = false
        
        doPerformClosure(withDelay: 0.01) {
            switch self {
            case .auth(_, let closureResultAuth):
                guard let arg0 = args[0] else {break}
                closureResultAuth(arg0 as! String)

            case .select(_, let closureResultSelect):
                guard let arg0 = args[0] else {break}
                closureResultSelect(arg0 as! String)
                
            case .scan(_, _, let continueOnError, _):
                isContinueOnError = continueOnError
                guard let closure = LibRedisCommand.closureResultScan else {return}
                guard let arg0 = args[0] else {break}
                closure(arg0 as! [String:Any])

            case .type(_, let continueOnError, let closureResultType):
                isContinueOnError = continueOnError
                guard let arg0 = args[0] else {break}
                closureResultType(arg0 as! String)
                
            case .ttl(_, let continueOnError, let closureResultTtl):
                isContinueOnError = continueOnError
                guard let arg0 = args[0] else {break}
                closureResultTtl(arg0 as! Int)
                
            case .expire(_, _, let continueOnError, let closureResultExpire):
                isContinueOnError = continueOnError
                guard let arg0 = args[0] else {break}
                closureResultExpire(arg0 as! String)

            case .persist(_, let continueOnError, let closureResultPersist):
                isContinueOnError = continueOnError
                guard let arg0 = args[0] else {break}
                closureResultPersist(arg0 as! String)
                
            case .info(_, let continueOnError, let closureResultInfo):
                isContinueOnError = continueOnError
                guard let arg0 = args[0] else {break}
                closureResultInfo(arg0 as! [(infoKey: String, infoValue: String)])
                
            case .configGet(_, let continueOnError, let closureResultConfig):
                isContinueOnError = continueOnError
                guard let arg0 = args[0] else {break}
                closureResultConfig(arg0 as! [(configKey: String, configValue: String)])
                
            case .configSet(_, _, let continueOnError, let closureResultConfig):
                isContinueOnError = continueOnError
                guard let arg0 = args[0] else {break}
                closureResultConfig(arg0 as! String)
                
            case .renamenx(_, _, let continueOnError, let closureResultRenamenx):
                isContinueOnError = continueOnError
                guard let arg0 = args[0] else {break}
                closureResultRenamenx(arg0 as! String)
                
            case .del(_, let continueOnError, let closureResultDel):
                isContinueOnError = continueOnError
                guard let arg0 = args[0] else {break}
                closureResultDel(arg0 as! String)
                
            case .get(_, let continueOnError, let closureResultGet):
                isContinueOnError = continueOnError
                guard let arg0 = args[0], let arg1 = args[1], let arg2 = args[2] else {break}
                closureResultGet(arg0 as! String, arg1 as! String, arg2 as! Int)

            case .set(_, _, _, _, let continueOnError, let closureResultSet):
                isContinueOnError = continueOnError
                guard let arg0 = args[0] else {break}
                closureResultSet(arg0 as! String)
                
            case .lrange(_, _, let continueOnError, _):
                isContinueOnError = continueOnError
                guard let closure = LibRedisCommand.closureResultLrange else {return}
                guard let arg0 = args[0] else {break}
                closure(arg0 as! [String:Any])

            case .lset(_, _, _, let continueOnError, let closureResultLset):
                isContinueOnError = continueOnError
                guard let arg0 = args[0] else {break}
                closureResultLset(arg0 as! String)
                
            case .rpush(_, _, let continueOnError, let closureResultRpush):
                isContinueOnError = continueOnError
                guard let arg0 = args[0] else {break}
                closureResultRpush(arg0 as! String)
                
            case .lrem(_, _, let continueOnError, let closureResultLrem):
                isContinueOnError = continueOnError
                guard let arg0 = args[0] else {break}
                closureResultLrem(arg0 as! String)

            case .sscan(_, _, let continueOnError, _):
                isContinueOnError = continueOnError
                guard let closure = LibRedisCommand.closureResultSscan else {return}
                guard let arg0 = args[0] else {break}
                closure(arg0 as! [String:Any])
                
            case .sadd(_, _, let continueOnError, let closureResultSadd):
                isContinueOnError = continueOnError
                guard let arg0 = args[0] else {break}
                closureResultSadd(arg0 as! String)
            
            case .srem(_, _, let continueOnError, let closureResultSrem):
                isContinueOnError = continueOnError
                guard let arg0 = args[0] else {break}
                closureResultSrem(arg0 as! String)
                
            case .hscan(_, _, let continueOnError, _):
                isContinueOnError = continueOnError
                guard let closure = LibRedisCommand.closureResultHscan else {return}
                guard let arg0 = args[0] else {break}
                closure(arg0 as! [String:Any])

            case .hset(_, _, _, let continueOnError, let closureResultHset):
                isContinueOnError = continueOnError
                guard let arg0 = args[0] else {break}
                closureResultHset(arg0 as! String)
                
            case .hdel(_, _, let continueOnError, let closureResultHdel):
                isContinueOnError = continueOnError
                guard let arg0 = args[0] else {break}
                closureResultHdel(arg0 as! String)

            case .zrange(_, _, let continueOnError, _):
                isContinueOnError = continueOnError
                guard let closure = LibRedisCommand.closureResultZrange else {return}
                guard let arg0 = args[0] else {break}
                closure(arg0 as! [String:Any])
                
            case .zadd(_, _, _, let continueOnError, let closureResultZadd):
                isContinueOnError = continueOnError
                guard let arg0 = args[0] else {break}
                closureResultZadd(arg0 as! String)
                
            case .zrem(_, _, let continueOnError, let closureResultZrem):
                isContinueOnError = continueOnError
                guard let arg0 = args[0] else {break}
                closureResultZrem(arg0 as! String)
                
            case .pubsubChannels(let closurePubsubChannels):
                guard let arg0 = args[0] else {break}
                closurePubsubChannels(arg0 as! [String])

            case .subscribe(_, let closureSubscribe):
                guard let arg0 = args[0] else {break}
                closureSubscribe(arg0 as! (String, String, String))

            case .psubscribe(_, let closurePsubscribe):
                guard let arg0 = args[0] else {break}
                closurePsubscribe(arg0 as! [(String, String, String, String)])

            case .unsubscribe(_, let closureUnsubscribe):
                guard let arg0 = args[0] else {break}
                closureUnsubscribe(arg0 as! String)

            case .punsubscribe(_, let closureUnsubscribe):
                guard let arg0 = args[0] else {break}
                closureUnsubscribe(arg0 as! String)

            case .publish(_, _, let closurePublish):
                guard let arg0 = args[0] else {break}
                closurePublish(arg0 as! String)
                break
            
            case ._consoleCommand(_, let closureConsoleCommand):
                guard let arg0 = args[0] else {break}
                closureConsoleCommand(arg0 as! String)
                break
            }

        
            if args[0] == nil && !isContinueOnError {
                LibRedisCommand.commandArray.removeAll()
                return
            }

            LibRedis.doSend(libRedisSocket:libRedisSocket)
        }
    }


    internal func doCommand() -> Data {
        let KEYNAME_DATA:String = "{{{---KEYNAME---}}}"
        var temps:[String] = []
        var keyInfo_:KeyInfo = KeyInfo()
        
        switch self {
        case .auth(let password, _):
            temps.append(contentsOf: ["auth", password])

        case .select(let dbNo, _):
            temps.append(contentsOf: ["select", dbNo])

        case .scan(let cursorIndex, let match, _, let closureResultScan):
            LibRedisCommand.scanMatch = match.count <= 0 ? "*" : match
            if closureResultScan != nil {LibRedisCommand.closureResultScan = closureResultScan}
            temps.append(contentsOf: ["scan", "\(cursorIndex)", "count", "\(SCAN_COUNT)", "match", LibRedisCommand.scanMatch])

        // https://redis.io/commands/type
        // type {keyname}
        case .type(let keyInfo, _, _):
            keyInfo_ = keyInfo
            temps.append(contentsOf: ["type", KEYNAME_DATA])
        
        case .get(let keyInfo, _, _):
            keyInfo_ = keyInfo
            temps.append(contentsOf: ["get", KEYNAME_DATA])

        // set {keyname} {value} [ex ttl] [nx|xx]
        case .set(let keyInfo, let value, let ttl, let isNew, _, _):
            keyInfo_ = keyInfo
            temps.append(contentsOf: ["set", KEYNAME_DATA, value])
            if ttl != -1 {
                temps.append(contentsOf: ["ex", "\(ttl)"])
            }
            temps.append(isNew ? "nx" : "xx")

        case .ttl(let keyInfo, _, _):
            keyInfo_ = keyInfo
            temps.append(contentsOf: ["ttl", KEYNAME_DATA])
            
        // https://redis.io/commands/expire
        // expire {keyname} {seconds}
        case .expire(let keyInfo, let sec, _, _):
            keyInfo_ = keyInfo
            temps.append(contentsOf: ["expire", KEYNAME_DATA, "\(sec)"])
            
        // https://redis.io/commands/persist
        // persist {keyname}
        case .persist(let keyInfo, _, _):
            keyInfo_ = keyInfo
            temps.append(contentsOf: ["persist", KEYNAME_DATA])
            
        case .info(let section, _, _):
            temps.append("info")
            if section != nil {temps.append(section!)}

        case .configGet(let section, _, _):
            temps.append(contentsOf: ["config", "get"])
            temps.append(section ?? "*")
            
        case .configSet(let configCmd, let configOption, _, _):
            temps.append(contentsOf: ["config", "set", configCmd])
            if configOption != nil {temps.append(configOption!)}
            
        // https://redis.io/commands/renamenx
        // renamenx {keyname} {newkeyname}
        case .renamenx(let keyInfo, let newKeyName, _, _):
            keyInfo_ = keyInfo
            temps.append(contentsOf: ["renamenx", KEYNAME_DATA, newKeyName])
            
        // https://redis.io/commands/del
        // del {keyname}
        case .del(let keyInfo, _, _):
            keyInfo_ = keyInfo
            temps.append(contentsOf: ["del", KEYNAME_DATA])

        // lrange {keyname} 0 100
        case .lrange(let keyInfo, let startOffset, _, let closureResultLrange):
            keyInfo_ = keyInfo
            LibRedisCommand.lrangeKeyInfo = keyInfo
            LibRedisCommand.lrangeStartOffset = startOffset
            if closureResultLrange != nil {LibRedisCommand.closureResultLrange = closureResultLrange}
            temps.append(contentsOf: ["lrange", KEYNAME_DATA, "\(startOffset)", "\(startOffset+SCAN_COUNT)"])

        // lset {keyname} {index} {value}
        case .lset(let keyInfo, let index, let value, _, _):
            keyInfo_ = keyInfo
            temps.append(contentsOf: ["lset", KEYNAME_DATA, "\(index)", value])

        // rpush {keyname} {value}
        case .rpush(let keyInfo, let value, _, _):
            keyInfo_ = keyInfo
            temps.append(contentsOf: ["rpush", KEYNAME_DATA, value])

        // lrem {keyname} {count} {value}
        case .lrem(let keyInfo, let itemValue, _, _):
            keyInfo_ = keyInfo
            temps.append(contentsOf: ["lrem", KEYNAME_DATA, "1", itemValue])

        case .sscan(let keyInfo, let cursorIndex, _, let closureResultSscan):
            keyInfo_ = keyInfo
            LibRedisCommand.sscanKeyInfo = keyInfo
            if closureResultSscan != nil {LibRedisCommand.closureResultSscan = closureResultSscan}
            temps.append(contentsOf: ["sscan", KEYNAME_DATA, "\(cursorIndex)", "count", "\(SCAN_COUNT)"])
    
        // sadd {keyname} {value}
        case .sadd(let keyInfo, let value, _, _):
            keyInfo_ = keyInfo
            temps.append(contentsOf: ["sadd", KEYNAME_DATA, value])
        
        // srem {keyname} {value}
        case .srem(let keyInfo, let value, _, _):
            keyInfo_ = keyInfo
            temps.append(contentsOf: ["srem", KEYNAME_DATA, value])
            
        case .hscan(let keyInfo, let cursorIndex, _, let closureResultHscan):
            keyInfo_ = keyInfo
            LibRedisCommand.hscanKeyInfo = keyInfo
            if closureResultHscan != nil {LibRedisCommand.closureResultHscan = closureResultHscan}
            temps.append(contentsOf: ["hscan", KEYNAME_DATA, "\(cursorIndex)", "count", "\(SCAN_COUNT)"])

        // hset {keyname} {hash} {value}
        case .hset(let keyInfo, let hash, let value, _, _):
            keyInfo_ = keyInfo
            temps.append(contentsOf: ["hset", KEYNAME_DATA, hash, value])

        // hdel {keyname} {hash}
        case .hdel(let keyInfo, let hash, _, _):
            keyInfo_ = keyInfo
            temps.append(contentsOf: ["hdel", KEYNAME_DATA, hash])

        // zrange {keyname} 0 100 withscores
        case .zrange(let keyInfo, let startOffset, _, let closureResultZrange):
            keyInfo_ = keyInfo
            LibRedisCommand.zrangeKeyInfo = keyInfo
            LibRedisCommand.zrangeStartOffset = startOffset
            if closureResultZrange != nil {LibRedisCommand.closureResultZrange = closureResultZrange}
            temps.append(contentsOf: ["zrange", KEYNAME_DATA, "\(startOffset)", "\(startOffset+SCAN_COUNT)", "withscores"])
            
        case .zadd(let keyInfo, let score, let value, _, _):
            keyInfo_ = keyInfo
            temps.append(contentsOf: ["zadd", KEYNAME_DATA, score, value])
            
        case .zrem(let keyInfo, let value, _, _):
            keyInfo_ = keyInfo
            temps.append(contentsOf: ["zrem", KEYNAME_DATA, value])
            
        case .pubsubChannels( _):
            temps.append(contentsOf: ["pubsub", "channels"])
            
        case .subscribe(let channelName, _):
            temps.append(contentsOf: ["subscribe", channelName])

        case .psubscribe(let pattern, _):
            temps.append(contentsOf: ["psubscribe", pattern])
            
        case .unsubscribe(let channelName, _):
            temps.append(contentsOf: ["unsubscribe", channelName])

        case .punsubscribe(let pattern, _):
            temps.append(contentsOf: ["punsubscribe", pattern])

        case .publish(let channelName, let message, _):
            temps.append(contentsOf: ["publish", channelName, message])
            
        case ._consoleCommand(let command, _):
            temps.append(contentsOf: command.components(separatedBy: " "))
        }
        
        var commandString:String = ""
        var commandData:Data = Data()
        commandData.append(("*\(temps.count)" + CRLF).data(using: .utf8)!)
        for s:String in temps {
            if s == KEYNAME_DATA {
                commandData.append(("$\(keyInfo_.keyNameData.count)" + CRLF).data(using: .utf8)!)
                commandData.append(keyInfo_.keyNameData)
            } else {
                let d:Data = s.data(using: .utf8)!
                commandData.append(("$\(d.count)" + CRLF).data(using: .utf8)!)
                commandData.append(d)
            }
            commandData.append(CRLF.data(using: .utf8)!)
            commandString += "\"\(s == KEYNAME_DATA ? keyInfo_.keyName : s)\" "
        }
        commandData.append(UInt8.REDIS_SEPARATER_CR)
        commandData.append(UInt8.REDIS_SEPARATER_LF)
        
        print("--->"+commandString)
        //print("--->"+String(decoding: commandData, as: UTF8.self))
        LibRedisCommand.displayCommandArray.append(commandString)
        
        return commandData
    }

    
    static func doGetKeySpaceNotiChannel(dbNo:Int) -> String {
        return "__keyspace@\(dbNo)__"
    }
    
    
    // 각 배열에서 맨 마지막은, redis.io 명령어 설명 사이트 주소임.
    static var allList: [[String]] {
        [["AUTH", "[username]", "password", "auth.md"],
         ["SELECT", "index", "select.md"],
         ["SCAN", "cursor", "[MATCH pattern]", "[COUNT count]", "[TYPE type]", "scan.md"],
         ["TYPE", "key", "type.md"],
         ["TTL", "key", "ttl.md"],
         ["EXPIRE", "key", "seconds", "expire.md"],
         ["PERSIST", "key", "persist.md"],
         ["INFO", "[section]", "info.md"],
         ["CONFIG GET", "parameter", "config-get.md"],
         ["CONFIG SET", "parameter", "value", "config-set.md"],
         ["RENAMENX", "key", "newkey", "renamenx.md"],
         ["DEL", "key", "[key ...]", "del.md"],
         ["GET", "key", "get.md"],
         ["SET", "key", "value", "[EX seconds|PX milliseconds|EXAT timestamp|PXAT milliseconds-timestamp|KEEPTTL]", "[NX|XX]", "[GET]", "set.md"],
         ["LRANGE", "key", "start", "stop", "lrange.md"],
         ["LSET", "key", "index", "element", "lset.md"],
         ["RPUSH", "key", "element", "[element ...]", "rpush.md"],
         ["LREM", "key", "count", "element", "lrem.md"],
         ["SSCAN", "key", "cursor", "[MATCH pattern]", "[COUNT count]", "sscan.md"],
         ["SADD", "key", "member", "[member ...]", "sadd.md"],
         ["SREM", "key", "member", "[member ...]", "srem.md"],
         ["HSCAN", "key", "cursor", "[MATCH pattern]", "[COUNT count]", "hscan.md"],
         ["HSET", "key", "field", "value", "[field value ...]", "hset.md"],
         ["HDEL", "key", "field", "[field ...]", "hdel.md"],
         ["ZRANGE", "key", "min", "max", "[BYSCORE|BYLEX]", "[REV]", "[LIMIT offset count]", "[WITHSCORES]", "zrange.md"],
         ["ZADD", "key", "[NX|XX]", "[GT|LT]", "[CH]", "[INCR]", "score", "member", "[score member ...]", "zadd.md"],
         ["ZREM", "key", "member", "[member ...]", "zrem.md"],
         ["PUBSUB CHANNELS", "[pattern]", "pubsub.md"],
         ["SUBSCRIBE", "channel", "[channel ...]", "subscribe.md"],
         ["PSUBSCRIBE", "pattern", "[pattern ...]", "psubscribe.md"],
         ["UNSUBSCRIBE", "[channel [channel ...]]", "unsubscribe.md"],
         ["PUNSUBSCRIBE", "[pattern [pattern ...]]", "punsubscribe.md"],
         ["PUBLISH", "channel", "message", "publish.md"]]
    }
    
    
    // 콘솔에서 사용자가 직접 입력한 명령어 전송
//    static func doConsoleCommand(command:String, libRedisStream:LibRedisStream) {
//        let commandData:Data = command.data(using: .utf8)!
//        commandData.withUnsafeBytes { (unsafeBytes) in
//            let bytes:UnsafePointer<UInt8> = unsafeBytes.bindMemory(to: UInt8.self).baseAddress!
//            libRedisStream.outputStream.write(bytes, maxLength: unsafeBytes.count)
//        }
//    }
}
