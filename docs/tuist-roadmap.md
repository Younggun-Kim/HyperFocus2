# Tuist Roadmap: 매니페스트부터 CI까지

## TL;DR

- Tuist는 `.xcodeproj`를 직접 관리하지 않고 Swift 매니페스트로 프로젝트를 선언해서 생성하는 도구입니다.
- 4주 동안 환경 통일 → 매니페스트 → 모듈화 → 캐시·테스트 → CI·마이그레이션 순서로 익힙니다.
- 주차마다 통과 기준이 있어서 체크리스트처럼 따라갈 수 있습니다.

> ⚠️ Tuist는 버전이 빠르게 올라가는 도구입니다. 이 글은 2026년 10월 기준 공식 문서를 확인하며 작성했고, 코드 예시는 사용 중인 버전의 문서와 꼭 대조해 보세요.

## 들어가며

iOS 프로젝트를 여러 명이 함께 개발하다 보면 `.xcodeproj` 때문에 고생하는 순간이 반드시 옵니다.

- PR마다 충돌이 나는데 diff는 읽을 수 없다.
- 모듈을 하나 추가할 때마다 비슷한 설정을 복사해서 붙여넣는다.

Tuist는 프로젝트 구조를 Swift 코드로 선언하고, 그 코드로 Xcode 프로젝트를 생성해서 이 문제를 풉니다. 코드라서 리뷰가 가능하고, 반복되는 설정은 함수로 추출할 수 있습니다.

이 글은 Tuist를 처음 배우는 사람(신입 팀원을 가르친다는 생각으로 썼습니다)을 위한 로드맵입니다.

## 4주 한눈에 보기

| 주차 | 한 줄 목표 | 핵심 키워드 | 통과 기준 |
| --- | --- | --- | --- |
| 0주차 | 환경 통일 | mise, 버전 고정 | 팀 전원이 같은 Tuist 버전 사용 |
| 1주차 | 매니페스트 읽고 쓰기 | `Project.swift`, `Tuist.swift` | `tuist generate`만으로 빌드·실행 |
| 2주차 | 모듈화 | 의존성 그래프, `Tuist/Package.swift` | 의존 방향이 의도대로, 순환 없음 |
| 3주차 | 빠르게 만들기 | 바이너리 캐시, 선택적 테스트 | 시간 단축을 수치로 설명 |
| 4주차 | 팀에 적용 | CI, 점진적 마이그레이션 | CI에서 자동 빌드·테스트 통과 |

---

## 0주차: 사전 지식 (1~2일)

### 먼저 복습할 것

Tuist는 결국 Xcode 프로젝트를 만들어주는 도구라서, 아래 개념이 헷갈리면 매니페스트가 읽히지 않습니다.

- target, scheme, build settings
- xcconfig
- 정적/동적 링크, framework

### 환경 통일: mise로 버전 고정

공식 문서는 팀이나 조직처럼 환경마다 같은 버전을 보장해야 할 때 Homebrew보다 mise를 권장합니다. mise는 버전을 프로젝트 단위로 고정할 수 있기 때문입니다.

```bash
mise use tuist@x.y.z      # 현재 프로젝트에 버전을 고정 (mise.toml에 기록)
mise install              # mise.toml에 고정된 버전을 설치 (팀원이 clone한 뒤 실행)
tuist version
```

> 💡 `mise install tuist`만으로는 버전이 고정되지 않습니다. 고정은 `mise use`가 담당하고, `mise install`은 이미 고정된 버전을 설치할 때 씁니다.

> 📝 Linux에서는 mise로만 설치할 수 있고, `tuist generate`처럼 Xcode에 의존하는 명령은 쓸 수 없습니다. CI는 macOS 러너를 기준으로 생각하세요.

✅ **통과 기준:** `tuist version`이 정상 동작하고 팀과 같은 버전이 `mise.toml`에 고정되어 있다.

---

## 1주차: 매니페스트는 코드다

### 배울 것

- 기본 명령어: `tuist init`, `tuist generate`, `tuist edit`
- 매니페스트 3종

