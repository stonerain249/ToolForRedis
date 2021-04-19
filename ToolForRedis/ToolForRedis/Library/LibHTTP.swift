import Cocoa


// MARK: - 상수들
let LibHTTP_TIMEOUT: TimeInterval = 300.0
let LibHTTP_CRLF: String = "\r\n"
let LibHTTP_BOUNDARY: String = "BOUNDARY***hotelnow__!__hotelnow***"
let LibHTTP_DELIMITER: String = "--\(LibHTTP_BOUNDARY)\(LibHTTP_CRLF)"
let LibHTTP_CHARSET: CharacterSet = CharacterSet.urlQueryAllowed;


// MARK: - http method
enum LibHttpMethod
{
    case get, post, post_json, post_multipart, put, put_json, delete, delete_json
    
    func getMethod() -> String
    {
        switch self
        {
        case .get: return "GET"
        case .post, .post_json, .post_multipart: return "POST"
        case .put, .put_json: return "PUT"
        case .delete, .delete_json: return "DELETE"
        }
    }
}



// MARK: - 통신후 결과를 LibAPI에 전달할 protocol
protocol LibHTTPProtocol
{
    func doHTTPDataDidReceive(flag:String?, httpResponseCode:Int, data:Data?) -> Void
    func doHTTPDataDidError(flag:String?, error:Error?, data:Data?) -> Void
}



// MARK: - LibHTTP
class LibHTTP
{
    var libHTTPProtocol: LibHTTPProtocol;
    var flag:String?

    /**
     * init
     */
    init(libHTTPProtocol:LibHTTPProtocol, flag:String?)
    {
        self.libHTTPProtocol = libHTTPProtocol
        self.flag = flag
    }
    

