# HyperFocus Refactoring

HyperFocus 앱을 [Tuist](https://tuist.dev) 기반 프로젝트로 다시 구성하는 리팩터링 저장소입니다.

> 🚧 2주차 진행 중입니다. 1주차에 앱·유닛 테스트·UI 테스트 타깃과 Debug/Release 설정(앱 이름, App Group) 분리를 마쳤고, 2주차에는 [아키텍처](#아키텍처)를 확정하고 Feature 2개(FocusTimer, SessionHistory)와 Data·Core/Utils 모듈로 나눈 뒤 암묵적 의존 검사를 통과했습니다.

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

# 3. 외부 의존성 가져오기 (Tuist/Package.swift: swift-dependencies)
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
| `tuist generate` | 매니페스트로 Xcode 프로젝트 생성 |
| `tuist install` | `Tuist/Package.swift`의 외부 의존성 설치 |
| `tuist graph` | 모듈 의존성 그래프 시각화 |
| `tuist build` / `tuist test` | 빌드 / 테스트 (테스트는 변경된 타겟만 실행) |
| `tuist cache` | 바이너리 캐시 데우기 |

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
│   └── ProjectDescriptionHelpers/
│       └── Module.swift     # Target.module(...), Target.feature(...) helper
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
│   ├── Data/Sources/
│   │   ├── Client/          # public: XxxClient (선언 + liveValue, 같은 파일)
│   │   ├── Model/           # public: 모델
│   │   └── DataSource/      # internal: Local(SwiftData, UserDefaults), Remote(API)
│   └── Features/            # 기능 모듈 (FocusTimer, SessionHistory)
│       └── FocusTimer/
│           ├── Sources/     # Reducer + View
│           ├── Example/     # 이 기능만 띄우는 개발용 앱 (mock 주입)
│           └── Tests/
├── docs/
│   ├── tuist-roadmap.md
│   └── blog/                # 주차별 학습 정리
└── mise.toml                # Tuist 버전 고정
```

반복되는 타깃 정의는 `Tuist/ProjectDescriptionHelpers/Module.swift`로 추출했습니다. `Target.feature(name:dependencies:)` 한 줄이 Feature 프레임워크, `<Feature>Example` 앱, `<Feature>Tests`를 함께 만듭니다.

## 아키텍처

[TMA(The Modular Architecture)](https://docs.tuist.dev/en/guides/features/projects/tma-architecture) 방식으로 기능(Feature)을 나누고, 데이터 접근은 Data 모듈 하나가 맡습니다. 처음에는 클린 아키텍처(Domain / Data / Presentation)로 설계했지만, 계층 사이의 순환 의존과 정적 링크 문제, 단순 위임만 하는 UseCase가 반복돼서 더 단순한 구조로 바꿨습니다.

| 모듈 | 의존하는 대상 |
| --- | --- |
| App | Features, ComposableArchitecture |
| `<Feature>Example`, `<Feature>Tests` | `<Feature>`와 그 의존성 (mock 주입 시 Data를 직접 import) |
| `<Feature>` | Data, Core/Utils, ComposableArchitecture |
| Data | Core/Network, Core/Utils, Dependencies |
| Core | 내부 모듈 의존 없음 |

### 규칙

- **Feature끼리는 서로 의존하지 않습니다.** 화면 이동은 부모 Reducer가 자식의 위임(delegate) 액션을 받아서 처리합니다.
- **Data의 공개 범위는 `Client`와 `Model`뿐입니다.** DataSource는 `internal`로 숨깁니다.
- **별도의 Entity 계층은 두지 않습니다. Data의 `Model`이 그 역할을 합니다.** SwiftData `@Model`과 API DTO는 DataSource에 `internal`로 두고, 클라이언트의 `liveValue`에서 `Model`로 변환해 반환합니다. Feature 코드에 `import SwiftData`가 나타나면 경계가 새고 있다는 신호입니다.
- **클라이언트의 선언과 `liveValue`는 같은 파일에 둡니다.** Feature가 선언을 참조하면 실제 구현도 함께 링크되게 하기 위해서입니다.
- **Example 앱은 mock을 명시적으로 주입합니다**(`prepareDependencies`). 주입하지 않으면 실제 SwiftData에 접근합니다.
- 암묵적 의존은 `tuist inspect dependencies --only implicit`으로 검사합니다.

### 로직을 둘 위치

| 로직 | 위치 |
| --- | --- |
| 데이터와 묶인 규칙 | Data 클라이언트의 `liveValue` |
| 화면 상태, 흐름, 화면 이동 | Reducer |
| 여러 Feature가 함께 쓰는 순수 계산 | Data 모델의 extension 또는 순수 함수 |

### 팀 규칙

1. 경계는 struct 기반 클라이언트(`@Sendable` 클로저의 묶음)로 만들고, 이름은 `XxxClient`로 합니다.
2. DataSource는 구체 타입으로 두고 swift-dependencies로 주입하지 않습니다.
3. 경계의 함수 시그니처는 처음부터 `async throws`로 만듭니다.
4. 모델은 `public struct`이고 `Sendable`, `Equatable`, `Identifiable`을 명시하며 `public init`을 직접 작성합니다. 저장 방식(SwiftData, API)에 의존하는 타입은 모델에 넣지 않습니다.

> Data를 `DataInterface`와 구현으로 나누는 건 Example 앱 빌드가 무거워지거나, Data를 고칠 때마다 Feature가 다시 빌드되는 게 느려질 때 다시 검토합니다. 나눌 때는 `Model`과 클라이언트 선언을 `DataInterface`로 옮기고, 정적 링크에서 `liveValue`가 빠지지 않도록 앱 진입점에서 Data의 등록 함수(`DataModule.bootstrap()`)를 호출합니다.

## 진행 상황

- [x] mise로 Tuist 버전 고정
- [x] 단일 타겟 앱을 `tuist generate`로 빌드·실행
- [x] Debug/Release 설정을 xcconfig로 분리
- [x] App Group entitlements를 환경별로 분리
- [x] UI 테스트 타깃 추가
- [x] 모듈 분리 및 암묵적 의존 검사(`tuist inspect dependencies --only implicit`) 적용
- [ ] 바이너리 캐시·선택적 테스트 적용 및 시간 측정
- [ ] CI 파이프라인 구성

## 문서

- [Tuist 로드맵: 매니페스트부터 CI까지](docs/tuist-roadmap.md)
- [Tuist 1주차: 매니페스트로 iOS 프로젝트 만들기](docs/blog/week1-manifest.md)
- [Tuist 2주차: 모듈 설계와 첫 번째 모듈 분리](docs/blog/week2-modularization.md)
