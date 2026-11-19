# Tuist 3주차: 바이너리 캐시와 선택적 테스트를 숫자로 확인하기, 그리고 scaffold

## TL;DR

- **바이너리 캐시: 클린 빌드 55.4초 → 10.9초(-80%).** 줄어든 시간은 모두 외부 의존성 컴파일 몫입니다.
- **선택적 테스트: 48.1초 → 45.0초.** 측정 오차 범위 안이라 효과를 확인하지 못했습니다. 앱을 띄우는 `HyperFocusTests`가 모든 Feature에 의존해서 매번 다시 실행되는 구조가 원인으로 보입니다.
- **`tuist build`는 이제 빌드하지 않습니다.** 이 글의 측정은 `xcodebuild`로 했습니다.
- **`tuist scaffold Feature --name <이름>`** 으로 Feature 모듈 파일을 만드는 템플릿을 추가했습니다.

> 환경: Tuist 4.216.2(mise로 고정), Xcode 27.2, macOS 26.6, MacBook Pro(M3 Pro, 11코어, 18GB)

---

## 3주차 학습 주제

[로드맵](../tuist-roadmap.md)의 3주차 제목은 "측정하지 않으면 개선이 아니다"이고, 통과 기준은 "캐시와 선택적 테스트를 적용하고, 개선 효과를 수치로 설명할 수 있다"입니다.

| 주제 | 이 글에서 |
| --- | --- |
| 바이너리 캐시 (`tuist cache`, 캐시 프로필) | ✅ 2절 |
| 선택적 테스트 (`tuist test`) | ✅ 3절 |
| `tuist build`, `tuist test`, `tuist run` | ✅ 1절, 5절 |
| 템플릿 (`tuist scaffold`) | ✅ 4절 |
| 2주차에 미뤄 둔 질문: Data를 나눌까? | ✅ 6절 |
| 원격 캐시 공유, 플러그인 | ⏭ 다루지 않음 (Tuist 서버 연동 없음) |

[2주차](week2-modularization.md)에서 앱을 `FocusTimer`, `SessionHistory` 두 Feature와 `Data`, `Utils` 모듈로 나눴습니다. 3주차는 이 그래프 위에서 시간을 잽니다.

이 글에서 자주 쓰는 용어입니다.

| 용어 | 뜻 |
| --- | --- |
| 클린 빌드 | DerivedData를 지운 상태에서 처음부터 하는 빌드. 새로 clone한 팀원이나 CI가 겪는 시간입니다 |
| 바이너리 캐시 | 이미 컴파일한 타깃을 `.xcframework`로 저장해 두고, 프로젝트를 생성할 때 원본 타깃 대신 끼워 넣는 기능 |
| 해시 | 타깃의 소스, 설정, 의존성으로 계산한 지문. 해시가 같으면 "바뀌지 않았다"고 판단합니다 |
| 선택적 테스트 | 마지막으로 성공한 실행 이후 해시가 바뀐 테스트 타깃만 다시 실행하는 기능 |
| app-hosted 테스트 | 앱을 시뮬레이터에 띄운 뒤 그 안에서 실행하는 유닛 테스트. 이 프로젝트에서는 `HyperFocusTests` |
| swift-syntax | Swift 매크로가 쓰는 컴파일러 수준의 라이브러리. TCA의 매크로가 의존하며, 소스로 빌드하면 무겁기로 알려져 있습니다 |

---

## 학습 내용

### 1. 재기 전에: `tuist build`는 빌드하지 않는다

예전의 `tuist build`는 `xcodebuild`를 대신 호출해 주는 빌드 명령이었습니다. 설치된 4.216.2에서 도움말을 보면 성격이 바뀌었습니다.

```
$ tuist build --help
OVERVIEW: A set of commands to manage your project builds.

SUBCOMMANDS:
  list                    Lists all builds in a project.
  show                    Shows information about a build.
  xcode                   A set of commands to inspect Xcode build details.
  ...
```

