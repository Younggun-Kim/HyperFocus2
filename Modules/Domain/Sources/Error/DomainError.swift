/// 계층을 넘어 Feature까지 올라가는 공통 에러.
///
/// Data가 `APIError`·저장소 에러를 이 타입으로 바꿔서 던진다. 사용자 문구는 넣지 않는다(Feature가 만든다).
public enum DomainError: Error, Sendable, Equatable {
    /// 서버에 닿지 못함(오프라인, 타임아웃)
    case offline
    /// 인증 없음 또는 만료. 화면 이동은 App의 `RootFeature`가 맡는다
    case unauthorized
    /// 찾는 데이터가 없음
    case notFound
    /// 서버가 요청을 거절함(잘못된 값)
    case invalid
    /// 그 밖의 실패. 원본은 Data가 로깅한다
    case unknown
}
