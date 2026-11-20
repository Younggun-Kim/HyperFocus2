# HyperFocus Refactoring

HyperFocus 앱을 [Tuist](https://tuist.dev) 기반 프로젝트로 다시 구성하는 리팩터링 저장소입니다.

> 🚧 3주차까지 마쳤고, 4주차(CI)를 앞두고 있습니다.
> - 1주차: 앱·유닛 테스트·UI 테스트 타깃과 Debug/Release 설정(앱 이름, App Group) 분리
> - 2주차: [아키텍처](#아키텍처) 확정, Feature 2개(FocusTimer, SessionHistory)와 Data·Core/Utils 모듈 분리, 암묵적 의존 검사 통과
> - 3주차: 바이너리 캐시와 선택적 테스트 측정([결과](#측정-결과)), [새 Feature를 만드는 scaffold 템플릿](#새-feature-추가하기) 추가
> - 4주차 전: 아키텍처를 [클린 아키텍처 + `DataModule.bootstrap()`](#아키텍처)으로 전환 (Domain 모듈 추가, Feature는 Data를 링크하지 않음)

## 목표

- `.xcodeproj`를 직접 관리하지 않고 Swift 매니페스트(`Project.swift`)로 프로젝트를 선언·생성한다.
- 기능 단위로 모듈을 나누고, 의존 방향이 한쪽으로만 흐르도록 설계한다.
- 바이너리 캐시와 선택적 테스트로 빌드·테스트 시간을 줄이고, 그 효과를 수치로 남긴다.
- CI에서 `generate → build/test`가 자동으로 통과하게 만든다.

진행 순서와 주차별 통과 기준은 [Tuist 로드맵](docs/tuist-roadmap.md)을 따릅니다.

## 요구 사항

| 도구 | 버전 | 비고 |
| --- | --- | --- |
| macOS | 26.6 | 개발에 사용한 버전. `tuist generate`는 Xcode가 필요해서 macOS에서만 동작 |
| Xcode | 27.2 | 개발에 사용한 버전. 팀원·CI와 같은 버전 사용 |
| [mise](https://mise.jdx.dev) | 최신 | Tuist 버전 관리 |
| Tuist | `4.216.2` | `mise.toml`에 고정 |
| iOS (최소 지원) | 18.0 | 최신 버전이 아닌 기기를 쓰는 사용자까지 지원하면서 SwiftData를 쓰기 위해 선택. `Project.swift`의 `deploymentTargets` |

## 시작하기

```bash
# 1. 저장소 받기
git clone <저장소 URL>
cd HyperFocus_Refactoring

# 2. mise.toml에 고정된 Tuist 설치
mise install
tuist version   # 4.216.2가 나오면 정상

# 3. 외부 의존성 가져오기 (Tuist/Package.swift: swift-dependencies, TCA)
tuist install

# 4. Xcode 프로젝트 생성 후 열기
tuist generate
```

> `tuist version`이 다른 버전을 출력하면 셸에 mise가 활성화되어 있는지 확인하세요. `mise.toml`은 버전을 정할 뿐이고, 실제로 그 버전이 실행되게 하는 건 셸 설정(`mise activate`)입니다. `which -a tuist`로 어떤 `tuist`가 먼저 잡히는지 볼 수 있습니다.

> 생성된 `.xcodeproj` / `.xcworkspace`는 커밋하지 않습니다. 직접 수정해도 다음 `tuist generate`에서 사라지니, 변경은 항상 매니페스트에서 합니다.

## 자주 쓰는 명령어

| 명령어 | 용도 |
| --- | --- |
| `tuist edit` | 매니페스트를 Xcode에서 열어 편집 (자동완성 지원) |
| `tuist generate` | 매니페스트로 Xcode 프로젝트 생성 (기본값: 외부 의존성은 캐시된 바이너리 사용) |
| `tuist install` | `Tuist/Package.swift`의 외부 의존성 설치 |
| `tuist graph` | 모듈 의존성 그래프 시각화 |
| `tuist inspect dependencies --only implicit` | 선언하지 않은 `import`(암묵적 의존) 검사 |
| `tuist cache` | 바이너리 캐시 데우기 |
| `xcodebuild build -workspace HyperFocus.xcworkspace -scheme HyperFocus ...` | 빌드. `tuist build`는 4.216.2에서 빌드 기록 조회 명령으로 바뀌어 빌드하지 않습니다 |
| `tuist test <스킴> --device "iPhone 17 Pro"` | 테스트. 기본으로 선택적 테스트가 켜져 있어 해시가 바뀐 테스트 타깃만 실행합니다 |
| `tuist run <Feature> --device "iPhone 17 Pro"` | Feature의 Example 앱 실행 (`<Feature>` 스킴의 Run 대상이 Example 앱) |
| `tuist scaffold Feature --name <이름>` | 새 Feature 모듈 파일 생성 |

> 배포용 아카이브는 `tuist generate --no-binary-cache`로 소스 기반 프로젝트를 생성한 뒤 만듭니다.

## 빌드 configuration

| configuration | 홈 화면 앱 이름 | App Group | 설정 파일 |
| --- | --- | --- | --- |
| Debug | HyperFocus개발 | `group.com.hyperfocus.timer.dev` | `App/Configs/Debug.xcconfig` |
| Release | HyperFocus | `group.com.hyperfocus.timer` | `App/Configs/Release.xcconfig` |

- xcconfig는 앱 타깃(`HyperFocus`)에만 연결되어 있습니다. 테스트 타깃에는 적용되지 않습니다.
- 값은 `xcconfig → 빌드 설정(APP_DISPLAY_NAME) → Info.plist(CFBundleDisplayName) → 앱` 순서로 흐릅니다.
- App Group도 같은 방식입니다: `xcconfig → 빌드 설정(APP_GROUP_ID) → entitlements(com.apple.security.application-groups) → 앱`. 각 빌드에는 자기 환경의 그룹 하나만 들어갑니다.
- Info.plist와 entitlements는 `Project.swift`의 `infoPlist`, `entitlements`로 `Derived/InfoPlists/`, `Derived/Entitlements/`에 생성됩니다. 생성물이니 직접 고치지 말고 매니페스트에서 수정합니다.
- xcconfig에 키를 추가할 때는 파일 끝에 줄바꿈이 있는지 확인하세요. 줄바꿈이 없으면 두 줄이 합쳐져서, 값이 에러 없이 빈 문자열이 됩니다.
- 실기기 빌드에는 Apple Developer 계정에 두 App Group이 등록돼 있어야 합니다.

## Tuist 버전 관리

```bash
mise latest tuist           # 설치할 수 있는 최신 버전 확인
mise use tuist@<버전>        # 버전 변경 (mise.toml 갱신) — 예: mise use tuist@4.216.2
mise uninstall tuist@<버전>  # 안 쓰는 버전 삭제
```

버전을 올릴 때는 `mise.toml` 변경을 커밋해서 팀원과 CI가 같은 버전을 쓰도록 합니다.

## 프로젝트 구조

```
.
├── Tuist.swift              # 프로젝트 루트 표시 및 생성 옵션
├── Tuist/
│   ├── Package.swift        # 외부 의존성 (SPM: swift-dependencies, TCA)
│   ├── ProjectDescriptionHelpers/
│   │   └── Module.swift     # Target.module(...), Target.feature(...) helper
│   └── Templates/
│       └── Feature/         # tuist scaffold Feature 템플릿 (매니페스트 + .stencil 4개)
├── Project.swift            # 모든 타깃 선언 (Mono-project: 앱·테스트·모듈)
├── App/                     # 실행 단위(앱 타깃)
│   ├── Sources/             # 앱 진입점, RootFeature(자식 Feature 조립)
│   ├── Resources/           # 에셋 카탈로그
│   ├── Tests/               # 유닛 테스트 (Swift Testing)
│   ├── UITests/             # UI 테스트 (XCTest, XCUIApplication)
│   └── Configs/
│       ├── Debug.xcconfig   # Debug 빌드 설정 (앱 타깃)
│       └── Release.xcconfig # Release 빌드 설정 (앱 타깃)
├── Modules/                 # 라이브러리 모듈 (모두 staticFramework)
│   ├── Core/
│   │   ├── Utils/Sources/   # 공용 유틸
│   │   └── Network/         # (예정) 통신 공통 코드
│   ├── Domain/Sources/      # 내부 모듈 의존 없음
│   │   ├── Entity/          # public: 모델 (struct)
│   │   ├── Repository/      # public: XxxRepository 포트 (선언 + testValue/previewValue)
│   │   └── UseCase/         # public: XxxUseCase (선언 + liveValue, 같은 파일)
│   ├── Data/Sources/        # App만 링크
│   │   ├── DataModule.swift # bootstrap(): 모든 Repository의 liveValue 등록
│   │   ├── Repository/      # XxxRepository+Live.swift (DependencyKey 채택)
│   │   └── DataSource/      # internal: Local(SwiftData, UserDefaults), Remote(API)
│   └── Features/            # 기능 모듈 (FocusTimer, SessionHistory)
│       └── FocusTimer/
│           ├── Sources/     # Reducer + View
│           ├── Example/     # 이 기능만 띄우는 개발용 앱 (mock 주입)
│           └── Tests/
├── docs/
│   ├── tuist-roadmap.md
│   ├── network-roadmap.md   # APIService 단계별 재구성
│   └── blog/                # 주차별 학습 정리
└── mise.toml                # Tuist 버전 고정
```

반복되는 타깃 정의는 `Tuist/ProjectDescriptionHelpers/Module.swift`로 추출했습니다. `Target.feature(name:dependencies:)` 호출 하나가 Feature 프레임워크, `<Feature>Example` 앱, `<Feature>Tests`를 함께 만듭니다.

## 새 Feature 추가하기

```bash
# 1. 파일 생성 (저장소 루트에서, --path 없이)
tuist scaffold Feature --name Settings
```

`Modules/Features/Settings/` 아래에 `SettingsFeature.swift`, `SettingsView.swift`(Sources), `SettingsExampleApp.swift`(Example), `SettingsFeatureTests.swift`(Tests)가 생깁니다.

```swift
// 2. Project.swift의 Features 구간에 그래프 연결 (의존성은 Feature마다 직접 정함)
    + Target.feature(
        name: "Settings",
        dependencies: [.target(name: "Domain")]
    )
```

```bash
# 3. 프로젝트 생성 후 테스트
tuist generate
tuist test Settings --device "iPhone 17 Pro"
```

- scaffold는 파일만 만듭니다. 그래프 연결은 의존성을 리뷰에서 확인하도록 일부러 수작업으로 남겼습니다.
- 앱 화면에 붙이려면 `HyperFocus` 타깃의 `dependencies`에도 추가하고, `RootFeature`에서 조립합니다.

## 아키텍처

클린 아키텍처(Domain / Data / Presentation)를 Tuist 모듈로 나누고, 화면 단위는 [TMA](https://docs.tuist.dev/en/guides/features/projects/tma-architecture) 방식의 Feature 모듈로 만듭니다. Domain이 Repository 포트를 선언하고 Data가 그 구현을 제공하는 의존성 역전(DIP) 구조입니다.

```
App ──→ Feature ──→ Domain ←── Data
 └───────────────────────────────┘   (App만 Data를 링크하고 DataModule.bootstrap() 호출)
```

| 모듈 | 의존하는 대상 |
| --- | --- |
| App | Features, Data, ComposableArchitecture |
| `<Feature>Example`, `<Feature>Tests` | `<Feature>`와 그 의존성 (Data는 넣지 않음) |
| `<Feature>` | Domain, Core/Utils, ComposableArchitecture |
| Domain | Dependencies (내부 모듈 의존 없음) |
| Data | Domain, Core/Network, Core/Utils, Dependencies |
| Core | 내부 모듈 의존 없음 |

### 왜 `bootstrap()`이 필요한가

swift-dependencies는 `liveValue`를 컴파일 타임에 호출하지 않고, 런타임에 "이 키가 `DependencyKey`를 채택했는가"를 조회해서 찾습니다. 정적 라이브러리에서 링커는 참조되는 심볼이 있는 오브젝트 파일만 바이너리에 넣는데, Feature는 Domain의 포트만 참조하므로 Data의 구현 파일을 참조하는 코드가 하나도 없습니다. 그러면 구현이 링크 단계에서 빠지고, 런타임에 live 구현이 없다는 오류가 납니다.

`DataModule.bootstrap()`은 각 Repository의 `liveValue`를 코드로 직접 참조해 링크를 보장하고, `prepareDependencies`로 한 번에 등록합니다. 앱 진입점(`HyperFocusApp.init`)에서 Store를 만들기 전에 호출합니다.

### 규칙

- **Feature는 UseCase만 사용합니다.** Repository를 직접 `@Dependency`로 쓰지 않습니다. Repository는 Domain이 Data에 요구하는 경계 포트이고, Presentation의 진입점은 UseCase로 통일합니다. 같은 Domain 모듈에 있어 그래프로는 막히지 않으므로 리뷰와 CI 검사로 지킵니다.
- **Feature끼리는 서로 의존하지 않습니다.** 화면 이동은 부모 Reducer가 자식의 위임(delegate) 액션을 받아서 처리합니다.
- **Domain은 내부 모듈에 의존하지 않습니다.** SwiftData `@Model`과 API DTO는 Data의 DataSource에 `internal`로 두고, Repository의 `liveValue`에서 Entity로 변환해 반환합니다. Feature나 Domain에 `import SwiftData`가 나타나면 경계가 새고 있다는 신호입니다.
- **Repository를 새로 만들면 `DataModule.bootstrap()`에 반드시 등록합니다.** 빠뜨려도 컴파일은 통과하고 런타임에서야 실패합니다.
- **UseCase의 선언과 `liveValue`는 같은 파일에 둡니다.** UseCase 구현은 Repository 포트만 쓰므로 Domain 안에서 끝나고, Feature가 선언을 참조할 때 구현도 함께 링크됩니다.
- **Example 앱과 테스트는 Data를 링크하지 않고 mock을 명시적으로 주입합니다**(`prepareDependencies`, `TestStore`의 `withDependencies`). Repository 포트에 mock을 넣으면 UseCase는 실제 로직대로 동작합니다.
- 암묵적 의존은 `tuist inspect dependencies --only implicit`으로 검사합니다.

### 로직을 둘 위치

| 로직 | 위치 |
| --- | --- |
| 비즈니스 규칙, 여러 Repository 조합 | Domain의 UseCase `liveValue` |
| 저장 방식과 묶인 처리(조회, 변환, 캐시) | Data의 Repository `liveValue` |
| 화면 상태, 흐름, 화면 이동 | Reducer |
| 여러 Feature가 함께 쓰는 순수 계산 | Domain Entity의 extension 또는 순수 함수 |

### 팀 규칙

1. 경계는 struct 기반 클라이언트(`@Sendable` 클로저의 묶음, `@DependencyClient`)로 만듭니다. 데이터 경계는 `XxxRepository`, 비즈니스 동작은 `XxxUseCase`로 이름 짓습니다.
2. DataSource는 구체 타입으로 두고 swift-dependencies로 주입하지 않습니다.
3. 경계의 함수 시그니처는 처음부터 `async throws`로 만듭니다.
4. Entity는 `public struct`이고 `Sendable`, `Equatable`, `Identifiable`을 명시하며 `public init`을 직접 작성합니다. 저장 방식(SwiftData, API)에 의존하는 타입은 넣지 않습니다.
5. 모든 Repository 앞에는 UseCase를 둡니다. 단순 위임이라도 만들며, Feature의 진입점을 UseCase로 통일하기 위해서입니다.

> 2주차에는 클린 아키텍처를 시도했다가 TMA + Data 단일 모듈로 바꿨습니다(순환 의존, 정적 링크에서 `liveValue`가 빠지는 문제, 단순 위임 UseCase). 이후 링크 문제의 원인을 확인하고 `bootstrap()`으로 해결할 수 있게 되어, Feature가 Data 구현을 모르는 클린 아키텍처로 다시 전환했습니다. 순환은 Domain이 내부 모듈에 의존하지 않는 규칙으로 막습니다.

## 진행 상황

- [x] mise로 Tuist 버전 고정
- [x] 단일 타겟 앱을 `tuist generate`로 빌드·실행
- [x] Debug/Release 설정을 xcconfig로 분리
- [x] App Group entitlements를 환경별로 분리
- [x] UI 테스트 타깃 추가
- [x] 모듈 분리 및 암묵적 의존 검사(`tuist inspect dependencies --only implicit`) 적용
- [x] 바이너리 캐시·선택적 테스트 적용 및 시간 측정
- [x] 새 Feature를 만드는 scaffold 템플릿
- [ ] CI 파이프라인 구성

### 측정 결과

MacBook Pro(M3 Pro, 18GB), Xcode 27.2, Tuist 4.216.2에서 항목마다 3회 잰 중앙값입니다. 방법과 한계는 [3주차 글](docs/blog/week3-measure.md)에 있습니다.

| 항목 | 적용 전 | 적용 후 |
| --- | --- | --- |
| 클린 빌드 | 55.4초 (캐시 없음) | 10.9초 (외부 의존성 바이너리 캐시, -80%) |
| 모듈 1개 변경 후 테스트 | 48.1초 (선택적 테스트 끔) | 45.0초 (켬, 측정 오차 범위 안) |

선택적 테스트의 효과가 작은 건 app-hosted 테스트인 `HyperFocusTests`가 모든 Feature에 의존해서 매번 다시 실행되기 때문으로 보입니다.

## 문서

- [Tuist 로드맵: 매니페스트부터 CI까지](docs/tuist-roadmap.md)
- [APIService 재구성 로드맵: 가장 단순한 request부터 토큰 갱신까지](docs/network-roadmap.md)
- [Tuist 1주차: 매니페스트로 iOS 프로젝트 만들기](docs/blog/week1-manifest.md)
- [Tuist 2주차: 모듈 설계부터 Feature 분리와 의존성 검증까지](docs/blog/week2-modularization.md)
- [Tuist 3주차: 바이너리 캐시와 선택적 테스트를 숫자로 확인하기, 그리고 scaffold](docs/blog/week3-measure.md)