이제는 이미 실행된 빌드 기록을 조회하는 inspection 명령(조회 명령)의 묶음입니다. `tuist generate`, `tuist test`에도 `list`, `show` 하위 명령이 생겼고, 기존 동작은 기본 하위 명령(`run`)으로 남아 있습니다. 그래서 측정에는 `xcodebuild`를 직접 썼습니다. 함께 확인한 차이는 다음과 같습니다.

| 예전 방식 | 4.216.2에서 |
| --- | --- |
| `tuist build`로 빌드 | 빌드 기록 조회 명령. 빌드는 `xcodebuild build` |
| `--no-binary-cache` | 그대로 유효. 더 세밀하게 고르려면 `--cache-profile` |
| `tuist test --derived-data-path` | deprecated. `tuist test -- -derivedDataPath <경로>`처럼 `--` 뒤에 `xcodebuild` 인자로 넘김 |

> 💡 2주차의 `enforceExplicitDependencies`에 이어 두 번째입니다. 문서에 적힌 옵션은 **설치된 버전의 `--help`로 먼저 확인**합니다. 로드맵 문서도 이 표대로 고쳤습니다.

### 2. 바이너리 캐시: 클린 빌드 -80%

#### 측정 방법

바꾼 것은 캐시 프로필 하나뿐이고, 나머지는 모두 고정했습니다.

- 매번 `build/DerivedData`를 지우고 클린 빌드
- 같은 명령, 같은 destination
- 3번씩 재서 중앙값 사용
- 시간은 `xcodebuild`만 잼 (`tuist generate` 시간은 포함하지 않음)

```bash
# 적용 전: 캐시를 쓰지 않고 모든 타깃을 소스로 생성
tuist generate --no-open --cache-profile none

# 적용 후: 캐시를 데운 뒤 기본 프로필(only-external)로 생성
tuist cache            # = tuist cache warm (기본 하위 명령)
tuist generate --no-open

# 측정 (양쪽 동일)
rm -rf build/DerivedData
time xcodebuild build \
  -workspace HyperFocus.xcworkspace \
  -scheme HyperFocus \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/DerivedData
```

`--cache-profile`은 어떤 타깃을 바이너리로 바꿀지 고르는 옵션입니다.

| 프로필 | 바이너리로 바꾸는 범위 |
| --- | --- |
| `only-external` (기본값) | 외부 의존성만 (TCA, swift-dependencies 등) |
| `all-possible` | 내부 모듈까지 가능한 모든 타깃 |
| `none` | 없음. 모두 소스로 빌드 (`--no-binary-cache`와 같은 효과) |

#### 결과

| 항목 | 캐시 없음 (`none`) | 캐시 사용 (`only-external`) |
| --- | --- | --- |
| 클린 빌드 (3회 중앙값) | 55.4초 | 10.9초 (-80%) |

`tuist cache`는 54개 타깃(외부 50개 + `Utils`, `Data`, `FocusTimer`, `SessionHistory`)을 저장했고, 142초가 걸렸습니다. 이 142초는 위 비교 시간에 포함하지 않았습니다.

#### 해석

- **줄어든 44.5초는 모두 외부 의존성 몫입니다.** 내부 모듈은 두 조건 모두 소스로 빌드했으니, 차이는 외부 타깃을 바이너리로 바꾼 데서만 나옵니다. 즉 이 앱의 클린 빌드 시간 80%가 외부 의존성 컴파일이었습니다. 의존성별로 몇 초씩인지는 재지 않았지만, 매크로 때문에 swift-syntax를 함께 빌드하는 TCA가 큰 몫일 것으로 봅니다.
- **캐시를 데우는 비용은 클린 빌드 4번째부터 돌려받습니다.** 142초 ÷ 44.5초 ≈ 3.2회입니다. 다만 몇 가지를 감안해야 합니다.
  - `tuist help cache warm`에 따르면 타깃을 지정하지 않은 `tuist cache`는 내부 모듈까지 데웁니다. 이번 비교(`only-external`)에 쓰지 않은 내부 모듈 몫이 142초에 섞여 있어서, 실제 본전은 조금 더 빠릅니다. 외부만 데우려면 `tuist cache --cache-profile only-external`을 씁니다.
  - Tuist나 Xcode, 의존성 버전이 바뀌어 해시가 달라지면 데우는 비용을 다시 냅니다.
  - 이 계산은 로컬 클린 빌드에만 해당합니다. 이 프로젝트는 Tuist 서버와 연결하지 않아서(`Tuist.swift`의 `fullHandle`이 주석 처리돼 있음) 캐시는 **이 Mac에만** 있습니다. 로드맵이 권하는 "CI에서 main 커밋마다 캐시 데우기"의 이득을 팀이 나누려면 원격 캐시가 필요합니다.
