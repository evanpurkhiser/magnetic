import Foundation

let TOKEN_HEADER = "X-Transmission-Session-Id"

var lastSessionToken: String?

struct TorrentAdd: Codable {
    // TODO: does it need to have let?
    let filename:URL
}

struct TransmissionRequest: Codable {
    let method: String
    let arguments: TorrentAdd
}

enum TransmissionResponse {
    case success
    case timeout
    case forbidden
    case configError
}

// Configuration for talking to transmission is simply a URL configurtion
public typealias TransmissionConfig = URLComponents

// Send a torrent magnet URL 
public func addTorrent(fileUrl: URL, config: TransmissionConfig) -> Void {
    var url = config
    url.path = "/transmission/rpc"
    url.scheme = url.scheme ?? "http"
    
    let setTorrentBody = TransmissionRequest(
        method: "torrent-add",
        arguments: TorrentAdd(filename: fileUrl)
    )
    
    var req = URLRequest(url: url.url!)
    req.httpMethod = "POST"
    req.httpBody = try? JSONEncoder().encode(setTorrentBody)
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.setValue(lastSessionToken, forHTTPHeaderField: TOKEN_HEADER)
    
    let task = URLSession.shared.dataTask(with: req) { (data, resp, error) in
        // TODO: Handle error here
        
        let httpResp = resp as? HTTPURLResponse
        
        // If our session token is invalid transmission will tell us,
        // we'll store the new one and make the request again
        if httpResp?.statusCode == 409 {
            lastSessionToken = httpResp?.allHeaderFields[TOKEN_HEADER] as? String
            addTorrent(fileUrl: fileUrl, config: config)
            return
        }
        
        print(data?.description)
        
        
        
        
        
        print("TORRENT ADDED!!")
        
        
        
        
        
        
        print(httpResp!.statusCode)
    }
    
    task.resume()
}
