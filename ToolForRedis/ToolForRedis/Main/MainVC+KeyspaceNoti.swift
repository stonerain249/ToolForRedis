//
//  MainVC+KeyspaceNoti.swift
//  RedClient
//
//  Created by swlee on 2021/02/09.
//

import Cocoa

extension MainVC {
    
    internal func doKeyspaceNotificationConnect() {
        guard let serverInfo = self.serverInfo else {return}
        libRedisSub = LibRedis()

        LibRedis.doMakeConnection(libRedises: [self.libRedisSub!],
                                  serverInfo: serverInfo) { (result:Bool, uuid:UUID) in
            // 연결 실패.
            if !result {
                //self.tfServer.stringValue = "CONNECTION FAIL !"
                let msg:String = "CONNECTION FAIL !"
                doAlertShow(message: msg, informativeText: nil, buttons: ["OK"])
                return
            }
            
            // 연결 성공.
            self.doKeyspaceNotificationConfigSet()
        } closureResultDisconnected: { (uuid:UUID) in
            let msg:String = "The connection has been closed."
            doAlertShow(message: msg, informativeText: nil, buttons: ["OK"])
        }
    }
    
    internal func doKeyspaceNotificationConfigSet() {
        //LibRedis.doAdd(.configSet(configCmd: "notify-keyspace-events", configOption: "AKE", continueOnError: false) { (result:String) in
        LibRedis.doAdd(.configSet(configCmd: "notify-keyspace-events", configOption: "AK", continueOnError: false) { (result:String) in
            print("config set result [\(result)]")
            self.doKeyspaceNotificationSubscribe()
        })
        LibRedis.doSend(libRedisSocket:libRedisSub!.libRedisSocket)
    }
    
    
    internal func doKeyspaceNotificationSubscribe() {
        let pattern:String = LibRedisCommand.doGetKeySpaceNotiChannel(dbNo: self.logicalDbNo) + ":*"
        let keyspaceChannel:String = LibRedisCommand.doGetKeySpaceNotiChannel(dbNo: self.logicalDbNo) + ":"
        LibRedis.doAdd(.psubscribe(pattern: pattern) { (pmsgInfo:[(kind: String, channelName: String, key:String, cmd: String)]) in
            print(pmsgInfo)
            var keyName1:String = ""
            var keyName2:String = ""
            for (_, _, key, cmd) in pmsgInfo {
                let keyName:String = key.replacingOccurrences(of: keyspaceChannel, with: "")
                if cmd == "rename_from" {
                    keyName1 = keyName
                    continue
                }
                
                if cmd == "rename_to" {
                    keyName2 = keyName
                    self.doKeyspaceNotificationSubscribeProc(keyName1: keyName1, keyName2:keyName2, cmd: cmd)
                    continue
                }
                
                keyName1 = keyName
                keyName2 = ""
                self.doKeyspaceNotificationSubscribeProc(keyName1: keyName1, keyName2:keyName2, cmd: cmd)
            }
        })
        
//        pattern = LibRedisCommand.doGetKeyEventNotiChannel(dbNo: logicalDbNo) + ":*"
//        LibRedis.doAdd(.psubscribe(pattern: pattern) { (kind: String, channelName: String, key:String, cmd: String) in
//            print("*** keyevent")
//            print("psubscribe set kind [\(kind)]")
//            print("psubscribe set channelName [\(channelName)]")
//            print("psubscribe set key [\(key)]")
//            print("psubscribe set cmd [\(cmd)]")
//
//            let s:String = LibRedisCommand.doGetKeySpaceNotiChannel(dbNo: self.logicalDbNo) + ":"
//            let keyName:String = key.replacingOccurrences(of: s, with: "")
//            //self.doKeyspaceNotificationSubscribeProc(keyName: keyName, cmd: cmd)
//        })
        
        LibRedis.doSend(libRedisSocket: libRedisSub!.libRedisSocket)
    }
    
    
    
    internal func doKeyspaceNotificationSubscribeProc(keyName1:String, keyName2:String, cmd:String) {
        // common
        if cmd == "del" || cmd == "expired" {
            let index:Int = self.doGetKeyinfoIndex(keyName: keyName1)
            if index < 0 {return} // 없는 키 : 그냥 리턴.
            keyInfoArray.remove(at: index)
            tvRedis.removeRows(at: IndexSet(integer: index), withAnimation: .effectFade)
        }
        
        if cmd == "rename_to" {
            let index:Int = self.doGetKeyinfoIndex(keyName: keyName1)
            if index < 0 {return} // 없는 키 : 그냥 리턴.
            keyInfoArray[index].keyName = keyName2
            keyInfoArray[index].keyNameUtf8 = keyName2
            keyInfoArray[index].keyNameData = keyName2.data(using: .utf8)!
            tvRedis.reloadData(forRowIndexes: IndexSet(integer: index), columnIndexes: IndexSet(integer: 2))
        }
        
        // string
        if cmd == "set" ||
           cmd == "lset" || cmd == "rpush" || cmd == "lpush" ||
           cmd == "sadd" ||
           cmd == "hset" ||
           cmd == "zadd" {
            let index:Int = self.doGetKeyinfoIndex(keyName: keyName1)
            if index >= 0 {return} // 이미 존재하는 키 : 그냥 리턴
            var keyInfo:KeyInfo = KeyInfo()
            keyInfo.keyName = keyName1
            keyInfo.keyNameUtf8 = keyName1
            keyInfo.keyNameData = keyName1.data(using: .utf8)!
            
            if cmd == "set" {keyInfo.keyType = RedisDataType.string.rawValue}
            if cmd == "lset" || cmd == "rpush" || cmd == "lpush" {keyInfo.keyType = RedisDataType.list.rawValue}
            if cmd == "sadd" {keyInfo.keyType = RedisDataType.set.rawValue}
            if cmd == "hset" {keyInfo.keyType = RedisDataType.hash.rawValue}
            if cmd == "zadd" {keyInfo.keyType = RedisDataType.zset.rawValue}

            keyInfoArray.append(keyInfo)
            tvRedis.insertRows(at: IndexSet(integer: tvRedis.numberOfRows), withAnimation: .effectFade)
        }

        if cmd == "lrem" {}
        if cmd == "srem" {}
        if cmd == "hdel" {}
        if cmd == "zrem" {}
    }
    
    
    
    internal func doGetKeyinfoIndex(keyName:String) -> Int {
        var index:Int = -1
        for (n, keyInfo) in keyInfoArray.enumerated() {
            if keyName != keyInfo.keyName {continue}
            index = n
        }
        return index
    }
    
    
    // MARK: - unsubscribe, disconnect
    internal func doKeyspaceNotificationDisconnect() {
        let pattern:String = LibRedisCommand.doGetKeySpaceNotiChannel(dbNo: self.logicalDbNo) + ":*"
        LibRedis.doAdd(.punsubscribe(pattern: pattern) { (result:String) in
            print("punsubscribe result [\(result)]")
            //self.libRedisSub?.libRedisSocket = nil
            self.libRedisSub = nil
        })
        LibRedis.doSend(libRedisSocket:libRedisSub!.libRedisSocket)
    }

}
