import Cocoa
import NIO
//import NIOTransportServices



// =============================================================================
// MARK: Helpers

struct CustomError: LocalizedError, CustomStringConvertible {
    var title:String
    var code:Int
    var description: String { errorDescription() }
    
    init(title:String?, code:Int) {
        self.title = title ?? "Error"
        self.code = code
    }
    
    func errorDescription()->String {
        "\(title) (\(code))"
    }
}



// =============================================================================
// MARK: Async code

func asyncDownload(on ev: EventLoop, urlString: String) -> EventLoopFuture<String> {
    // Prepare the promise
    let promise = ev.makePromise(of: String.self)

    // Do the async work
    let url = URL(string: urlString)!

    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        print("Loading \(url)")
        if let error = error {
            promise.fail(error)
            return
        }
        if let httpResponse = response as? HTTPURLResponse {
            if (200...299).contains(httpResponse.statusCode) {
                if let mimeType = httpResponse.mimeType, mimeType == "text/html",
                    let data = data,
                    let string = String(data: data, encoding: .utf8) {
                    promise.succeed(string)
                    return
                }
            } else {
                // TODO: Analyse response for better error handling
                let httpError = CustomError(title: "HTTP error", code: httpResponse.statusCode)
                promise.fail(httpError)
                return
            }
        }
        let err = CustomError(title: "no or invalid data returned", code: 0)
        promise.fail(err)
    }
    task.resume()

    // Return the promise of a future result
    return promise.futureResult
}

// =============================================================================
// MARK: Main

print("System cores: \(System.coreCount)\n")
let evGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

var futures: [EventLoopFuture<String>] = []

for url in ["https://www.process-one.net/en/", "https://www.remond.im", "https://swift.org"] {
    let ev = evGroup.next()
    let future = asyncDownload(on: ev, urlString: url)
    futures.append(future)
}


let futureResult = EventLoopFuture.reduce(0, futures, on: evGroup.next()) { (count: Int, page: String) -> Int in
    let tok =  page.components(separatedBy:"<div")
    let p_count = tok.count-1
    return count + p_count
}

futureResult.whenSuccess { count in
    print("Result = \(count)")
}
futureResult.whenFailure { error in
    print("Error: \(error)")
}

futureResult.
// Timeout: As processing is async, we can handle timeout by just waiting in
// main thread before quitting.
// => Waiting 10 seconds for completion
sleep(10)

try evGroup.syncShutdownGracefully()

