# HyperFocus Refactoring

HyperFocus 앱을 [Tuist](https://tuist.dev) 기반 프로젝트로 다시 구성하는 리팩터링 저장소입니다.

> 🚧 1주차 진행 중입니다. 단일 타깃 앱을 `tuist generate`로 생성·빌드·테스트할 수 있고, Debug/Release 설정을 xcconfig로 분리했습니다. 모듈 분리는 2주차에 진행합니다.

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

# 3. 외부 의존성 가져오기 (지금은 선언된 외부 의존성이 없음)
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

| configuration | 홈 화면 앱 이름 | 설정 파일 |
| --- | --- | --- |
| Debug | HyperFocus개발 | `Configs/Debug.xcconfig` |
| Release | HyperFocus | `Configs/Release.xcconfig` |

- xcconfig는 앱 타깃(`HyperFocus`)에만 연결되어 있습니다. 테스트 타깃에는 적용되지 않습니다.
- 값은 `xcconfig → 빌드 설정(APP_DISPLAY_NAME) → Info.plist(CFBundleDisplayName) → 앱` 순서로 흐릅니다.
- Info.plist는 `Project.swift`의 `infoPlist`로 `Derived/InfoPlists/`에 생성됩니다. 생성물이니 직접 고치지 말고 매니페스트에서 수정합니다.

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
│   └── Package.swift        # 외부 의존성 (SPM)
├── Project.swift            # 앱(HyperFocus)·테스트(HyperFocusTests) 타깃 선언
├── Configs/
│   ├── Debug.xcconfig       # Debug 빌드 설정 (앱 타깃)
│   └── Release.xcconfig     # Release 빌드 설정 (앱 타깃)
├── Sources/                 # 앱 코드
├── Resources/               # 에셋 카탈로그
├── Tests/                   # 유닛 테스트 (Swift Testing)
├── docs/
│   ├── tuist-roadmap.md
│   └── blog/                # 주차별 학습 정리
└── mise.toml                # Tuist 버전 고정
```

2주차 모듈 분리 후에는 `Projects/`(App / Feature / Core / Shared)와 `Tuist/ProjectDescriptionHelpers/`가 추가될 예정입니다.

## 진행 상황

- [x] mise로 Tuist 버전 고정
- [x] 단일 타겟 앱을 `tuist generate`로 빌드·실행
- [x] Debug/Release 설정을 xcconfig로 분리
- [ ] 모듈 분리 및 `enforceExplicitDependencies` 적용
- [ ] 바이너리 캐시·선택적 테스트 적용 및 시간 측정
- [ ] CI 파이프라인 구성

## 문서

- [Tuist 로드맵: 매니페스트부터 CI까지](docs/tuist-roadmap.md)
- [Tuist 1주차: 매니페스트로 iOS 프로젝트 만들기](docs/blog/week1-manifest.md)
