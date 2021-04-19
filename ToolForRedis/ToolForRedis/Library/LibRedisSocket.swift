//
//  LibRedisSocket.swift
//  RedClient
//
//  Created by swlee on 2021/03/09.
//

import Foundation
import Cocoa
import NIO


class LibRedisSocket {
    private let eventLoopGroup:MultiThreadedEventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    private var host:String = ""
    private var port:Int = -1
    private var channel:Channel?
    private var responseData:Data = Data()
    
    private var libRedisProtocol:LibRedisProtocol
    private var libRedisSocketHandler:LibRedisSocketHandler!
    private var libRedisCommand:LibRedisCommand?

    
    private var scanAry:[KeyInfo] = []
    private var scanMatch:String = ""
    private var lrangeAry:[String] = []
    private var lrangeValueSize:Int = 0
    private var zrangeAry:[(String,String)] = []
    private var zrangeValueSize:Int = 0
    private var sscanAry:[String] = []
    private var sscanValueSize:Int = 0
    private var hscanAry:[(String,String)] = []
    private var hscanValueSize:Int = 0
    
    
    init(libRedisProtocol:LibRedisProtocol) {
        self.libRedisProtocol = libRedisProtocol
        self.libRedisSocketHandler = LibRedisSocketHandler(libRedisSocket:self)
    }

    
    internal func doConnect(host:String, port:Int=6379) throws {
        self.host = host
        self.port = port
        
        let clientBootstrap:ClientBootstrap = ClientBootstrap(group: self.eventLoopGroup)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            //.channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .channelInitializer{ channel in
                channel.pipeline.addHandler(self.libRedisSocketHandler)
            }
        
