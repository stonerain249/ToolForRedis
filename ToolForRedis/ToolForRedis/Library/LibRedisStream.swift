//
//  LibRedisStream.swift
//  swleeTest
//
//  Created by swlee on 2020/12/23.
//

import Cocoa

class LibRedisStream: NSObject, StreamDelegate {
/*
    private var libRedis:LibRedis
    private var responseData:Data = Data()
    
    var inputStream: InputStream!
    var outputStream: OutputStream!
    var libRedisCommand:LibRedisCommand?


    init(libRedis:LibRedis) {
        self.libRedis = libRedis
    }
    
    
    // MARK: - StreamDelegate

    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        
        if aStream == inputStream {
            switch eventCode {
            case Stream.Event.openCompleted:
                print("inputStream.Stream.Event.openCompleted")
            case Stream.Event.hasSpaceAvailable:
                print("inputStream.Stream.Event.hasSpaceAvailable")
            
            case Stream.Event.hasBytesAvailable:
                print("inputStream.Stream.Event.hasBytesAvailable")
                
                while inputStream.hasBytesAvailable {
                    // 방법1.
//                    var readBytes:Int = 0
//                    let data = NSMutableData(length: RESPONSE_BUFFER_SIZE)!
//                    let op = OpaquePointer(data.mutableBytes)
//                    let buffer = UnsafeMutablePointer<UInt8>(op)
//                    readBytes = inputStream.read(buffer, maxLength: RESPONSE_BUFFER_SIZE)
//                    print("inputStream.Stream.Event.hasBytesAvailable.\(readBytes)")
//                    if readBytes < 0, let error = inputStream.streamError {
//                        print("------------------------error")
//                        print(error)
//                        print("------------------------")
//                        break
//                    }
//                    data.length = readBytes
//                    //responseData.append(data as Data)
                    
                    
                    // 방법2. 이게 좀더 간단하네.
                    var buffer = [UInt8](repeating :0, count : RESPONSE_BUFFER_SIZE)
                    let bytesRead = inputStream.read(&buffer, maxLength: RESPONSE_BUFFER_SIZE) // UnsafeMutablePointer<UInt8>
                    var dropCount = RESPONSE_BUFFER_SIZE - bytesRead
                    if dropCount < 0 {
                        dropCount = 0
                    }
                    let chunk = buffer.dropLast(dropCount)
                    if chunk.count > 0 {
                        responseData.append(contentsOf: chunk)
                    }
                }
                
                if responseData.count <= 0 {return}
                
                switch self.libRedisCommand {
                case .auth : libRedis.doParsingResponse_Auth(responseData: &responseData)
                case .select : libRedis.doParsingResponse_Select(responseData: &responseData)
                case .scan : libRedis.doParsingResponse_Scan(responseData: &responseData)
                case .type : libRedis.doParsingResponse_Type(responseData: &responseData)
                case .get : libRedis.doParsingResponse_Get(responseData: &responseData)
                case .set : libRedis.doParsingResponse_Set(responseData: &responseData)
                case .ttl : libRedis.doParsingResponse_Ttl(responseData: &responseData)
                case .expire : libRedis.doParsingResponse_Expire(responseData: &responseData)
                case .persist : libRedis.doParsingResponse_Persist(responseData: &responseData)
                case .info : libRedis.doParsingResponse_Info(responseData: &responseData)
                case .configGet : libRedis.doParsingResponse_ConfigGet(responseData: &responseData)
                case .configSet : libRedis.doParsingResponse_ConfigSet(responseData: &responseData)
                case .renamenx : libRedis.doParsingResponse_Renamenx(responseData: &responseData)
                case .del : libRedis.doParsingResponse_Del(responseData: &responseData)

                case .lrange : libRedis.doParsingResponse_Lrange(responseData: &responseData)
                case .lset : libRedis.doParsingResponse_Lset(responseData: &responseData)
                case .rpush : libRedis.doParsingResponse_Rpush(responseData: &responseData)
                case .lrem : libRedis.doParsingResponse_Lrem(responseData: &responseData)
                
                //case .smembers : LibRedis.doParsingResponse_Smembers(responseData: &responseData)
                case .sscan : libRedis.doParsingResponse_Sscan(responseData: &responseData)
                case .sadd : libRedis.doParsingResponse_Sadd(responseData: &responseData)
                case .srem : libRedis.doParsingResponse_Srem(responseData: &responseData)
                    
                //case .hgetall : LibRedis.doParsingResponse_Hgetall(responseData: &responseData)
                case .hscan : libRedis.doParsingResponse_Hscan(responseData: &responseData)
                case .hset : libRedis.doParsingResponse_Hset(responseData: &responseData)
                case .hdel : libRedis.doParsingResponse_Hdel(responseData: &responseData)

                case .zrange : libRedis.doParsingResponse_Zrange(responseData: &responseData)
                case .zadd : libRedis.doParsingResponse_Zadd(responseData: &responseData)
                case .zrem : libRedis.doParsingResponse_Zrem(responseData: &responseData)

                case .pubsubChannels : libRedis.doParsingResponse_PubSubChannels(responseData: &responseData)
                case .subscribe : libRedis.doParsingResponse_Subscribe(responseData: &responseData)
                case .psubscribe : libRedis.doParsingResponse_Subscribe(responseData: &responseData)
                case .unsubscribe : libRedis.doParsingResponse_Unsubscribe(responseData: &responseData)
                case .punsubscribe : libRedis.doParsingResponse_Unsubscribe(responseData: &responseData)
                case .publish : libRedis.doParsingResponse_Publish(responseData: &responseData)
                    
                case ._consoleCommand : libRedis.doParsingResponse_ConsoleCommand(responseData: &responseData)
                case .none: break
                }

            // 연결이 종료되었을때.
            case Stream.Event.endEncountered:
                print("inputStream.Stream.Event.endEncountered")
                libRedis.doDisconnected()

            case Stream.Event.errorOccurred:
                print("inputStream.Stream.Event.errorOccurred")
                libRedis.doConnectResult(connResult: false)
            default:
                print("inputStream.default")
            }
        }

        if(aStream == outputStream) {
            switch eventCode {
            case Stream.Event.openCompleted:
                print("outputStream.Stream.Event.openCompleted")
                libRedis.doConnectResult(connResult: true)
            case Stream.Event.hasSpaceAvailable:
                print("outputStream.Stream.Event.hasSpaceAvailable")
            case Stream.Event.hasBytesAvailable:
                print("outputStream.Stream.Event.hasBytesAvailable")
            case Stream.Event.endEncountered:
                print("outputStream.Stream.Event.endEncountered")
            case Stream.Event.errorOccurred:
                print("outputStream.Stream.Event.errorOccurred")
                libRedis.doConnectResult(connResult: false)
            default:
                print("outputStream.default")
            }
        }
    }
*/
}