- **캐시는 개발용입니다.** 배포용 아카이브는 `--no-binary-cache`(또는 `--cache-profile none`)로 생성한 소스 기반 프로젝트에서 만듭니다.

### 3. 선택적 테스트: 효과를 확인하지 못한 이유

#### 측정 방법

"모듈 하나만 고친 뒤 테스트를 다시 돌리는 상황"을 재현했습니다.

1. `SessionHistoryView.swift` 끝에 주석 한 줄을 붙여 `SessionHistory`의 해시를 바꿉니다.
2. 선택적 테스트를 끄고 켠 상태로 각각 3번 잽니다.
3. UI 테스트는 제외하고, DerivedData는 미리 데워 둔 `build/TestDerivedData`를 씁니다.

```bash
# 적용 전: 모든 테스트 실행
time tuist test --skip-ui-tests --no-selective-testing -- -derivedDataPath build/TestDerivedData

# 적용 후: 바뀐 타깃의 테스트만 실행 (기본값)
time tuist test --skip-ui-tests -- -derivedDataPath build/TestDerivedData
```

#### 결과

| 항목 | 선택적 테스트 끔 | 선택적 테스트 켬 |
| --- | --- | --- |
| 모듈 1개 변경 후 테스트 (3회 중앙값) | 48.1초 | 45.0초 |

중앙값으로는 3.1초(6%) 줄었지만, 3번의 측정값 범위가 서로 겹쳤습니다. 3번 측정으로는 차이를 확인하지 못했다고 보는 게 맞습니다.

#### 왜 효과가 작았나 (그래프와 로그에서 추론)

실행 로그를 보면 선택적 테스트가 건너뛴 것은 `FocusTimerTests` 하나뿐이었습니다. `FocusTimerTests`는 `TestClock`으로 시간을 건너뛰는 가벼운 테스트라 원래 실행 비용이 작습니다. 무거운 쪽은 `HyperFocusTests`입니다.

```
HyperFocusTests (app-hosted)
   ├──→ HyperFocus (App) ──→ FocusTimer ──→ Utils
   │                    └──→ SessionHistory ──→ Data
   └──→ Data
```

- `HyperFocusTests`는 App에 의존하고, App은 **모든 Feature**에 의존합니다. `Data`에도 직접 의존합니다.
- 그래서 Feature나 `Data`를 고치면 `HyperFocusTests`의 해시도 바뀌어 다시 실행됩니다.
- 로그 기준으로 이 테스트는 시뮬레이터와 앱을 준비하는 데만 약 18초를 썼습니다.

선택적 테스트가 건너뛸 수 있었던 건 처음부터 싼 테스트뿐이었고, **비싼 테스트는 그래프 꼭대기에 있어서** 이번 변경으로는 피할 수 없었습니다. 다만 45초 가운데 빌드와 테스트 실행이 각각 얼마인지는 나눠 재지 않았고, 시험한 변경도 `SessionHistory` 한 가지뿐입니다. 이 설명은 측정이 아니라 추론입니다.

개선 방향은 로드맵의 "타깃을 작고 집중적으로 유지하라"와 같습니다. 선택적 테스트는 **타깃 단위**로 판단하므로, 앱을 띄울 필요가 없는 테스트는 Feature의 `XxxTests`로 옮기고 `HyperFocusTests`에는 `RootFeature`처럼 정말 앱이 필요한 테스트만 남깁니다.

#### 측정할 때 주의할 점

