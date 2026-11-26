# CLAUDE.md

## 프로젝트 소개

HyperFocus는 집중 타이머 iOS 앱이다. 이 저장소는 앱을 Tuist 기반 프로젝트로 다시 구성하면서, 클린 아키텍처를 모듈로 나눈다.

**프로젝트 규칙의 기준 문서는 이 파일과 디렉터리별 `CLAUDE.md`다.** README와 내용이 다르면 이 파일들을 따른다. `docs/blog/`는 당시의 기록이라 현재 규칙의 근거로 쓰지 않는다.

### 기술 스택

| 영역 | 사용 | 비고 |
| --- | --- | --- |
| 플랫폼 | iOS 18.0 이상 | SwiftData를 쓰기 위한 최소 버전. `Module.deploymentTargets` |
| UI·상태 | SwiftUI, TCA (ComposableArchitecture) | 화면 단위는 TMA 방식 Feature 모듈 |
| 의존성 주입 | swift-dependencies (`@DependencyClient`) | 계층 경계를 struct 클라이언트로 만든다 |
| 네트워크 | Alamofire | CoreNetwork 안에서만 쓴다 |
| 로컬 저장 | SwiftData + App Group 컨테이너 | 아직 코드 없음 |
| 테스트 | Swift Testing(유닛), XCTest(UI) | |
| 프로젝트 | Tuist 4.216.2 (`mise.toml`), Xcode 27.2 | `.xcodeproj`는 생성물 |
| CI | GitHub Actions (`.github/workflows/ci.yml`) | install → generate → inspect → test. **현재 일시 중지**(워크플로 비활성화) |

라이브러리 버전은 `Tuist/Package.resolved`가 기준이다.

### 아키텍처

클린 아키텍처(Domain / Data / Presentation)를 Tuist 모듈로 나눈다. Domain이 Repository 포트를 선언하고 Data가 구현하는 의존성 역전 구조다.

```
App ──→ Feature ──→ Domain ←── Data ──→ CoreNetwork ──→ Alamofire
 │         ├──→ Util
 │         └──→ DesignSystem
 ├──→ Domain (RootFeature가 UseCase를 쓴다)
 └──→ Data   (App만 Data를 링크하고 DataModule.bootstrap() 호출)
```

| 모듈 | 역할 | 의존할 수 있는 대상 | 쓸 수 있는 곳 | 세부 규칙 |
| --- | --- | --- | --- | --- |
| App | 진입점, Feature 조립, 환경 설정 | Feature, Domain, Data, TCA | - | `App/CLAUDE.md` |
| Feature | 화면 단위 (Sources, Example, Tests) | Domain, Util, DesignSystem, TCA | App | `Modules/Features/CLAUDE.md` |
| Domain | Entity, Repository 포트, UseCase | swift-dependencies만 | Feature, Data, App | `Modules/Domain/CLAUDE.md` |
| Data | Repository 구현, DataSource | Domain, CoreNetwork, swift-dependencies | App | `Modules/Data/CLAUDE.md` |
| CoreNetwork | 통신 공통 코드 (`APIService`, `APIEndpoint`, 토큰 갱신) | Alamofire | Data | `Modules/Core/CoreNetwork/CLAUDE.md` |
| Util | 순수 유틸리티 | 없음 | 모든 모듈 | - |
| DesignSystem | 공통 UI 리소스와 컴포넌트 (`Resources/`의 에셋, `DesignSystemAsset` 접근자) | 없음 | Feature, App | - |

## 아키텍처 규칙

- Feature의 진입점은 UseCase다. 모든 Repository 앞에는 UseCase를 둔다(단순 위임이어도).
- 화면 이동은 부모 Reducer가 자식의 delegate 액션으로 처리한다.
- **Repository를 추가하면 `DataModule.bootstrap()`에 반드시 등록한다.** 빠뜨려도 컴파일은 통과하고 런타임에 실패한다.
- 에러는 계층을 넘을 때마다 받는 쪽의 언어로 바꾼다: `APIError`(CoreNetwork) → Domain 에러(Data에서 변환, 원본 로깅) → 화면 상태와 사용자 문구(Feature). 세션 만료는 앱 전역 이벤트로 App의 `RootFeature`가 처리한다.