| 파일 | 역할 |
| --- | --- |
| `Project.swift` | Xcode 프로젝트 하나를 선언 |
| `Workspace.swift` | 여러 프로젝트를 묶는 워크스페이스 정의 (생략하면 Tuist가 프로젝트와 그 의존 프로젝트를 담은 워크스페이스를 자동 생성) |
| `Tuist.swift` | 프로젝트 루트 판단 기준이자 생성 옵션 설정 |

- 기본 디렉터리 구조: 루트에 `Tuist.swift`, `Tuist/` 디렉터리(그 안에 `Package.swift`), 그리고 `Project.swift`
- Target 구성: 앱, 프레임워크, 유닛/UI 테스트, 리소스, Info.plist, entitlements
- Settings와 xcconfig로 Debug/Release 등 configuration 분리

### 실습

`tuist init`으로 시작할 때는 대화형 프롬프트에서 "generated project" 옵션을 고릅니다. 그다음 단일 타겟 앱을 만들고, 생성된 `.xcodeproj`는 `.gitignore`에 추가합니다.

```swift
// Project.swift (형태를 보여주는 예시)
import ProjectDescription

let project = Project(
    name: "MyApp",
    targets: [
        .target(
            name: "MyApp",
            destinations: .iOS,
            product: .app,
            bundleId: "dev.example.myapp",
            sources: ["Sources/**"],
            resources: ["Resources/**"]
        )
    ]
)
```

### 흔한 실수와 팁

- 매니페스트 최상단에는 `let project = Project(...)` 하나만 둡니다. 재사용할 코드는 Swift 함수로 뺍니다.
- 처음에는 `tuist edit`으로 매니페스트를 Xcode에서 열어 편집하면 자동완성이 되어 편합니다.
- 첫 실행이 느린 건 정상입니다. 매니페스트가 Swift라서 컴파일이 필요하고, 그 결과는 캐시됩니다.
- 생성된 `.xcodeproj`를 직접 수정하면 다음 `generate`에서 모두 사라집니다.

✅ **통과 기준:** `tuist generate`만으로 앱이 빌드되고 실행된다.

---

## 2주차: 의존성은 설계다

### 배울 것

- 의존성 그래프와 `tuist graph` 시각화
- 외부 라이브러리는 `Tuist/Package.swift`에 선언하고 `tuist install`로 가져오기
  - Tuist는 SPM을 의존성 해석에만 쓰고, 결과를 Xcode 프로젝트와 타겟으로 변환해서 설정 자유도를 높입니다.
  - 외부 패키지의 기본 프로덕트 타입은 정적 프레임워크이고, 필요하면 `PackageSettings`의 `productTypes`로 바꿉니다.
- `enforceExplicitDependencies`: 선언하지 않은 암묵적 의존성을 잡아내는 옵션 (`Tuist.swift`의 generation options)
- `ProjectDescriptionHelpers`로 반복되는 target 정의 추출
- 계층 설계: Feature / Core / Shared, Interface / Implementation 분리

```swift
// Tuist.swift
import ProjectDescription

let tuist = Tuist(
    project: .tuist(
        generationOptions: .options(enforceExplicitDependencies: true)
    )
)
```

### 실습

앱을 Feature 모듈 2~3개와 Core 모듈로 쪼개고, 반복되는 target 정의를 helper로 통일합니다. 외부 라이브러리 하나를 `Tuist/Package.swift`로 추가해 보세요.

### 흔한 실수와 팁

- 모듈을 왜 그렇게 잘랐는지 설명할 수 있어야 합니다. 설명이 안 된다면 경계가 잘못 그어졌을 가능성이 큽니다.
- Core에 모든 걸 몰아넣거나 Feature끼리 직접 의존하는 구조를 조심하세요.
- helper는 처음부터 완벽할 필요 없습니다. 같은 코드가 세 번 나오면 그때 추출하세요.
- 프로젝트를 하나로 크게 두는 방식(mono-project)과 여러 개로 나누는 방식 중에서는, Tuist 팀은 콜드 생성이 더 빠르다는 이유로 mono-project 쪽을 택하고 helper를 캡슐화 단위로 씁니다. 팀 상황에 맞게 고르세요.