- **`--no-selective-testing`으로 돌려도 성공 기록은 남습니다.** 성공한 테스트 타깃마다 그 해시 이름의 폴더가 `~/.cache/tuist/SelectiveTests` 아래에 생기고, 다음 실행에서 같은 해시의 폴더가 있으면 건너뛰는 것으로 보입니다. 그래서 끈 상태로 돌린 직후 켠 상태로 돌리면 바뀐 게 없어 테스트가 거의 실행되지 않습니다. 비교하려면 실행 전마다 소스를 바꿔 해시를 새로 만들어야 합니다.
- **`tuist test`는 테스트 대상이 아닌 내부 모듈도 바이너리로 바꿀 수 있습니다(실행 로그 기준).** `tuist test`에는 `--cache-profile` 옵션이 없고 `--binary-cache/--no-binary-cache`만 있습니다. 그래서 이번 측정 명령은 캐시를 켠 상태였습니다.

### 4. `tuist scaffold`: 새 Feature를 만드는 규칙을 코드로

2주차에 정한 Feature 모듈의 모양(Sources, Example, Tests)을 사람이 매번 기억해서 만들면 언젠가 어긋납니다. 이 규칙을 템플릿으로 남겼습니다.

#### 그래프 연결은 일부러 수작업으로

먼저 결정부터 적습니다. scaffold는 **파일만** 만듭니다. 이 프로젝트는 `Project.swift` 하나에 모든 타깃을 선언하는 Mono-project라서, 새 Feature를 그래프에 넣으려면 `Target.feature(...)` 호출 하나를 직접 추가해야 합니다.

```swift
    + Target.feature(
        name: "SessionHistory",
        dependencies: [.target(name: "Data")]
    )
    + Target.feature(          // ← 새로 추가
        name: "Settings",
        dependencies: [.target(name: "Data")]
    )
```

앞의 `+`는 diff 기호가 아니라 타깃 배열을 잇는 연산자입니다. 앱 화면에 붙이려면 `HyperFocus` 타깃의 `dependencies`에도 추가해야 합니다.

이 호출까지 자동화하지 않은 이유는 **의존성이 Feature마다 다르기** 때문입니다. `FocusTimer`는 `Utils`에, `SessionHistory`는 `Data`에 의존합니다. 템플릿에 옵션으로 받을 수도 있지만, 이 호출은 코드 리뷰에서 "이 Feature가 무엇을 아는가"를 눈으로 확인하는 지점입니다. 자동으로 들어가면 오히려 그 확인을 놓치기 쉽습니다.

#### 구조

```
Tuist/Templates/Feature/
├── Feature.swift        ← 템플릿 매니페스트 (폴더 이름과 같아야 함)
├── Feature.stencil      ← {{ name }}Feature (Reducer)
├── View.stencil         ← {{ name }}View
├── ExampleApp.stencil   ← {{ name }}ExampleApp
└── Tests.stencil        ← {{ name }}FeatureTests
```

```swift
// Feature.swift
import ProjectDescription

let nameAttribute: Template.Attribute = .required("name")

let template = Template(
    description: "TMA Feature 모듈 (Sources, Example, Tests)",
    attributes: [nameAttribute],
    items: [
        .file(
            path: "Modules/Features/\(nameAttribute)/Sources/\(nameAttribute)Feature.swift",
            templatePath: "Feature.stencil"
        ),
        // View, ExampleApp, Tests도 같은 방식
    ]
)
```

`tuist scaffold Feature --name Settings`를 실행하면 `Modules/Features/Settings/` 아래에 파일 4개가 생깁니다. 이름은 처음에 `TMATemplate`였는데, `Templates/` 안에서 "Template"은 중복이고 명령이 "Settings라는 Feature를 만든다"로 읽히도록 `Feature`로 바꿨습니다. "TMA"는 `description`에 두어 `tuist scaffold list`에서 보이게 했습니다.

#### Stencil: 빈칸이 있는 텍스트 파일

처음에 가장 헷갈렸던 부분입니다. `.stencil`은 내용이 평범한 Swift 코드이고, 이름이 들어갈 자리만 `{{ name }}`으로 비워 둔 파일입니다.

