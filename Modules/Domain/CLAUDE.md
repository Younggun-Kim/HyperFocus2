# Domain

Entity, Repository 포트, UseCase를 두는 모듈. 공통 규칙은 루트 `CLAUDE.md`를 따른다.

## 경계

- 내부 모듈에 의존하지 않는다. 쓸 수 있는 외부 의존성은 swift-dependencies(`Dependencies`, `DependenciesMacros`)뿐이다.
- `SwiftData`, `Moya`, `Alamofire`, `CoreNetwork`를 import하지 않는다. 보이면 경계가 샌 것이다.

## 타입 규칙

- Entity는 `public struct` + `Sendable, Equatable, Identifiable` + 직접 쓴 `public init`. 계정마다 하나뿐인 값(예: `AppSetting`)은 `Identifiable`을 빼도 된다. 저장 방식(SwiftData, API)에 의존하는 타입을 넣지 않는다.
- Repository 포트와 UseCase는 `@DependencyClient` struct로 만들고, 이름은 `XxxRepository` / `XxxUseCase`, 시그니처는 처음부터 `async throws`.
- 모든 Repository 앞에는 UseCase를 둔다. 단순 위임이어도 만든다(Feature의 진입점을 UseCase로 통일).
- **UseCase 선언과 `liveValue`는 같은 파일에 둔다.** Feature가 선언을 참조할 때 구현도 함께 링크되게 하기 위해서다. Repository의 `liveValue`는 여기 두지 않는다(Data에 둔다).
- 비즈니스 규칙과 여러 Repository 조합은 UseCase `liveValue`에 둔다. 여러 Feature가 함께 쓰는 순수 계산은 Entity extension이나 순수 함수로 둔다.

## 에러

- UseCase는 Domain 에러만 던진다.
  - 공통: `DomainError`(`offline`, `unauthorized`, `notFound`, `invalid`, `unknown` 등)
  - 비즈니스 규칙 위반: UseCase별 enum(예: `FocusSessionError.alreadyRunning`), UseCase에서 던진다.
- 에러 타입은 `Sendable, Equatable`로 만들어 `TestStore`에서 비교할 수 있게 한다. 사용자 문구는 넣지 않는다.
- 세션 만료는 UseCase(예: `SessionEventUseCase`의 `AsyncStream`)로 앱 전역 이벤트로 노출한다.

## 테스트

- UseCase: Repository mock을 주입해 비즈니스 규칙을 검증한다.