✅ **통과 기준:** `tuist graph`에서 의존 방향이 한쪽으로만 흐르고, 순환 의존과 암묵적 의존이 없다.

---

## 3주차: 측정하지 않으면 개선이 아니다

### 배울 것

- `tuist build`, `tuist test`, `tuist run`
- 템플릿(Scaffold): `tuist edit` 후 `Tuist/Templates/<템플릿명>/` 아래에 매니페스트를 만들고 `tuist scaffold <템플릿명> --name Foo`로 실행합니다. 새 모듈을 만들 때 쓰는 팀 규칙을 코드로 남기는 작업입니다.

#### 바이너리 캐시

- Tuist는 의존성 그래프의 각 타겟을 해시로 비교하고, 프로젝트를 생성할 때 원본 타겟을 캐시된 바이너리로 바꿔줍니다.
- `tuist cache`로 캐시를 데웁니다.
- 효과는 그래프 구조에 크게 좌우됩니다. 잘게 나뉘고 변경이 적은 모듈이 많을수록 유리합니다.
- 시뮬레이터/기기 실행이나 테스트 같은 개발 워크플로용입니다. 앱을 아카이브할 때는 `--no-binary-cache`로 소스 기반 프로젝트를 생성하세요.
- CI에서 main 브랜치 커밋마다 캐시를 데우는 잡을 두는 것이 권장됩니다.

#### 선택적 테스트

- `tuist test`가 변경된 타겟의 테스트만 실행합니다. 마지막 성공 실행 이후 해시가 바뀐 타겟이 대상입니다.
- 코드 수준 의존을 알 수 없어서 최대 단위는 타겟입니다. 그래서 타겟을 작고 집중적으로 유지하라고 권장합니다.
- 선택적 실행에서는 코드 커버리지 도구가 전체 테스트를 가정하기 때문에, 커버리지 수치가 실제와 다를 수 있습니다.

#### 원격 캐시 공유와 서버 기능

환경 간에 바이너리를 공유하려면 Tuist 서버(과거 Tuist Cloud) 연동이 필요합니다. 제공 범위와 요금은 바뀔 수 있으니 공식 문서에서 현재 상태를 확인하세요.

#### (선택) 플러그인

helper와 템플릿을 여러 프로젝트에서 공유하는 용도입니다. 플러그인끼리 의존할 수 없고 버전 해석을 제공하지 않으며, task 플러그인은 deprecated입니다.

### 실습

캐시를 켜기 전에 클린 빌드 시간을 먼저 기록하고, 적용한 뒤 다시 측정해서 비교합니다.

| 항목 | 적용 전 | 적용 후 |
| --- | --- | --- |
| 클린 빌드 시간 | (측정) | (측정) |
| 변경 1개 모듈 후 테스트 시간 | (측정) | (측정) |

도입 전 숫자가 없으면 "빨라진 것 같다"는 느낌만 남습니다. 이 숫자가 팀을 설득합니다.

✅ **통과 기준:** 캐시와 선택적 테스트를 적용하고, 개선 효과를 수치로 설명할 수 있다.

---

## 4주차: 혼자 되는 것과 팀이 쓰는 것은 다르다

### CI 파이프라인의 기본 흐름

1. `mise install` (고정된 Tuist 버전 설치)
2. `tuist install` (외부 의존성 가져오기)
3. `tuist generate` (프로젝트 생성)
4. `tuist build` / `tuist test`
5. 릴리스 빌드는 `--no-binary-cache`로 생성한 소스 기반 프로젝트로 아카이브 → Fastlane 등으로 TestFlight 업로드

CI에서 Tuist 버전이 로컬과 같은지부터 확인하세요. 어긋나면 "내 PC에서는 되는데" 문제가 생깁니다.

### 기존 앱 마이그레이션: 공식 가이드의 순서

한 번에 갈아엎지 않고, 아래 순서로 빌드가 깨지지 않는지 확인하면서 조금씩 옮깁니다.

