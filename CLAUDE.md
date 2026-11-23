# CLAUDE.md

HyperFocus iOS 앱. Tuist로 프로젝트를 선언하고, 클린 아키텍처를 모듈로 나눈 구조다.
**프로젝트 규칙의 기준 문서는 이 파일이다.** README와 내용이 다르면 이 파일을 따른다.

> `(미적용)` 표시는 결정은 했지만 아직 코드·설정에 반영하지 않은 규칙이다. 새 코드는 이 규칙대로 작성하고, 기존 코드는 해당 작업 때 맞춘다.

## 작업 방식

- Tuist 동작은 **`mise.toml`에 고정된 4.216.2 기준** 공식 문서로 확인한다. 기억에 의존하지 않는다(예: 4.216.2의 `tuist build`는 빌드하지 않고 빌드 기록을 조회한다).
- 변경을 마치면 CI(`.github/workflows/ci.yml`)와 같은 순서(install → generate → inspect → test)로 확인한다.

```bash
tuist install                                   # 외부 의존성 (Tuist/Package.swift)
tuist generate --no-open                        # 프로젝트 생성
tuist inspect dependencies --only implicit      # 암묵적 의존 검사
tuist test <스킴> --device "iPhone 17 Pro"       # 테스트 (기본: 선택적 테스트)
tuist test --device "iPhone 17 Pro" --no-selective-testing   # CI와 같은 전체 테스트
```

## 생성물은 고치지 않는다

- `*.xcodeproj`, `*.xcworkspace`, `Derived/`(Info.plist, entitlements), `graph.png`는 생성물이다. 변경은 항상 `Project.swift`, `Tuist/ProjectDescriptionHelpers/`, `App/Configs/*.xcconfig`에서 한다.
- xcconfig에 키를 추가하면 파일 끝 줄바꿈을 확인한다. 없으면 값이 에러 없이 빈 문자열이 된다.

## 모듈 구조

```
App ──→ Feature ──→ Domain ←── Data ──→ CoreNetwork ──→ Moya / Alamofire
 │         └──→ Util
 └──→ Data   (App만 Data를 링크하고 DataModule.bootstrap() 호출)
```

| 모듈 | 의존할 수 있는 대상 | 쓸 수 있는 곳 |
| --- | --- | --- |
| App | Feature, Data, TCA | - |
| Feature | Domain, Util, TCA | App |
| Domain | swift-dependencies만 (내부 모듈 의존 없음) | Feature, Data |
| Data | Domain, CoreNetwork, swift-dependencies | App |
| CoreNetwork | Moya, Alamofire (내부 모듈 의존 없음) | Data |
| Util | 없음 | 모든 모듈 |

### 계층 규칙

- Feature는 **UseCase만** `@Dependency`로 쓴다. Repository를 직접 쓰지 않는다.
- 모든 Repository 앞에는 UseCase를 둔다. 단순 위임이어도 만든다(Feature의 진입점을 UseCase로 통일).
- Feature끼리 의존하지 않는다. 화면 이동은 부모 Reducer가 delegate 액션으로 처리한다.
- Domain은 내부 모듈에 의존하지 않는다. Feature나 Domain에 `import SwiftData`가 보이면 경계가 샌 것이다.
- Repository를 추가하면 `DataModule.bootstrap()`에 **반드시 등록**한다. 빠뜨려도 컴파일은 통과하고 런타임에 실패한다(정적 링크에서 참조되지 않는 `liveValue`가 빠지기 때문).
- UseCase 선언과 `liveValue`는 같은 파일에 둔다.
- Example 앱과 테스트는 Data를 링크하지 않고 mock을 명시적으로 주입한다.
- 새 Feature는 `tuist scaffold Feature --name <이름>`으로 만들고, `Project.swift` 그래프 연결은 수작업으로 한다(의존성을 리뷰하려는 의도).

### 네트워크 계층

- 통신 공통 코드(`APIService`, 인터셉터, 토큰 갱신)는 CoreNetwork에 둔다. **CoreNetwork는 Data만 링크한다.**
- **Moya와 Alamofire는 CoreNetwork 밖에서 import하지 않는다.** Data는 CoreNetwork의 API만 쓴다. 라이브러리를 교체할 때 CoreNetwork만 바뀌게 하기 위해서다.
- API별 `TargetType`과 DTO는 Data의 `DataSource/Remote`에 `internal`로 두고, Repository의 `liveValue`에서 Entity로 변환한다.
- (미적용) 현재 Data가 `Moya`를 직접 의존하고 CoreNetwork는 어디에도 링크되지 않았다. Data의 의존성을 `Moya` → `CoreNetwork`로 바꾼다.

