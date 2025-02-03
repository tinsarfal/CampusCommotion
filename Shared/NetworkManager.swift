import Alamofire
import KeychainSwift

class AuthTokenInterceptor: RequestInterceptor {
    private let token: String

    init(token: String) {
        self.token = token
    }

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        guard let host = urlRequest.url?.host, host == "canvas.example.edu" else {
            completion(.success(urlRequest))
            return
        }
        var urlRequest = urlRequest
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        completion(.success(urlRequest))
    }
}

class NetworkManager {
    static let shared: Session = {
        let configuration = URLSessionConfiguration.af.default
        configuration.timeoutIntervalForRequest = 5
        
        let keychain = KeychainSwift()
        keychain.accessGroup = "group.com.example.CampusCommotion"
        let token = keychain.get("token") ?? ""
        print("Token Used: " + token)
        
        let interceptor = AuthTokenInterceptor(token: token)
        let session = Session(configuration: configuration, interceptor: interceptor)
        return session
    }()
}