1. 현재 프로젝트가 빌드·실행되는지 먼저 기준선을 확인한다. (배포 타깃과 번들 ID는 원본과 동일하게 유지)
2. 기존 프로젝트와 충돌하지 않게 프로젝트 이름에 `-Tuist` 접미사를 붙여 `Project.swift`를 만든다. (완전히 옮긴 뒤 접미사 제거)
3. CI에서 Tuist 프로젝트가 빌드·테스트되는지 확인한다.
4. `tuist migration settings-to-xcconfig`로 빌드 설정을 `.xcconfig`로 추출하고, `tuist migration check-empty-settings`로 남은 설정이 없는지 확인한다.
5. 외부 의존성을 `Tuist/Package.swift`로 옮긴다.
6. `tuist migration list-targets`로 타겟 목록을 보고, 타겟을 하나씩 옮긴다.
7. 생성된 프로젝트의 파일 목록이 원본과 일치하는지 확인한다.

### 트러블슈팅 체크

- **매니페스트 컴파일이 느리다** → 첫 실행 이후에는 캐시된다. 그래도 느리면 매니페스트 수를 줄이는 방향을 검토
- **캐시가 안 맞는다** → 그래프 구조와 타겟 입력(소스, 설정)이 해시에 어떻게 반영되는지 확인
- **Xcode 버전 호환 문제** → CI와 로컬의 Xcode 버전 정렬

### Flutter 앱이라면?

Tuist 공식 문서에는 Flutter 전용 가이드가 없습니다. 다만 Flutter 툴체인이 iOS `Runner.xcodeproj`를 직접 읽고 수정하기 때문에(예: Flutter의 SPM 통합 때 Runner 프로젝트를 건드립니다), Runner를 Tuist로 생성하는 방식은 충돌할 가능성이 있습니다.

그래서 아래처럼 범위를 나눠서 판단하는 것을 권합니다.

- Runner는 그대로 두고, 네이티브 모듈이나 별도 iOS 앱에만 Tuist를 적용한다.
- Runner까지 적용하고 싶다면 별도 브랜치에서 `flutter build ios`가 통과하는지 먼저 실험한다.

> 이 항목은 공식 문서로 확인된 내용이 아니라 추론이 섞여 있으니, 적용 전에 꼭 직접 검증하세요.

### 최종 과제

샘플 앱(또는 개인 프로젝트)에 모듈화, 캐시, CI, 템플릿을 모두 적용하고 README로 정리합니다.

✅ **통과 기준:** CI에서 generate → build/test가 자동으로 통과하고, 새 팀원이 README만 보고 세팅할 수 있다.

---

## 최종 점검 체크리스트

- [ ] 생성된 `.xcodeproj`가 커밋되지 않았는가
- [ ] Tuist 버전이 `mise.toml`로 고정되어 있는가
- [ ] 외부 의존성이 `Tuist/Package.swift`에 모여 있는가
- [ ] 매니페스트에 하드코딩된 반복 설정이 없는가 (helper로 추출)
- [ ] 의존 방향이 한쪽으로만 흐르고 `enforceExplicitDependencies`를 통과하는가
- [ ] 릴리스 아카이브는 `--no-binary-cache`로 생성했는가
- [ ] 빌드·테스트 시간 비교 수치가 있는가
- [ ] 새 팀원이 README만 보고 세팅할 수 있는가

## 참고 자료

### 공식 문서 (이 글을 검증하는 데 사용)

- Install Tuist
- Manifests
- Directory structure
- Create a new project
- Add dependencies
- Cache
- Selective testing
- Templates
- Plugins
- Migrate an Xcode project

### 참고 (Flutter 관련 맥락)

- flutter/flutter#160214: Flutter가 iOS Xcode 프로젝트에 의존한다는 커뮤니티 의견

## 마치며

Tuist는 도구 자체보다 "프로젝트 구조를 코드로 관리한다"는 사고방식을 익히는 게 핵심입니다. 매니페스트 문법은 금방 익숙해지지만, 모듈 경계를 어떻게 긋고 의존성을 어떻게 관리할지는 결국 설계의 문제입니다.

4주 동안 각 주차의 통과 기준을 하나씩 체크해 보세요. 막히면 공식 문서가 가장 좋은 선생님입니다.