        do {
            self.channel = try clientBootstrap.connect(host: host, port: port).wait()
            
//            let result = try! self.sendsend().wait()
//            print(result)
            
//            let emailSentPromise: EventLoopPromise<Void> = self.eventLoopGroup.next().makePromise()
//            let connection = clientBootstrap.connect(host: host, port: port)
//
//            connection.cascadeFailure(to: emailSentPromise)
//            emailSentPromise.futureResult.map {
//                connection.whenSuccess { $0.close(promise: nil) }
//                DispatchQueue.main.async {
//                    print("OKOKOK")
//                }
//            }.whenFailure { error in
//                connection.whenSuccess { $0.close(promise: nil) }
//                DispatchQueue.main.async {
//                    print(error)
//                }
//            }

// okokok
//            var mmm = "auth long0185**\r\n"
//            var buffer:ByteBuffer = (self.channel?.allocator.buffer(capacity: mmm.utf8.count))!
//            buffer.writeString(mmm)
//            self.channel?.writeAndFlush(NIOAny(buffer), promise: nil)
//
//
//            mmm = "get html2\r\n"
//            buffer = (self.channel?.allocator.buffer(capacity: mmm.utf8.count))!
//            buffer.writeString(mmm)
//            self.channel?.writeAndFlush(NIOAny(buffer), promise: nil)
        } catch let error {
            print("aaaaaaaaaaaaaaaaa")
            print(error)
            throw error
        }
    }
    
    
    internal func doConnectResult(connResult:Bool) {
        doPerformClosure(withDelay: 0.01) {
            self.libRedisProtocol.doConnectResult(connResult:connResult)
        }
    }
    
    
    internal func doSendData(sendData:Data, libRedisCommand:LibRedisCommand) -> Void {
        print("LibRedisSocket.doSendData")
        let sss:String = String(decoding: sendData, as: UTF8.self)
        print("LibRedisSocket.doSendData [\(sss)]")
        guard let channel = self.channel else {
            print("NO CONNECTION")
            doPerformClosure(withDelay: 0.1) {
                doAlertShow(message: "NO CONNECTION", informativeText: nil, buttons: ["OK"])
            }
            return
        }
        self.libRedisCommand = libRedisCommand
        //libRedisSocketHandler.libRedisCommand = libRedisCommand
        
        //var buffer:ByteBuffer = channel.allocator.buffer(capacity: sendData.count)
        //buffer.writeBytes(sendData)
        let buffer:ByteBuffer = channel.allocator.buffer(bytes: sendData)
        channel.writeAndFlush(NIOAny(buffer), promise: nil)
    }
    
    
    internal func doReadComplete(readData:Data) {
        responseData.append(readData)
        //let sss:String = String(decoding: responseData, as: UTF8.self)
        //print("doReadComplete size=[\(responseData.count)] [\(sss)]")
        print("doReadComplete size=[\(responseData.count)]")
        //doPerformClosure(withDelay: 0.01) { [self] in
            switch self.libRedisCommand {
            case .auth : doParsingResponse_Auth(responseData: &responseData)
            case .select : doParsingResponse_Select(responseData: &responseData)
            case .scan : doParsingResponse_Scan(responseData: &responseData)
            case .type : doParsingResponse_Type(responseData: &responseData)
            case .get : doParsingResponse_Get(responseData: &responseData)
            case .set : doParsingResponse_Set(responseData: &responseData)
            case .ttl : doParsingResponse_Ttl(responseData: &responseData)
            case .expire : doParsingResponse_Expire(responseData: &responseData)
            case .persist : doParsingResponse_Persist(responseData: &responseData)
            case .info : doParsingResponse_Info(responseData: &responseData)
            case .configGet : doParsingResponse_ConfigGet(responseData: &responseData)
            case .configSet : doParsingResponse_ConfigSet(responseData: &responseData)
            case .renamenx : doParsingResponse_Renamenx(responseData: &responseData)
            case .del : doParsingResponse_Del(responseData: &responseData)

            case .lrange : doParsingResponse_Lrange(responseData: &responseData)
            case .lset : doParsingResponse_Lset(responseData: &responseData)
            case .rpush : doParsingResponse_Rpush(responseData: &responseData)
            case .lrem : doParsingResponse_Lrem(responseData: &responseData)

            //case .smembers : LibRedis.doParsingResponse_Smembers(responseData: &responseData)
            case .sscan : doParsingResponse_Sscan(responseData: &responseData)
            case .sadd : doParsingResponse_Sadd(responseData: &responseData)
            case .srem : doParsingResponse_Srem(responseData: &responseData)

            //case .hgetall : LibRedis.doParsingResponse_Hgetall(responseData: &responseData)
            case .hscan : doParsingResponse_Hscan(responseData: &responseData)
            case .hset : doParsingResponse_Hset(responseData: &responseData)
            case .hdel : doParsingResponse_Hdel(responseData: &responseData)

            case .zrange : doParsingResponse_Zrange(responseData: &responseData)
            case .zadd : doParsingResponse_Zadd(responseData: &responseData)
            case .zrem : doParsingResponse_Zrem(responseData: &responseData)

            case .pubsubChannels : doParsingResponse_PubSubChannels(responseData: &responseData)
            case .subscribe : doParsingResponse_Subscribe(responseData: &responseData)
            case .psubscribe : doParsingResponse_Subscribe(responseData: &responseData)
            case .unsubscribe : doParsingResponse_Unsubscribe(responseData: &responseData)
            case .punsubscribe : doParsingResponse_Unsubscribe(responseData: &responseData)
            case .publish : doParsingResponse_Publish(responseData: &responseData)

            case ._consoleCommand : doParsingResponse_ConsoleCommand(responseData: &responseData)

            case .none: break
            }
        //}
    }
    
    
    
    
    // MARK: - Parsing. Basic

    public func doParsingResponse_Auth(responseData:inout Data) {
        // 에러 검사
        if self.doCheckErrorResponse(responseData: responseData) {
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, nil)
            responseData.removeAll()
            return
        }
        
        let sIndex:Int = responseData.index(after: responseData.startIndex)
        let eIndex:Int = responseData.index(responseData.endIndex, offsetBy: -2)
        let subData:Data = responseData.subdata(in: sIndex..<eIndex)
        let result:String = String(decoding: subData, as: UTF8.self)
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, result)
        responseData.removeAll()
    }

    
    public func doParsingResponse_Select(responseData:inout Data) {
        // 에러 검사
        if self.doCheckErrorResponse(responseData: responseData) {
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, nil)
            responseData.removeAll()
            return
        }
        
        let sIndex:Int = responseData.index(after: responseData.startIndex)
        let eIndex:Int = responseData.index(responseData.endIndex, offsetBy: -2)
        let subData:Data = responseData.subdata(in: sIndex..<eIndex)
        let result:String = String(decoding: subData, as: UTF8.self)
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, result)
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
            LibRedis.doSend(libRedisSocket:self)
            return
        }
        
        let returnValue:[String:Any] = ["cursorIndex":d.nextCursorIndex, "scanAry":scanAry]
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, returnValue)
        scanAry.removeAll()
        responseData.removeAll()
    }
    
    
    public func doParsingResponse_Type(responseData:inout Data) {
        // 에러 검사
        if self.doCheckErrorResponse(responseData: responseData) {
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, nil)
            responseData.removeAll()
            return
        }
        
        let sIndex:Int = responseData.index(after: responseData.startIndex)
        let eIndex:Int = responseData.index(responseData.endIndex, offsetBy: -2)
        let subData:Data = responseData.subdata(in: sIndex..<eIndex)
        let type:String = String(decoding: subData, as: UTF8.self)
        print("******************************* type = (\(type))")
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, type)
        responseData.removeAll()
    }
    
    
    public func doParsingResponse_Ttl(responseData:inout Data) {
        // 에러 검사
        if self.doCheckErrorResponse(responseData: responseData) {
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, nil)
            responseData.removeAll()
            return
        }
        
        let sIndex:Int = responseData.index(after: responseData.startIndex)
        let eIndex:Int = responseData.index(responseData.endIndex, offsetBy: -2)
        let subData:Data = responseData.subdata(in: sIndex..<eIndex)
        let s:String = String(decoding: subData, as: UTF8.self)
        let ttl:Int = Int(s) ?? 0
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, ttl)
        responseData.removeAll()
    }
    
    
    // return value : integer
    // 1 : ok. 타임아웃 설정 성공.
    // 0 : fail. 키가 없음.
    public func doParsingResponse_Expire(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, s == ":1" ? s : nil)
        responseData.removeAll()
    }
    

    // return value : integer
    // 1 : ok. 타임아웃 제거 성공.
    // 0 : fail. 키가 없음. 또는 타임아웃이 설정안되어 있는 키.
    // persist 명령어는 리턴값이 1 이던 0 이던, 상관없다.
    public func doParsingResponse_Persist(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, s)
        responseData.removeAll()
    }
    
    
    public func doParsingResponse_Info(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, nil)
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
        
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, ary)
        responseData.removeAll()
    }
    
    
    public func doParsingResponse_ConfigGet(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, nil)
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
        
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, ary)
        responseData.removeAll()
    }


    public func doParsingResponse_ConfigSet(responseData:inout Data) {
        // 에러 검사
        if self.doCheckErrorResponse(responseData: responseData) {
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, nil)
            responseData.removeAll()
            return
        }
        
        let sIndex:Int = responseData.index(after: responseData.startIndex)
        let eIndex:Int = responseData.index(responseData.endIndex, offsetBy: -2)
        let subData:Data = responseData.subdata(in: sIndex..<eIndex)
        let result:String = String(decoding: subData, as: UTF8.self)
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, result)
        responseData.removeAll()
    }


    // return value : integer
    // 1 : ok. 이름변경 성공.
    // 0 : fail. 새로운키 이름이 이미 있음.
    public func doParsingResponse_Renamenx(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, s == ":1" ? s : nil)
        responseData.removeAll()
    }

    
    // return value : integer
    // 삭제된 키 갯수
    public func doParsingResponse_Del(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, s)
        responseData.removeAll()
    }
    
    
    
    // MARK: - Parsing. String
    
    public func doParsingResponse_Get(responseData:inout Data) {
        let d:(oneItemDatas:[Data], valueSize:Int, needMoreData:Bool) = self.doSplitResponseType2(responseData: &responseData)
        if d.needMoreData {return}
        if d.oneItemDatas.count <= 0 {
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, nil)
            return
        }
  
        var keyInfo:(valueType:String, value:String, valueSize:Int) = ("", "", d.valueSize)
        keyInfo.value = String(decoding: d.oneItemDatas[d.oneItemDatas.startIndex], as: UTF8.self)
        
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, keyInfo.valueType, keyInfo.value, keyInfo.valueSize)
        responseData.removeAll()
    }
    
    
    public func doParsingResponse_Set(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, s == "+OK" ? s : nil)
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
            LibRedis.doSend(libRedisSocket:self)
            return
        }

        let returnValue:[String:Any] = ["valueSize":lrangeValueSize, "itemAry":lrangeAry]
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, returnValue)
        lrangeAry.removeAll()
        lrangeValueSize = 0
        responseData.removeAll()
    }
    
    
    public func doParsingResponse_Lset(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, s == "+OK" ? s : nil)
        responseData.removeAll()
    }
    

    public func doParsingResponse_Rpush(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        //self.libRedisStream.libRedisCommand?.doRunResultClosure(s == ":0" ? s : nil)
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, s)
        responseData.removeAll()
    }
    
    
    public func doParsingResponse_Lrem(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, s == ":0" ? s : nil)
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
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, returnValue)
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
            LibRedis.doSend(libRedisSocket:self)
            return
        }

        let returnValue:[String:Any] = ["valueSize":d.valueSize, "itemAry":sscanAry]
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, returnValue)
        sscanAry.removeAll()
        responseData.removeAll()
    }
    
    
    // return value : integer
    // 추가된 아이템갯수
    public func doParsingResponse_Sadd(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, s)
        responseData.removeAll()
    }

    
    // return value : integer
    // 삭제된 아이템갯수
    public func doParsingResponse_Srem(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, s)
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
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, returnValue)
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
            LibRedis.doSend(libRedisSocket:self)
            return
        }
        
        let returnValue:[String:Any] = ["valueSize":d.valueSize, "itemAry":hscanAry]
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, returnValue)
        hscanAry.removeAll()
        responseData.removeAll()
    }
    
    // return value : integer
    // 추가된 아이템갯수
    public func doParsingResponse_Hset(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, s)
        responseData.removeAll()
    }
    
    // return value : integer
    // 삭제된 아이템갯수
    public func doParsingResponse_Hdel(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, s)
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
            LibRedis.doSend(libRedisSocket:self)
            return
        }
        
        let returnValue:[String:Any] = ["valueSize":zrangeValueSize, "itemAry":zrangeAry]
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, returnValue)
        zrangeAry.removeAll()
        zrangeValueSize = 0
        responseData.removeAll()
    }
    
    
    // return value : integer
    // 추가된 아이템갯수
    public func doParsingResponse_Zadd(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, s)
        responseData.removeAll()
    }
    

    // return value : integer
    // 삭제된 아이템갯수
    public func doParsingResponse_Zrem(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 0 {
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, nil)
            return
        }
        
        let s:String = String(decoding: oneItemDatas[oneItemDatas.startIndex], as: UTF8.self)
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, s)
        responseData.removeAll()
    }
    
    
    // MARK: - Pub/Sub
    
    public func doParsingResponse_PubSubChannels(responseData:inout Data) {
        let oneItemDatas:[Data] = self.doSplitResponseType1(responseData: &responseData)
        if oneItemDatas.count <= 2 {
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, nil)
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
        
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, activeChannelArray)
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
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, nil)
            return
        }

        let kind:String = String(decoding: oneItemDatas[2], as: UTF8.self)
        let channelName:String = String(decoding: oneItemDatas[4], as: UTF8.self)
        
        // subscribe 명령을 실행했을때.
        if kind == "subscribe" {
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, (kind, channelName, ""))
            responseData.removeAll()
            return
        }

        // subscribe 메세지를 받았을때.
        if kind == "message" {
            let s:String = String(decoding: oneItemDatas.last!, as: UTF8.self)
            print("----------------------------------SUB")
            print(channelName + ":" + s)
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, (kind, channelName, s))
            responseData.removeAll()
            return
        }

        // psubscribe 명령을 실행했을때.
        if kind == "psubscribe" {
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, [(kind, channelName, "", "")])
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
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, pmsgInfo)
            responseData.removeAll()
            return
        }
        
        // 이게 실행되면 이상한건데...
        let s:String = String(decoding: responseData, as: UTF8.self)
        print("----------------------------------SUB.Warning...")
        print(s)
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, ("", "", ""))
        responseData.removeAll()
    }
    
    
    public func doParsingResponse_Unsubscribe(responseData:inout Data) {
        let s:String = String(decoding: responseData, as: UTF8.self)
        //print("----------------------------------UNSUB")
        //print(s)
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, s)
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
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, s)
        }
        else {
            libRedisCommand?.doRunResultClosure(libRedisSocket:self, nil)
        }
        
        responseData.removeAll()
    }
    
    
    // MARK: - Console Command
    
    public func doParsingResponse_ConsoleCommand(responseData:inout Data) {
        let s:String = String(decoding: responseData, as: UTF8.self)
        print("----------------------------------ConsoleCommand")
        print("[\(s)]")
        libRedisCommand?.doRunResultClosure(libRedisSocket:self, s)
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
        print("informativeText=[" + informativeText + "]")
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
}




