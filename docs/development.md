# 개발 가이드

로컬 환경 설정, 자주 쓰는 명령어, 빌드 설정, 프로젝트 구조를 정리한 기여자용 문서입니다. 프로젝트 소개는 [README](../README.md), 아키텍처 규칙은 [CLAUDE.md](../CLAUDE.md)를 봅니다.

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

# 3. 외부 의존성 가져오기 (Tuist/Package.swift: swift-dependencies, TCA, Moya)
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
| `tuist test <스킴> --device "iPhone 18 Pro"` | 테스트. 기본으로 선택적 테스트가 켜져 있어 해시가 바뀐 테스트 타깃만 실행합니다 |
| `tuist run <Feature> --device "iPhone 18 Pro"` | Feature의 Example 앱 실행 (`<Feature>` 스킴의 Run 대상이 Example 앱) |
| `tuist scaffold Feature --name <이름>` | 새 Feature 모듈 파일 생성 |

> 배포용 아카이브는 `tuist generate --no-binary-cache`로 소스 기반 프로젝트를 생성한 뒤 만듭니다.

## CI

`main` 푸시와 PR마다 GitHub Actions(`.github/workflows/ci.yml`)가 아래 순서로 실행합니다. 로컬에서도 같은 명령으로 재현할 수 있습니다.

```bash
tuist install
tuist generate --no-open
tuist inspect dependencies --only implicit
tuist test --device "iPhone 18 Pro" --no-selective-testing
```

- Tuist 버전은 `mise.toml`, Xcode 버전은 워크플로의 `XCODE_VERSION`으로 로컬과 맞춥니다. Xcode를 올릴 때는 둘 다 바꿉니다.
- CI에는 이전 실행 기록이 없어 선택적 테스트가 이득이 없으므로 끄고 전부 실행합니다.
- `Tuist/.build`(SPM 체크아웃)는 `Package.resolved` 해시로 캐시합니다.

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
│   ├── Package.swift        # 외부 의존성 (SPM: swift-dependencies, TCA, Moya)
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
│   │   ├── Util/Sources/    # 공용 유틸
│   │   └── CoreNetwork/     # 통신 공통 코드 (APIService, 인터셉터) + Tests
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
tuist test Settings --device "iPhone 18 Pro"
```

- scaffold는 파일만 만듭니다. 그래프 연결은 의존성을 리뷰에서 확인하도록 일부러 수작업으로 남겼습니다.
- 앱 화면에 붙이려면 `HyperFocus` 타깃의 `dependencies`에도 추가하고, `RootFeature`에서 조립합니다.