### 로직을 둘 위치

| 로직 | 위치 |
| --- | --- |
| 비즈니스 규칙, 여러 Repository 조합 | Domain의 UseCase `liveValue` |
| 저장 방식과 묶인 처리(조회, 변환, 캐시) | Data의 Repository `liveValue` |
| 화면 상태, 흐름, 화면 이동 | Reducer |
| 여러 Feature가 함께 쓰는 순수 계산 | Domain Entity의 extension 또는 순수 함수 |

### 에러 경계

에러는 계층을 넘을 때마다 받는 쪽의 언어로 바꾼다. 아래 계층의 에러 타입이 위로 그대로 올라가지 않게 한다.

| 계층 | 던지는 에러 | 책임 |
| --- | --- | --- |
| CoreNetwork | `APIError` (통신 사실만: 상태 코드, 디코딩, 세션 만료) | 사용자에게 보여 줄 문구를 갖지 않는다 |
| Data (Repository `liveValue`) | `APIError`와 SwiftData 에러를 **Domain 에러로 변환** | 변환하기 전에 원본을 로깅한다 |
| Domain | 공통 `DomainError`(`offline`, `unauthorized`, `notFound`, `invalid`, `unknown` 등) + 비즈니스 규칙 위반은 UseCase별 enum(예: `FocusSessionError.alreadyRunning`) | `Sendable, Equatable`로 만들어 `TestStore`에서 비교할 수 있게 한다 |
| UseCase | Domain 에러만 던진다 | 비즈니스 규칙 위반은 여기서 던진다 |
| Feature | Domain 에러 → 화면 상태(alert, 재시도, 빈 화면) | **사용자 문구는 여기서 만든다.** `CancellationError`는 무시한다 |

- 세션 만료는 호출 하나의 에러가 아니라 **앱 전역 이벤트**다. Feature는 `unauthorized`를 받아도 화면을 이동하지 않는다. CoreNetwork의 만료 알림을 Domain UseCase(예: `SessionEventUseCase`의 `AsyncStream`)로 노출하고, App의 `RootFeature`가 구독해서 로그인 흐름으로 보낸다.
- (미적용) Domain에 `DomainError`가 아직 없다.
- (미적용) CoreNetwork의 `APIError+UserMessage.swift`는 이 규칙을 어긴다. 사용자 문구는 Feature로 옮기고, `APIError`의 `LocalizedError` 채택도 다시 검토한다.

## 코드 규칙

- 경계는 `@DependencyClient` struct, 이름은 `XxxRepository` / `XxxUseCase`, 시그니처는 처음부터 `async throws`.
- DataSource는 구체 타입으로 두고 swift-dependencies로 주입하지 않는다.
- Entity는 `public struct` + `Sendable, Equatable, Identifiable` + 직접 쓴 `public init`. 저장 방식 타입(SwiftData `@Model`, DTO)은 Data의 DataSource에 `internal`로 둔다.
- (미적용) Swift 6 언어 모드와 strict concurrency를 `Module.swift` 헬퍼에서 모든 타깃에 일괄 적용한다. 타깃별로 따로 설정하지 않는다.
- (미적용) 포맷은 Xcode에 포함된 `swift format`을 쓰고, 설정 파일은 저장소 루트의 `.swift-format` 하나로 둔다. CI에서 `swift format lint --strict`로 검사한다.

## 스택과 의존성

- 외부 의존성은 `Tuist/Package.swift`에서만 추가하고, `Tuist/Package.resolved`를 커밋한다.
- 새 외부 의존성은 PR 설명에 **추가 이유, 대안, 유지보수 상태**를 적는다. 표준 라이브러리나 기존 의존성으로 되면 추가하지 않는다.
- 버전 범위는 `from:`(다음 메이저 전까지)으로 둔다. 메이저 업그레이드는 별도 PR로 한다.
- Moya는 CoreNetwork 안에만 둔다(네트워크 계층 참고). async/await 지원은 CoreNetwork가 감싸서 제공한다.
- SwiftData 스키마는 **`VersionedSchema` + `SchemaMigrationPlan`으로만 변경한다.** `@Model`의 저장 속성을 바꾸는 PR에는 마이그레이션 단계와 그 테스트가 함께 있어야 한다. 저장소는 App Group 컨테이너에 있으므로 앱 확장도 같은 스키마를 본다.
- (미적용) Tuist 원격 캐시를 쓴다(`Tuist.swift`의 `fullHandle`). CI와 로컬이 같은 바이너리 캐시를 공유하게 한다.

