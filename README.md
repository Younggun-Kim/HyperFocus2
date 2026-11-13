# HyperFocus Refactoring

HyperFocus 앱을 [Tuist](https://tuist.dev) 기반 프로젝트로 다시 구성하는 리팩터링 저장소입니다.

> 🚧 초기 단계입니다. 지금은 개발 환경(Tuist 버전 고정)만 갖춰져 있고, 매니페스트와 소스 코드는 아직 없습니다.

## 목표

- `.xcodeproj`를 직접 관리하지 않고 Swift 매니페스트(`Project.swift`)로 프로젝트를 선언·생성한다.
- 기능 단위로 모듈을 나누고, 의존 방향이 한쪽으로만 흐르도록 설계한다.
- 바이너리 캐시와 선택적 테스트로 빌드·테스트 시간을 줄이고, 그 효과를 수치로 남긴다.
- CI에서 `generate → build/test`가 자동으로 통과하게 만든다.

진행 순서와 주차별 통과 기준은 [Tuist 로드맵](docs/tuist-roadmap.md)을 따릅니다.

## 요구 사항

| 도구 | 버전 | 비고 |
| --- | --- | --- |
| macOS | TODO | `tuist generate`는 Xcode가 필요해서 macOS에서만 동작 |
| Xcode | TODO | 팀원·CI와 같은 버전 사용 |
| [mise](https://mise.jdx.dev) | 최신 | Tuist 버전 관리 |
| Tuist | `4.212.0` | `mise.toml`에 고정 |

## 시작하기

```bash
# 1. 저장소 받기
git clone <저장소 URL>
cd HyperFocus_Refactoring

# 2. mise.toml에 고정된 Tuist 설치
mise install
tuist version   # 4.212.0이 나오면 정상

# 3. 외부 의존성 가져오기 (Tuist/Package.swift가 생긴 뒤부터)
tuist install

# 4. Xcode 프로젝트 생성 후 열기
tuist generate
```

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

## Tuist 버전 관리

```bash
mise latest tuist           # 설치할 수 있는 최신 버전 확인
mise use tuist@<버전>        # 버전 변경 (mise.toml 갱신) — 예: mise use tuist@4.216.2
mise uninstall tuist@<버전>  # 안 쓰는 버전 삭제
```

버전을 올릴 때는 `mise.toml` 변경을 커밋해서 팀원과 CI가 같은 버전을 쓰도록 합니다.

## 프로젝트 구조

TODO: 매니페스트를 만든 뒤 채웁니다. 예상 구조는 아래와 같습니다.

```
.
├── Tuist.swift              # 프로젝트 루트 표시 및 생성 옵션
├── Tuist/
│   ├── Package.swift        # 외부 의존성 (SPM)
│   └── ProjectDescriptionHelpers/
├── Projects/                # TODO: App / Feature / Core / Shared 모듈
├── docs/
│   └── tuist-roadmap.md
└── mise.toml                # Tuist 버전 고정
```

## 진행 상황

- [x] mise로 Tuist 버전 고정
- [ ] 단일 타겟 앱을 `tuist generate`로 빌드·실행
- [ ] 모듈 분리 및 `enforceExplicitDependencies` 적용
- [ ] 바이너리 캐시·선택적 테스트 적용 및 시간 측정
- [ ] CI 파이프라인 구성

## 문서

- [Tuist 로드맵: 매니페스트부터 CI까지](docs/tuist-roadmap.md)