| 로직 | 위치 |
| --- | --- |
| 비즈니스 규칙, 여러 Repository 조합 | Domain의 UseCase `liveValue` |
| 저장 방식과 묶인 처리(조회, 변환, 캐시) | Data의 Repository `liveValue` |
| 화면 상태, 흐름, 화면 이동 | Reducer |
| 여러 Feature가 함께 쓰는 순수 계산 | Domain Entity의 extension 또는 순수 함수 |

## Tuist와 의존성

- Tuist 동작은 **4.216.2 기준** 공식 문서로 확인한다(예: 4.216.2의 `tuist build`는 빌드하지 않고 빌드 기록을 조회한다).
- 프로젝트 변경은 `Project.swift`, `Tuist/ProjectDescriptionHelpers/`, `App/Configs/*.xcconfig`에서 한다.
- 타깃은 `Module.swift`의 헬퍼(`Target.module`, `Target.moduleTests`, `Target.feature`)로 만든다. 타깃 공통 설정은 헬퍼에서 일괄로 바꾼다.
- 외부 의존성은 `Tuist/Package.swift`에 추가하고 `Tuist/Package.resolved`를 커밋한다. 직접 import하는 패키지는 간접 의존이어도 명시적으로 선언한다.
- 버전 범위는 `from:`(다음 메이저 전까지). 메이저 업그레이드는 별도 PR로 한다.
- 새 외부 의존성은 PR 설명에 **추가 이유, 대안, 유지보수 상태**를 적는다.
- Tuist 버전을 바꾸면 `mise.toml`을, Xcode 버전을 바꾸면 워크플로의 `XCODE_VERSION`도 같이 바꾼다.

## 코드 작성

- 경계는 `@DependencyClient` struct, 이름은 `XxxRepository` / `XxxUseCase`, 시그니처는 처음부터 `async throws`.
- 환경별 값은 xcconfig → 빌드 설정 → Info.plist로 흘려보낸다(`App/CLAUDE.md`). API 주소는 `API_BASE_URL`.
- 로깅은 `os.Logger`. subsystem은 번들 ID, category는 모듈 이름. 사용자 데이터와 토큰은 `privacy: .private`(기본값).
- 유닛 테스트는 Swift Testing, UI 테스트는 XCTest. 계층별 필수 테스트는 디렉터리별 `CLAUDE.md`에 있다.
- 크래시 리포팅 도구는 아직 정하지 않았다.

## 검증과 릴리스

변경을 마치면 CI와 같은 순서로 확인한다. CI가 일시 중지된 동안에는 이 로컬 검증이 머지 전 유일한 검사다.

```bash
tuist install                                   # 외부 의존성 (Tuist/Package.swift)
tuist generate --no-open                        # 프로젝트 생성
tuist inspect dependencies --only implicit      # 암묵적 의존 검사
tuist test <스킴> --device "iPhone 17 Pro"       # 테스트 (기본: 선택적 테스트)
tuist test --device "iPhone 17 Pro" --no-selective-testing   # CI와 같은 전체 테스트
```

- 배포용 아카이브는 `tuist generate --no-binary-cache`로 소스 기반 프로젝트를 생성한 뒤 만든다.

## 브랜치, PR, 커밋

- 브랜치 → PR → 검증 통과 후 squash 머지. CI가 일시 중지된 동안에는 위 "검증과 릴리스"의 로컬 검증(전체 테스트 포함)을 통과시키고, PR 설명에 결과를 적는다.
- 커밋과 PR 제목: 접두어 `feat:` / `fix:` / `refactor:` / `test:` / `docs:` / `ci:` / `chore:` + 한국어 메시지.
- 아키텍처 규칙을 바꾸는 PR은 루트와 해당 디렉터리의 `CLAUDE.md`도 같이 수정한다.

## 하지 말 것

**프로젝트**
- 생성물(`*.xcodeproj`, `*.xcworkspace`, `Derived/`, `graph.png`)을 직접 고치지 않는다. 다음 `tuist generate`에서 사라진다.
- 버전, 빌드 번호, 빌드 설정을 Xcode UI에서 바꾸지 않는다. 같은 이유다.
- Tuist 동작을 기억으로 판단하지 않는다. 버전마다 명령의 의미가 다르다.
- `main`에 직접 푸시하지 않는다.

