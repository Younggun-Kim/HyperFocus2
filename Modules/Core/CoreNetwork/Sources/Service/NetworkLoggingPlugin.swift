import Foundation
import Moya
import os

/// 요청과 응답을 `os.Logger`로 남기는 Moya 플러그인.
///
/// - 헤더는 찍지 않는다. `Authorization`에 토큰이 들어 있다.
/// - 요청·응답 본문에는 토큰과 사용자 데이터가 들어갈 수 있다. `.debug` 레벨(기기에 남지 않음)에
///   기본값 `privacy: .private`로만 찍는다.
/// - 토큰 갱신 후 재시도는 Alamofire 안에서 일어나므로 이 플러그인에는 요청 한 번으로 보인다.
struct NetworkLoggingPlugin: PluginType {
    /// 본문을 이 바이트 수까지만 찍는다. 파일 응답 같은 큰 본문이 로그를 채우지 않게 한다.
    static let bodyLimit = 1024

    func willSend(_ request: RequestType, target: TargetType) {
        let method = target.method.rawValue
        Logger.network.debug("→ \(method) \(target.path)")
        if let body = Self.bodyDescription(request.request?.httpBody) {
            Logger.network.debug("→ \(method) \(target.path) body: \(body)")
        }
    }

    func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
        let method = target.method.rawValue

        switch result {
        case .success(let response):
            Logger.network.info("← \(response.statusCode) \(method) \(target.path) (\(response.data.count) bytes)")
            logBody(response.data, method: method, target: target)

        case .failure(let error):
            let apiError = APIError.from(error)
            switch apiError {
            case .cancelled:
                // 취소는 흐름이다. 실패로 남기지 않는다.
                Logger.network.debug("← 취소 \(method) \(target.path)")
            default:
                Logger.network.error("← 실패 \(method) \(target.path): \(String(describing: apiError))")
            }
            if let data = error.response?.data {
                logBody(data, method: method, target: target)
            }
        }
    }

    private func logBody(_ data: Data, method: String, target: TargetType) {
        guard let body = Self.bodyDescription(data) else { return }
        Logger.network.debug("← \(method) \(target.path) body: \(body)")
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