```swift
@Reducer
public struct {{ name }}Feature {
    @ObservableState
    public struct State: Equatable {
        public init() {}
    }
    ...
}
```

보간이 두 종류라서 헷갈립니다. 둘 다 결국 `--name`으로 넘긴 값으로 바뀝니다.

| 쓰는 곳 | 문법 | 정하는 것 |
| --- | --- | --- |
| 매니페스트 (`Feature.swift`) | Swift 문자열 보간 `\(nameAttribute)` | 파일이 **생성될 경로** |
| 템플릿 파일 (`.stencil`) | Stencil 문법 `{{ name }}` | 파일의 **내용** |

템플릿 코드는 일부러 최소한으로 만들었습니다. State는 비어 있고 Action은 `onAppear` 하나뿐입니다. 목표는 **생성 직후에도 컴파일되고 테스트가 통과하는 것**입니다. 실제로 `Settings`를 생성해 임시로 그래프에 붙이고 `tuist test Settings`를 돌려 Example 앱 빌드와 테스트 통과를 확인한 뒤 지웠습니다.

#### 트러블슈팅

| 증상 | 해결 |
| --- | --- |
| `Could not find template ... in: .../Templates` | `--path`는 생성 위치뿐 아니라 **템플릿을 찾는 기준 경로**도 바꿉니다. 저장소 루트에서 `--path` 없이 실행합니다 |
| `Feature.swift not found at path .../Templates/Feature` | Tuist는 `Templates/` 아래 **모든 폴더**를 템플릿으로 읽습니다. 빈 폴더를 지웁니다 |
| `tuist scaffold list`에 템플릿이 안 보임 | 매니페스트를 `Templates/<이름>/<이름>.swift` 구조로 둡니다 |
| `We could not find external dependencies` | 생성한 Feature를 붙여 `tuist generate`할 때 나왔습니다. 외부 의존성 소스는 `tuist install`로 받아야 합니다 |

### 5. Example 앱 실행: `tuist run`

`FocusTimerExample`이라는 스킴은 따로 없습니다. Tuist가 만든 `FocusTimer` 스킴 하나에 역할이 나뉘어 들어 있습니다.

| 스킴 액션 | 대상 |
| --- | --- |
| Build | `FocusTimer`, `FocusTimerExample` |
| Test | `FocusTimerTests` |
| Run | `FocusTimerExample` |

그래서 Xcode에서는 `FocusTimer` 스킴을 고르고 ⌘R을 누르면 Example 앱이 뜨고, 터미널에서는 이렇게 실행합니다.

```bash
tuist run FocusTimer --device "iPhone 17 Pro"
```

`tuist test`에서도 스킴 이름은 `FocusTimer`입니다. `FocusTimerTests`를 넘기면 `Couldn't find scheme`이 나옵니다. 기기는 `--device`로 지정합니다.

```bash
tuist test FocusTimer --device "iPhone 17 Pro"
```

이번 환경에서는 `-- -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`로 넘겼을 때 `Unable to find a device matching the provided destination specifier`가 나며 실패했고, 후보 목록에는 My Mac만 나왔습니다. `-- -destination 'id=<시뮬레이터 UDID>'`처럼 UDID로 넘기면 동작했습니다.

### 6. 2주차에 미뤄 둔 질문: Data를 나눌까?

2주차에는 "측정해 보고 `Data`를 `DataInterface`와 구현으로 나눌지 정하자"고 미뤄 뒀습니다. 나누자는 신호는 두 가지로 정해 두었습니다.

- Example 앱 빌드가 무거워진다.
- `Data`를 고칠 때마다 Feature가 다시 빌드되는 시간이 아프다.

**이번에는 두 신호를 재지 않았습니다.** 알 수 있는 건 상한뿐입니다. 캐시를 쓴 클린 빌드 10.9초 안에 App과 내부 모듈 4개의 컴파일이 모두 들어 있으니, 우리 코드의 컴파일 비용은 지금 크지 않습니다.