**아키텍처**
- Feature에서 Repository를 `@Dependency`로 직접 쓰지 않는다. 같은 Domain 모듈이라 그래프로는 막히지 않는다.
- Feature끼리 의존하지 않는다.
- Data를 App 밖(Feature, Example 앱, 테스트 포함)에서 링크하지 않는다. Example과 테스트는 mock을 주입한다.
- Feature·Domain에서 `SwiftData`, `Alamofire`, `CoreNetwork`를 import하지 않는다. Alamofire는 CoreNetwork 밖에서 쓰지 않는다.
- 아래 계층의 에러 타입(`APIError`, SwiftData 에러)을 위로 그대로 올리지 않는다. 사용자 문구를 Feature 밖에서 만들지 않는다.

**코드와 데이터**
- 환경별 값을 `#if DEBUG`로 하드코딩하지 않는다.
- 비밀값(API 키 등)을 커밋하지 않는다. 로그, 에러 메시지, 테스트 fixture에 실제 토큰이나 개인정보를 넣지 않는다. 로그에 `.public`을 붙이지 않는다.
- SwiftData `@Model`의 저장 속성을 마이그레이션(`VersionedSchema` + `SchemaMigrationPlan`)과 그 테스트 없이 바꾸지 않는다.
- 표준 라이브러리나 기존 의존성으로 되는 일에 새 외부 의존성을 추가하지 않는다.

## 아직 적용하지 않은 결정

결정은 했지만 코드·설정에 반영하지 않은 항목이다. 새 코드는 이 결정대로 작성한다. **요청 범위 밖의 항목은 제안만 하고 직접 바꾸지 않는다.** 적용하면 이 목록에서 지우고 해당 섹션으로 옮긴다.

**코드·설정**
- CI를 다시 켠다. 실행 시간 때문에 일시 중지했다(GitHub에서 워크플로 비활성화). 다시 켤 때는 draft PR #1(`ci/xcode-27-runner`, `xcode-27` 러너와 `iPhone 18 Pro`)을 최신 main에 맞춰 함께 적용한다. `macos-26` 러너에는 Xcode 27.2가 없어 그대로 켜면 실패한다.
- CoreNetwork의 `APIError+UserMessage.swift`에 있는 사용자 문구를 Feature로 옮기고, `APIError`의 `LocalizedError` 채택을 다시 검토한다.
- Swift 6 언어 모드와 strict concurrency를 `Module.swift` 헬퍼에서 모든 타깃에 일괄 적용한다.
- 포맷은 Xcode에 포함된 `swift format`, 설정은 저장소 루트의 `.swift-format` 하나로 둔다.
- `App/Configs/Secrets.xcconfig`를 gitignore하고 각 xcconfig에서 `#include? "Secrets.xcconfig"`로 포함한다. CI는 GitHub Secrets로 이 파일을 만든다.
- Tuist 원격 캐시(`Tuist.swift`의 `fullHandle`)로 CI와 로컬이 같은 바이너리 캐시를 공유한다.

**CI로 강제하기** (리뷰에 기대는 규칙을 검사로 옮긴다)

| 규칙 | 검사 방법 | 상태 |
| --- | --- | --- |
| 선언하지 않은 import | `tuist inspect dependencies --only implicit` | 적용 |
| Feature는 Repository를 직접 쓰지 않음 | Feature 소스에서 `@Dependency(\.` + `Repository` grep | 미적용 |
| Feature·Domain에서 `SwiftData`·`Alamofire`·`CoreNetwork` import 금지 | 해당 디렉터리 grep | 미적용 |
| Alamofire는 CoreNetwork에서만 | `Modules/Core/CoreNetwork` 밖 grep | 미적용 |
| bootstrap 등록 누락 | App 테스트에서 `bootstrap()` 후 모든 Repository가 live 값인지 확인 | 미적용 |
| 포맷 | `swift format lint --strict` | 미적용 |
| Release configuration 빌드 | CI 단계 추가 | 미적용 |