## 테스트

- 유닛 테스트는 Swift Testing, UI 테스트는 XCTest.
- 계층별 최소 기준:

| 대상 | 필수 테스트 |
| --- | --- |
| UseCase | Repository mock을 주입해 비즈니스 규칙 검증 |
| Repository `liveValue` | DTO/`@Model` → Entity 변환, 에러 변환 |
| Reducer | `TestStore`로 액션·상태·delegate 흐름 검증 |
| CoreNetwork | stub provider로 요청·디코딩·토큰 갱신 검증 |
| UI 테스트 | 핵심 사용자 흐름만 (앱 실행, 타이머 시작·종료) |

- (미적용) Domain과 Data에는 아직 테스트 타깃이 없다. `Target.moduleTests`로 추가한다.
- (미적용) `bootstrap()` 누락을 잡는 테스트: App 테스트에서 `bootstrap()` 후 모든 Repository가 test/preview 값이 아닌 live 값으로 해석되는지 확인한다.

## 규칙을 CI로 강제하기

리뷰에 기대는 규칙은 CI 검사로 옮긴다. 검사가 생기면 이 표의 상태를 갱신한다.

| 규칙 | 검사 방법 | 상태 |
| --- | --- | --- |
| 선언하지 않은 import | `tuist inspect dependencies --only implicit` | 적용 |
| Feature는 Repository를 직접 쓰지 않음 | Feature 소스에서 `@Dependency(\.` + `Repository` grep | 미적용 |
| Feature·Domain에서 `SwiftData`·`Moya`·`Alamofire` import 금지 | 해당 디렉터리 grep | 미적용 |
| Moya·Alamofire는 CoreNetwork에서만 | `Modules/Core/CoreNetwork` 밖 grep | 미적용 |
| Feature·Domain에서 `import CoreNetwork` 금지 (`APIError` 노출 방지) | 해당 디렉터리 grep | 미적용 |
| bootstrap 등록 누락 | 위 테스트 | 미적용 |
| 포맷 | `swift format lint --strict` | 미적용 |

## 환경과 비밀값

- 환경별 값은 `App/Configs/{Debug,Release}.xcconfig` → 빌드 설정 → Info.plist 순서로 흘려보낸다. 코드에 환경별 값을 `#if DEBUG`로 하드코딩하지 않는다.
- 비밀값(API 키 등)은 커밋하지 않는다. (미적용) `App/Configs/Secrets.xcconfig`를 gitignore하고 각 xcconfig에서 `#include? "Secrets.xcconfig"`로 선택적으로 포함한다. CI는 GitHub Secrets로 이 파일을 만든다.
- 로그, 에러 메시지, 테스트 fixture에 실제 토큰이나 개인정보를 넣지 않는다.

## 빌드와 릴리스

- 배포용 아카이브는 `tuist generate --no-binary-cache`로 소스 기반 프로젝트를 생성한 뒤 만든다.
- 버전(`MARKETING_VERSION`)과 빌드 번호(`CURRENT_PROJECT_VERSION`)는 매니페스트나 xcconfig에서 관리한다. Xcode UI에서 바꾸지 않는다(생성물이라 사라진다).
- (미적용) CI에서 Release configuration 빌드도 검증한다.
- Tuist 버전을 바꾸면 `mise.toml`을, Xcode 버전을 바꾸면 워크플로의 `XCODE_VERSION`도 같이 바꾼다.

## 로깅

- `os.Logger`를 쓴다. subsystem은 번들 ID, category는 모듈 이름.
- 에러 원본은 정보가 사라지기 전, 즉 Data에서 Domain 타입으로 변환하는 지점에서 로깅한다.
- 사용자 데이터와 토큰은 `privacy: .private`(기본값)로 두고 `.public`을 붙이지 않는다.
- 크래시 리포팅 도구는 아직 정하지 않았다.

## 브랜치, PR, 커밋

- `main`에 직접 푸시하지 않는다. 브랜치 → PR → CI 통과 후 squash 머지.
- 커밋과 PR 제목: 접두어 `feat:` / `fix:` / `refactor:` / `test:` / `docs:` / `ci:` / `chore:` + 한국어 메시지.
- 아키텍처 규칙을 바꾸는 PR은 이 파일도 같이 수정한다.
