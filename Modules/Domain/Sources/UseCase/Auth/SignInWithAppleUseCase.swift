import Dependencies
import DependenciesMacros

/// Apple 계정으로 로그인한다.
///
/// 1. 토큰이 없으면 익명 계정부터 받는다. 연동은 익명 토큰으로 요청하기 때문이다.
/// 2. 익명 계정에 Apple 연동을 시도한다. 처음 쓰는 Apple 계정은 여기서 가입된다.
/// 3. 이미 연동된 Apple 계정이면(`conflict`) 그 계정으로 로그인한다.
///
/// 로그인만 먼저 시도하면, 처음 쓰는 Apple 계정은 "등록되지 않은 계정"으로 막혀 가입할 수 없다.
@DependencyClient
public struct SignInWithAppleUseCase: Sendable {
    public var execute: @Sendable (_ request: AppleSignInRequest) async -> Result<Void, DomainError> = { _ in .failure(.unknown) }
}

extension DependencyValues {
    public var signInWithAppleUseCase: SignInWithAppleUseCase {
        get { self[SignInWithAppleUseCase.self] }
        set { self[SignInWithAppleUseCase.self] = newValue }
    }
}

// UseCase의 구현은 Repository 포트만 쓰므로 Domain 안에서 끝난다.
// 선언과 같은 파일에 두어 Feature가 선언을 참조하면 liveValue도 함께 링크되게 한다.
extension SignInWithAppleUseCase: DependencyKey {
    public static let liveValue = Self(
        execute: { request in
            @Dependency(\.authRepository) var authRepository
            if !authRepository.hasToken() {
                if case .failure(let error) = await authRepository.signInAnonymously() {
                    return .failure(error)
                }
            }
            let linked = await authRepository.linkApple(request)
            guard case .failure(.conflict) = linked else { return linked }
            return await authRepository.signInWithApple(request)
        }
    )
    public static let testValue = Self()
    public static let previewValue = liveValue
}