그래서 `Data`는 하나로 유지합니다. 이 결정의 근거는 측정이 아니라 비용입니다. 나누면 2주차에 겪은 정적 링크 문제(`liveValue`가 링크에서 빠지는 문제)를 다시 다뤄야 합니다. Feature가 늘어나면 `Data` 증분 빌드와 Example 빌드 시간을 재서 다시 판단합니다.

### 통과 기준 점검

| 기준 | 결과 |
| --- | --- |
| 캐시를 적용하고 효과를 수치로 설명 | ✅ 2절 |
| 선택적 테스트를 적용하고 효과를 수치로 설명 | ✅ 3절 (효과 없음과 그 원인 추정) |
| 새 모듈을 만드는 규칙을 코드로 남김 | ✅ 4절 |

### 이번 측정의 한계

- 측정 횟수가 항목마다 3회이고, 실행별 원시 값을 남기지 않아 범위를 표로 보여 줄 수 없습니다.
- 시간은 `xcodebuild`와 `tuist test`만 쟀고, `tuist generate` 시간은 넣지 않았습니다.
- 선택적 테스트 측정에서 실행마다 해시를 새로 만들었는지, 끔과 켬을 어떤 순서로 실행했는지 기록하지 않았습니다.
- 빌드와 테스트 실행 시간, 의존성별 컴파일 시간은 나눠 재지 않았습니다.

다음에 다시 잴 때는 조건당 5회 이상, 실행별 값 기록, 끔과 켬 번갈아 실행(매번 해시 새로 만들기), `xcodebuild -showBuildTimingSummary`로 타깃별 시간 확인을 함께 하려고 합니다.

---

## TIL (Today I Learned)

- **측정은 바꾸는 변수를 하나로 줄이고, 잰 것과 추론한 것을 구분해서 적습니다.**
- **범위가 겹치면 "빨라졌다"고 말하지 않습니다.** 중앙값이 줄었어도 차이를 확인하지 못한 것입니다.
- **선택적 테스트의 효과는 도구보다 그래프 구조에 달려 있습니다.** 비싼 테스트가 모든 모듈에 의존하는 타깃에 있으면 대부분의 변경에서 피할 수 없습니다.
- **버전이 빠르게 바뀌는 도구는 문서보다 설치된 버전의 `--help`가 정답입니다.**

---

## 다음 글에서 다룰 것

4주차: 혼자 되는 것과 팀이 쓰는 것은 다르다

- CI 파이프라인: `mise install` → `tuist install` → `tuist generate` → `xcodebuild` / `tuist test`
- main 커밋마다 캐시를 데우는 잡과 원격 캐시 공유 검토
- 배포용 아카이브는 `--no-binary-cache`로 생성한 소스 기반 프로젝트에서
- 남은 정리: 오래된 `HyperFocusUITests`(아직 "Hello, World!"를 기대함)

---

## 부록

### 측정 환경

| 항목 | 값 |
| --- | --- |
| 기기 | MacBook Pro, Apple M3 Pro (11코어: 성능 5 + 효율 6), 메모리 18GB |
| Tuist | 4.216.2 (mise로 고정) |
| Xcode | 27.2 |
| 측정 횟수 | 항목마다 3회, 중앙값 |
| 클린 빌드 대상 | `HyperFocus` 스킴, `generic/platform=iOS Simulator` |
| 테스트 대상 | UI 테스트 제외, `build/TestDerivedData` 미리 데움 |

### 커밋 이력

| 커밋 | 내용 |
| --- | --- |
| `docs: 로드맵 CLI 설명을 Tuist 4.216.2 기준으로 보정하고 3주차 측정값 기록` | `tuist build`, 캐시 옵션 보정, 측정 표 채움 |
| `feat: Feature 모듈을 생성하는 scaffold 템플릿 추가` | `Tuist/Templates/Feature/` |

---

## 참고 자료

- [Tuist 공식 문서: Cache](https://tuist.dev/en/docs/guides/features/cache)
- [Tuist 공식 문서: Selective testing](https://tuist.dev/en/docs/guides/features/selective-testing)
- [Tuist 공식 문서: Templates](https://tuist.dev/en/docs/guides/features/projects/templates)
- [Stencil 문서](https://stencil.fuller.li/)