class LibRedisSocketHandler:ChannelInboundHandler, ChannelOutboundHandler {
    typealias InboundIn = ByteBuffer   // for ChannelInboundHandler
    typealias OutboundIn = ByteBuffer  // for ChannelOutboundHandler
    
    private var channel:Channel?
    private var readData:Data = Data()
    private var libRedisSocket:LibRedisSocket
    
    
    init(libRedisSocket:LibRedisSocket) {
        self.libRedisSocket = libRedisSocket
    }


    // MARK: - ChannelOutboundHandler
    
    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        print("LibTCPHandler.write")
        readData.removeAll()
        context.write(data, promise: promise)
    }
    
    
    // MARK: - ChannelInboundHandler
    
    // channel is connected, send a message
    func channelActive(context: ChannelHandlerContext) {
        print("LibTCPHandler.channelActive")
        if let remoteAddress = context.remoteAddress {
            print("server connected", remoteAddress)
        }
        self.channel = context.channel
        self.libRedisSocket.doConnectResult(connResult: true)
    }
    
    func channelInactive(context: ChannelHandlerContext) {
        
    }
    
    func channelReadComplete(context: ChannelHandlerContext) {
        print("LibTCPHandler.channelReadComplete")
        if readData.count <= 0 {return}
        
        //let sss:String = String(decoding: readData, as: UTF8.self)
        //print("LibTCPHandler.channelReadComplete size=[\(readData.count)] [\(sss)]")
        print("LibTCPHandler.channelReadComplete size=[\(readData.count)]")
        self.libRedisSocket.doReadComplete(readData:readData)
        readData.removeAll()
    }
    
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        //print("LibTCPHandler.channelRead")
        var buffer:InboundIn = unwrapInboundIn(data)
        let readableBytes:Int = buffer.readableBytes
        
        guard let dataReadBytes:[UInt8] = buffer.readBytes(length: readableBytes) else {
            print("LibTCPHandler.channelRead.ERROR")
            return
        }
        
        //let sss:String = String(decoding: dataReadBytes[dataReadBytes.startIndex..<dataReadBytes.endIndex], as: UTF8.self)
        //print("LibTCPHandler.channelRead [\(sss)]")
        readData.append(contentsOf: dataReadBytes)
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("error: \(error.localizedDescription)")
    }
}
