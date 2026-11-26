import Foundation
import os

/// 요청과 응답을 `os.Logger`로 남긴다. `APIService`가 요청 전후에 부른다.
///
/// - 헤더는 찍지 않는다. `Authorization`에 토큰이 들어 있다.
/// - 요청·응답 본문에는 토큰과 사용자 데이터가 들어갈 수 있다. `.debug` 레벨(기기에 남지 않음)에
///   기본값 `privacy: .private`로만 찍는다.
/// - 토큰 갱신 후 재시도는 Alamofire 안에서 일어나므로 요청 한 번으로 남는다.
enum NetworkLog {
    /// 본문을 이 바이트 수까지만 찍는다. 파일 응답 같은 큰 본문이 로그를 채우지 않게 한다.
    static let bodyLimit = 1024

    static func willSend(_ request: URLRequest, endpoint: some APIEndpoint) {
        let method = endpoint.method.rawValue
        Logger.network.debug("→ \(method) \(endpoint.path)")
        if let body = bodyDescription(request.httpBody) {
            Logger.network.debug("→ \(method) \(endpoint.path) body: \(body)")
        }
    }

    static func didReceive(_ data: Data, statusCode: Int?, endpoint: some APIEndpoint) {
        let method = endpoint.method.rawValue
        Logger.network.info("← \(statusCode ?? 0) \(method) \(endpoint.path) (\(data.count) bytes)")
        logBody(data, endpoint: endpoint)
    }

    static func didFail(_ error: APIError, body: Data?, endpoint: some APIEndpoint) {
        let method = endpoint.method.rawValue
        switch error {
        case .cancelled:
            // 취소는 흐름이다. 실패로 남기지 않는다.
            Logger.network.debug("← 취소 \(method) \(endpoint.path)")
        default:
            Logger.network.error("← 실패 \(method) \(endpoint.path): \(String(describing: error))")
        }
        if let body {
            logBody(body, endpoint: endpoint)
        }
    }

    private static func logBody(_ data: Data, endpoint: some APIEndpoint) {
        guard let body = bodyDescription(data) else { return }
        Logger.network.debug("← \(endpoint.method.rawValue) \(endpoint.path) body: \(body)")
    }

    /// 본문을 로그용 문자열로 바꾼다. 비었으면 nil, 길면 `bodyLimit`에서 자른다.
    static func bodyDescription(_ data: Data?, limit: Int = bodyLimit) -> String? {
        guard let data, !data.isEmpty else { return nil }
        let prefix = data.prefix(limit)
        let text = String(data: prefix, encoding: .utf8) ?? "<\(data.count) bytes, UTF-8 아님>"
        return data.count > limit ? "\(text)… (총 \(data.count) bytes)" : text
    }
}

extension Logger {
    /// CoreNetwork 공통 로거. subsystem은 번들 ID, category는 모듈 이름
    static let network = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.hyperfocus.timer", category: "CoreNetwork")
}
