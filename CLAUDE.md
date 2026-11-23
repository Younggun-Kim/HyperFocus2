# CLAUDE.md

HyperFocus 앱을 Tuist 기반 모듈 구조로 다시 만드는 **학습용** 리팩터링 저장소다.
설치, 명령어 표, 구조, 아키텍처 설명은 [README.md](README.md)에 있고, 이 문서에는 작업할 때 지킬 규칙만 적는다.

## 작업 방식

- 목적은 동작하는 결과보다 **사용자가 직접 이해하고 작성하는 것**이다. 방향과 힌트를 먼저 주고, 코드는 사용자가 쓰고 나는 리뷰한다. 사용자가 막혔거나 "그냥 해줘"라고 할 때만 직접 구현한다.
- 진행 순서와 주차별 통과 기준은 [docs/tuist-roadmap.md](docs/tuist-roadmap.md), 네트워크 계층은 [docs/network-roadmap.md](docs/network-roadmap.md)를 따른다. 다음 단계로 넘어가기 전에 통과 기준을 확인한다.
- Tuist 동작을 설명할 때는 **`mise.toml`에 고정된 4.216.2 기준** 공식 문서로 확인한다. 기억에 의존하지 않는다(예: 4.216.2의 `tuist build`는 빌드하지 않고 빌드 기록을 조회한다).

## 명령어

```bash
tuist install                                   # 외부 의존성 (Tuist/Package.swift)
tuist generate --no-open                        # 프로젝트 생성
tuist inspect dependencies --only implicit      # 암묵적 의존 검사
tuist test <스킴> --device "iPhone 17 Pro"       # 테스트 (기본: 선택적 테스트)
tuist test --device "iPhone 17 Pro" --no-selective-testing   # CI와 같은 전체 테스트
```

변경을 마치면 CI(`.github/workflows/ci.yml`)와 같은 순서(install → generate → inspect → test)로 확인한다.

## 생성물은 고치지 않는다

- `*.xcodeproj`, `*.xcworkspace`, `Derived/`(Info.plist, entitlements), `graph.png`는 생성물이다. 변경은 항상 `Project.swift`, `Tuist/ProjectDescriptionHelpers/`, `App/Configs/*.xcconfig`에서 한다.
- xcconfig에 키를 추가하면 파일 끝 줄바꿈을 확인한다. 없으면 값이 에러 없이 빈 문자열이 된다.

## 모듈 규칙

의존 방향: `App → Feature → Domain ← Data`. App만 Data를 링크하고 `DataModule.bootstrap()`을 호출한다.

- Feature는 **UseCase만** `@Dependency`로 쓴다. Repository를 직접 쓰지 않는다.
- Feature끼리 의존하지 않는다. 화면 이동은 부모 Reducer가 delegate 액션으로 처리한다.
- Domain은 내부 모듈에 의존하지 않는다. Feature나 Domain에 `import SwiftData`가 보이면 경계가 샌 것이다.
- Repository를 추가하면 `DataModule.bootstrap()`에 **반드시 등록**한다. 빠뜨려도 컴파일은 통과하고 런타임에 실패한다.
- UseCase 선언과 `liveValue`는 같은 파일에 둔다. 모든 Repository 앞에는 UseCase를 둔다(단순 위임이어도).
- Example 앱과 테스트는 Data를 링크하지 않고 mock을 명시적으로 주입한다.
- 새 Feature는 `tuist scaffold Feature --name <이름>`으로 만들고, `Project.swift` 그래프 연결은 수작업으로 한다(의존성을 리뷰하려는 의도).

## 코드 규칙

- 경계는 `@DependencyClient` struct, 이름은 `XxxRepository` / `XxxUseCase`, 시그니처는 처음부터 `async throws`.
- Entity는 `public struct` + `Sendable, Equatable, Identifiable` + 직접 쓴 `public init`. 저장 방식 타입(SwiftData, DTO)은 Data의 DataSource에 `internal`로 둔다.
- 유닛 테스트는 Swift Testing, UI 테스트는 XCTest.

## 커밋

- 접두어 `feat:` / `fix:` / `refactor:` / `test:` / `docs:` / `ci:` / `chore:` + 한국어 메시지. 로드맵 단계가 있으면 `(4단계)`, `(4주차)`처럼 붙인다.
- Tuist 버전을 바꾸면 `mise.toml`을, Xcode 버전을 바꾸면 워크플로의 `XCODE_VERSION`도 같이 바꾼다.
