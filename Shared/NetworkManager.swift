import Alamofire

class NetworkManager {
    static let shared: Session = {
        let configuration = URLSessionConfiguration.af.default
        configuration.timeoutIntervalForRequest = 5
        let session = Session(configuration: configuration)
        return session
    }()
}