    /**
     * doHTTP
     */
    func doHTTP(sURL:String, dicQueryStr:Dictionary<String, String>?, dicData:Dictionary<String, Any>?, method:LibHttpMethod)
    {
        var bJson: Bool = false
        var bMultipart: Bool = false
        
        switch method {
        case .post_json: bJson = true
        case .put_json: bJson = true
        case .delete_json: bJson = true
        case .post_multipart: bMultipart = true
        default: ()
        }

        // 전체 주소
        var sURLFull: String = "\(sURL)?"
        
        // 주소에 변환해야 할 문자열이 있는 경우
        if let dic = dicQueryStr
        {
            for(sKey, sValue) in dic
            {
                if let r:Range<String.Index> = sURLFull.range(of: sKey)
                {
                    sURLFull.replaceSubrange(r, with: sValue)
                }
                else
                {
                    sURLFull.append("\(sKey)=\(sValue)&")
                }
            }
        }
        
        if sURLFull.hasSuffix("?")
        {
            sURLFull = String(sURLFull[sURLFull.startIndex..<sURLFull.index(before: sURLFull.endIndex)])
        }
        
        // GET 일때
        if(method == LibHttpMethod.get)
        {
            if(dicData != nil)
            {
                for(sKey, sValue) in dicData!
                {
                    sURLFull.append("\(sKey)=\(sValue)&")
                }
            }
            
            let url: URL = URL.init(string: sURLFull.addingPercentEncoding(withAllowedCharacters: LibHTTP_CHARSET)!)!
            doPrint("url \(method)=[\(url.absoluteString)]")
            
            var urlRequest: URLRequest = URLRequest.init(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: LibHTTP_TIMEOUT)
            urlRequest.httpMethod = method.getMethod()
            doMakeSession(urlRequest: &urlRequest)
            return
        }
        
        // POST, PUT, DELETE 일때
        let url: URL = URL.init(string: sURLFull.addingPercentEncoding(withAllowedCharacters: LibHTTP_CHARSET)!)!
        doPrint("url \(method)=[\(url.absoluteString)]")
        
        var urlRequest: URLRequest = URLRequest.init(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: LibHTTP_TIMEOUT)
        urlRequest.httpMethod = method.getMethod()
        
        if(bMultipart)
        {
            var dataBody: Data = Data();
            
            if let dicDataTemp = dicData
            {
                for(sKey, anyValue) in dicDataTemp
                {
                    // 문자열일때
                    if anyValue is String
                    {
                        let dataTemp: String = String("Content-Disposition: form-data; name=\"\(sKey)\"\(LibHTTP_CRLF)\(LibHTTP_CRLF)\(anyValue)\(LibHTTP_CRLF)");
                        dataBody.append(LibHTTP_CRLF.data(using: String.Encoding.utf8)!)
                        dataBody.append(dataTemp.data(using: String.Encoding.utf8)!)
                        doPrint("multipart_data = [\(sKey)] [\(anyValue)]")
                    }
                    
                    // 이미지일때
//                    if anyValue is UIImage
//                    {
//                        let dataTemp: Data? = (anyValue as! UIImage).jpegData(compressionQuality: 0.5)
//                        let data1 = "Content-Disposition: form-data; name=\"\(sKey)\";filename=\"image.jpg\"\(LibHTTP_CRLF)"
//                        let data2 = "Content-Type: image/jpeg\(LibHTTP_CRLF)\(LibHTTP_CRLF)"
//                        dataBody.append(LibHTTP_CRLF.data(using: String.Encoding.utf8)!)
//                        dataBody.append(data1.data(using: String.Encoding.utf8)!)
//                        dataBody.append(data2.data(using: String.Encoding.utf8)!)
//                        dataBody.append(dataTemp!)
//                        doPrint("multipart_data = [\(sKey)] [\(dataTemp!.count) bytes]")
//                    }
                }
            }
            
            let dataTemp: String = "--\(LibHTTP_BOUNDARY)--\(LibHTTP_CRLF)"
            dataBody.append(dataTemp.data(using: String.Encoding.utf8)!)
            urlRequest.httpBody = dataBody
            urlRequest.addValue("multipart/form-data;boundary=\(LibHTTP_BOUNDARY)", forHTTPHeaderField: "Content-Type")
        }
        // json 으로 넘겨야 할 경우
//        else if(bJson)
//        {
//            var sBodyValue: String = ""
//            if let dicDataTemp = dicData
//            {
//                sBodyValue = JSON(dicDataTemp).rawString() ?? ""
//            }
//            urlRequest.httpBody = sBodyValue.data(using: String.Encoding.utf8)
//            urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
//            doPrint("json_data=[\(sBodyValue)]")
//        }
        // 일반적인 방식으로 넘겨야 할 경우
        else
        {
            var sBodyValue: String = ""
            if let dicDataTemp = dicData
            {
                for(sKey, anyValue) in dicDataTemp
                {
                    let sValue = anyValue as! String
                    sBodyValue.append("\(sKey)=\(sValue.addingPercentEncoding(withAllowedCharacters: LibHTTP_CHARSET)!)&")
                }
            }
            urlRequest.httpBody = sBodyValue.data(using: String.Encoding.utf8)
            urlRequest.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            doPrint("post_data=[\(sBodyValue)]")
        }
        
        urlRequest.httpMethod = method.getMethod()
        doMakeSession(urlRequest: &urlRequest)
    }
    
    
    /**
     * URLSession 생성. 시작
     */
    private func doMakeSession(urlRequest: inout URLRequest)
    {
        func completionHandler(data: Data?, response: URLResponse?, error:Error?) -> Void
        {
            // 에러
            if let error = error
            {
                doPrint("error")
                doPrint(error)
                
                //error.localizedDescription
                //let s: String = "{\"result\":\"fail\", \"errorMsg\":\"error code=\(error)\"}"
                libHTTPProtocol.doHTTPDataDidError(flag: self.flag, error: error, data: nil)
                return
            }

            let res:HTTPURLResponse = response as! HTTPURLResponse
            if res.statusCode != 200
            {
                doPrint("*** http status code = [\(res.statusCode)]")
            }
            
            // 성공
            libHTTPProtocol.doHTTPDataDidReceive(flag: self.flag, httpResponseCode: res.statusCode, data: data)
        }
        
        // request header에 access token 넣음.
//        let atoken:String = LibLocalData.doAccessTokenGet()
//        if atoken.count > 0
//        {
//            urlRequest.setValue(atoken, forHTTPHeaderField: "atoken")
//        }
        
        // request header에 refresh token 넣음.
//        let rtoken:String = LibLocalData.doRefreshTokenGet()
//        if rtoken.count > 0
//        {
//            urlRequest.setValue(rtoken, forHTTPHeaderField: "rtoken")
//        }

        let sessionConfig: URLSessionConfiguration = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = LibHTTP_TIMEOUT
        let session: URLSession = URLSession.init(configuration: sessionConfig, delegate: nil, delegateQueue: OperationQueue.main)
        //let sessionDataTask = session.dataTask(with: urlRequest, completionHandler: closureSessionDone)
        let sessionDataTask = session.dataTask(with: urlRequest, completionHandler: completionHandler)
        sessionDataTask.resume()
        session.finishTasksAndInvalidate()
    }
}
