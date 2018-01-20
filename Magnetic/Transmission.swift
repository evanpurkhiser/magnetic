import Foundation

let TOKEN_HEADER = "x-transmission-session-id"

var lastSessionToken: String?

struct TorrentAdd: Codable {
    // TODO: does it need to have let?
    let filename:URL
}

struct TransmissionRequest: Codable {
    let method: String
    let arguments: TorrentAdd
}

public enum TransmissionResponse {
    case success
    case forbidden
    case configError
    case failed
}

public typealias TransmissionConfig = URLComponents

// Send a torrent magnet URL to transmission
public func addTorrent(fileUrl: URL, config: TransmissionConfig, onAdd: @escaping (TransmissionResponse) -> Void) -> Void {
    var url = config
    url.scheme = "https"
    url.path = "/transmission/rpc"
    url.port = config.port ?? 443

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
        if error != nil {
            return onAdd(TransmissionResponse.configError)
        }

        let httpResp = resp as? HTTPURLResponse

        switch httpResp?.statusCode {
        // If our session token is invalid transmission will tell us,
        // we'll store the new one and make the request again
        case 409?:
            // Proxy services like CloudFlare may make the keys lowercase,
            // Transmission does not. Normalize them (lowercase is good, http2ish)
            let mixedHeaders = httpResp?.allHeaderFields as! [String: Any]
            let headers = Dictionary(uniqueKeysWithValues: mixedHeaders.map { ($0.0.lowercased(), $0.1) })

            lastSessionToken = headers[TOKEN_HEADER] as? String
            addTorrent(fileUrl: fileUrl, config: config, onAdd: onAdd)
            return
        case 401?:
            return onAdd(TransmissionResponse.forbidden)
        case 200?:
            return onAdd(TransmissionResponse.success)
        default:
            return onAdd(TransmissionResponse.failed)
        }
    }

    task.resume()
}
