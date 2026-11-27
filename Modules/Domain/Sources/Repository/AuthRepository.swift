import Dependencies
import DependenciesMacros

/// 인증 포트. 구현(`liveValue`)은 Data 모듈에 둔다.
/// 발급받은 토큰은 Data 안에서 저장하고 끝낸다. Domain은 토큰 값을 다루지 않는다.
/// Feature는 이 타입을 직접 쓰지 않고 UseCase를 통해서만 접근한다.
@DependencyClient
public struct AuthRepository: Sendable {
    /// 저장된 토큰(익명 포함)이 있는지
    public var hasToken: @Sendable () -> Bool = { false }
    /// 기기 식별자로 익명 계정을 만들거나 다시 받는다.
    public var signInAnonymously: @Sendable () async -> Result<Void, DomainError> = { .failure(.unknown) }
    /// 지금 계정(익명)에 Apple 계정을 연동한다. 이미 다른 계정에 연동된 Apple 계정이면 `DomainError.conflict`.
    public var linkApple: @Sendable (_ request: AppleSignInRequest) async -> Result<Void, DomainError> = { _ in .failure(.unknown) }
    /// 이미 연동된 Apple 계정으로 로그인한다.
    public var signInWithApple: @Sendable (_ request: AppleSignInRequest) async -> Result<Void, DomainError> = { _ in .failure(.unknown) }
    /// 회원 정보 조회
    public var fetchProfile: @Sendable () async -> Result<Profile, DomainError> = { .failure(.unknown) }
}

extension DependencyValues {
    public var authRepository: AuthRepository {
        get { self[AuthRepository.self] }
        set { self[AuthRepository.self] = newValue }
    }
}

extension AuthRepository: TestDependencyKey {
    public static let testValue = Self()
    public static let previewValue = Self(
        hasToken: { true },
        signInAnonymously: { .success(()) },
        linkApple: { _ in .success(()) },
        signInWithApple: { _ in .success(()) },
        fetchProfile: { .success((Profile.mock)) },
    )
}
