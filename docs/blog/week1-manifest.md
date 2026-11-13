# Tuist 1주차: 매니페스트로 iOS 프로젝트 만들기

## TL;DR

- Tuist에서는 `Project.swift`가 **무엇을** 만들지(타깃, 번들 ID, 의존성), `Tuist.swift`가 **어떻게** 만들지(생성 옵션)를 정합니다.
- 타깃 하나가 모듈 하나입니다. 모듈 간 의존성은 각 타깃의 `dependencies`에서 선언하고, `Workspace.swift`는 어떤 프로젝트를 함께 보여줄지만 정합니다.
- 매니페스트에서 생략한 값은 "없음"이 아니라 **누군가의 기본값**이 됩니다. 배포 타깃을 생략했다가 실행할 시뮬레이터가 없어지는 문제를 겪었습니다.
- `mise.toml`은 버전을 정하는 약속일 뿐이고, 실제로 그 버전을 쓰게 만드는 건 셸 설정(`mise activate`)입니다.
- Debug/Release를 xcconfig로 분리해서 Debug 빌드는 "HyperFocus개발", Release 빌드는 "HyperFocus"라는 이름을 갖게 했습니다. 값은 xcconfig → 빌드 설정 → Info.plist → 앱 순서로 흐릅니다.
- 빌드 설정에는 프로젝트 레벨과 타깃 레벨이 있고, 타깃 쪽이 이깁니다. 설정을 생략하면 Tuist와 Xcode가 각자의 기본값을 채웁니다.

> 환경: Tuist 4.216.2(mise로 고정), Xcode 27.2

---

## 1주차 학습 주제

| 항목 | 내용 |
| --- | --- |
| 한 줄 목표 | 매니페스트 읽고 쓰기 |
| 핵심 키워드 | `Project.swift`, `Tuist.swift` |
| 기본 명령어 | `tuist init`, `tuist generate`, `tuist edit` |
| 통과 기준 | `tuist generate`만으로 앱이 빌드되고 실행된다 |

세부 학습 항목은 아래와 같습니다.

- 매니페스트 3종(`Project.swift`, `Workspace.swift`, `Tuist.swift`)의 역할
- 기본 디렉터리 구조
- Target 구성: 앱, 유닛 테스트, 리소스, Info.plist
- Settings와 xcconfig로 Debug/Release configuration 분리

---

## 학습 내용

### 1. `tuist init`과 첫 번째 실수

`tuist init`을 실행하면 대화형으로 프로젝트 이름을 묻습니다.

```
$ tuist init
✔︎ Start: Create a generated project
Name
  How would you like to name the project?
```

처음에 이 단계에서 "현재 폴더"라는 생각으로 `.`을 입력했고, 그 결과 이렇게 생성됐습니다.

```swift
name: ".",
bundleId: "dev.tuist..",
```

다시 init하지 않고 생성된 파일을 직접 고쳤는데, 이름이 생각보다 여러 곳에 퍼져 있었습니다.

| 위치 | 바꾼 내용 |
| --- | --- |
| `Project.swift` | 프로젝트 이름, 앱/테스트 타깃 이름, 번들 ID, 테스트 타깃의 의존성 |
| `Tuist/Package.swift` | 패키지 이름 |
| `Sources/__App.swift` | 파일 이름과 `struct __App` → `HyperFocusApp` |
| `Tests/__Tests.swift` | 파일 이름, `struct __Tests`, `@testable import __` → `HyperFocus` |

타깃 이름이 곧 **모듈 이름**이기 때문에 `@testable import`까지 같이 바꿔야 합니다.

### 2. `tuist init`이 만든 파일

| 파일 | 역할 |
| --- | --- |
| `Tuist.swift` | 프로젝트 루트 표시, 생성 옵션 |
| `Project.swift` | Xcode 프로젝트 하나를 선언 (타깃, 번들 ID, 의존성) |
| `Tuist/Package.swift` | 외부 라이브러리(SPM) 선언, `tuist install`로 받음 |
| `Sources/`, `Resources/`, `Tests/` | 앱 코드, 에셋, 테스트 |
| `mise.toml` | Tuist 버전 고정 |
| `.gitignore` | `*.xcodeproj`, `*.xcworkspace`, `Derived/` 등 생성물 제외 |

`Project.swift`의 `buildableFolders`는 폴더를 통째로 타깃에 연결합니다. `Sources/`에 파일을 추가하면 등록 없이 자동으로 빌드에 포함됩니다.

생성된 `.xcodeproj`를 Xcode에서 직접 수정하면 다음 `tuist generate`에서 사라집니다. 설정은 항상 매니페스트에서 바꿉니다.

### 3. 매니페스트: "무엇을"과 "어떻게"

공식 문서의 매니페스트 설명을 번역하면 이런 문장이 나옵니다.

> Tuist는 프로젝트와 워크스페이스를 정의하고 생성 프로세스를 구성하는 기본 방식으로 Swift 파일을 사용합니다.

"생성 프로세스를 구성"은 *configure the generation process*의 직역이라 어색한데, 파일별로 나눠 보면 의미가 분명해집니다.

| 원문 표현 | 의미 | 파일 |
| --- | --- | --- |
| 프로젝트를 정의 | **무엇을** 만들지 | `Project.swift` |
| 워크스페이스를 정의 | 어떤 프로젝트를 **묶을지** | `Workspace.swift` |
| 생성 프로세스를 구성 | **어떻게** 만들지 (생성 옵션) | `Tuist.swift` |

자연스럽게 다듬으면 이렇습니다.

> Tuist에서는 Swift 파일로 무엇을 만들지(프로젝트, 워크스페이스)와 어떻게 만들지(생성 옵션)를 모두 선언합니다. 이 파일들을 매니페스트 파일이라고 합니다.

### 4. 프로젝트, 타깃, 모듈, 워크스페이스

처음에 "`Project.swift` = 내가 만드는 모듈 구조"라고 이해했는데, 조금 더 정확히 하면 이렇습니다.

- **타깃 하나 = 모듈 하나.** `Project.swift`는 Xcode 프로젝트 하나이고, 그 안에 모듈(타깃)이 여러 개 들어갑니다.
- **모듈 간 의존성은 타깃의 `dependencies`에서 선언합니다.** `Workspace.swift`가 아닙니다.

| 의존 대상 | 쓰는 법 |
| --- | --- |
| 같은 `Project.swift`의 타깃 | `.target(name: "Core")` |
| 다른 `Project.swift`의 타깃 | `.project(target: "Core", path: "../Core")` |
| 외부 라이브러리 | `.external(name: "Alamofire")` |

- **`Workspace.swift`는 어떤 프로젝트를 함께 보여줄지만 정합니다.** 생략하면 Tuist가 의존성을 따라가서 워크스페이스를 자동으로 만듭니다. 이 저장소에 `Workspace.swift`가 없는데도 `HyperFocus.xcworkspace`가 생긴 이유입니다.
- **폴더 구조와 모듈 구조는 자동으로 같아지지 않습니다.** 폴더를 만든다고 모듈이 생기지 않고, 매니페스트에서 타깃과 `buildableFolders`로 연결해야 합니다.

### 5. 버전 고정: mise가 실제로 하는 일

"팀원이 Homebrew로 다른 버전을 설치했다면 이 폴더에서 `tuist version`은 무엇을 출력할까?"라는 질문으로 정리했습니다.

| 팀원 상황 | 결과 |
| --- | --- |
| mise 설치 + 셸에 활성화 | `mise.toml`의 고정 버전 |
| mise 없이 Homebrew만 | Homebrew 버전 (`mise.toml` 무시) |
| mise 설치했지만 활성화 안 함 | Homebrew 버전, 둘 다 없으면 `command not found` |

내 환경에서 확인한 결과입니다.

```
$ which -a tuist
~/.local/share/mise/installs/tuist/4.216.2/tuist
~/.local/share/mise/shims/tuist
```

- 첫 줄: `mise activate`가 고정 버전의 경로를 `PATH` 맨 앞에 넣어서 이게 실행됩니다.
- 둘째 줄: shim. 현재 폴더의 `mise.toml`을 보고 맞는 버전으로 넘겨주는 대리 실행 파일로, 셸 활성화가 없는 환경을 위한 예비 경로입니다.

`mise.toml`은 약속이고 강제하는 건 셸 설정입니다. 셸 설정을 믿기 어려운 CI에서는 `mise exec -- tuist generate`처럼 mise를 거쳐 실행합니다.

### 6. 트러블슈팅: "실행할 디바이스가 없다"

**증상**: Xcode에서 실행하려는데 고를 수 있는 시뮬레이터가 없었습니다.

**원인**: `Project.swift`에 배포 타깃을 지정하지 않으면 생성된 프로젝트에도 `IPHONEOS_DEPLOYMENT_TARGET`이 없고, Xcode는 **설치된 SDK 버전**을 최소 버전으로 씁니다.

| 항목 | 값 |
| --- | --- |
| Xcode SDK | iOS 27.2 → 최소 버전이 27.2가 됨 |
| 설치된 시뮬레이터 런타임 | iOS 26.5, 27.0 |

27.2 이상에서만 도는 앱을 실행할 기기가 없었던 것입니다.

**해결**: 두 타깃 모두에 배포 타깃을 명시하고 상수로 뺐습니다.

```swift
let deploymentTargets: DeploymentTargets = .iOS("18.0")

// 앱 타깃과 테스트 타깃 모두
deploymentTargets: deploymentTargets,
```

**검증**: 생성된 `project.pbxproj`에서 값이 몇 개 들어갔는지 셌습니다.

```
$ grep "IPHONEOS_DEPLOYMENT_TARGET" HyperFocus.xcodeproj/project.pbxproj | sort | uniq -c
   4 IPHONEOS_DEPLOYMENT_TARGET = 18.0;
```

4개는 2개 타깃 × Debug/Release입니다. 처음엔 앱 타깃에만 넣어서 2개였고, 이 숫자로 테스트 타깃이 빠진 걸 알아챘습니다. 매니페스트 한 줄이 Xcode 빌드 설정 몇 곳으로 바뀌는지 세어 보는 것이 좋은 검증 방법이었습니다.

이후 iOS 26.5 시뮬레이터에서 빌드와 테스트가 통과했습니다.

```
✔ Test run with 1 test in 1 suite passed after 0.003 seconds.
** TEST SUCCEEDED **
```

### 7. 실험: Tuist는 프로젝트 루트를 어떻게 찾나

"`Tuist.swift`는 내용이 비어 있는데 지우면 어떻게 될까?"를 임시 폴더에 복사해서 실험했습니다.

| 실험 | 결과 |
| --- | --- |
| `Tuist.swift`만 삭제 | `tuist generate` 성공 |
| `Tuist/` 폴더까지 삭제 | 실패 |

실패했을 때의 에러 메시지에 규칙이 나와 있었습니다.

```
Couldn't locate the root directory from path ...
The root directory is the closest directory that contains a Tuist or a .git directory.
```

`Tuist/` 폴더나 `.git`이 있으면 `Tuist.swift` 없이도 루트를 찾습니다. 그래도 `Tuist.swift`를 두는 이유는 두 가지입니다.

- 폴더 구조나 git 상태에 의존하지 않고 루트를 명시적으로 표시합니다.
- 2주차의 `enforceExplicitDependencies` 같은 **생성 옵션**을 넣는 곳입니다.

### 8. Debug/Release를 xcconfig로 분리

**목표**: Debug 빌드는 홈 화면에 "HyperFocus개발", Release 빌드는 "HyperFocus"로 보이게 만들기.

먼저 두 개념을 구분했습니다.

| 개념 | 예시 | 무엇을 나누나 |
| --- | --- | --- |
| 빌드 configuration | Debug / Release | 어떻게 빌드하나 (최적화, 디버그 심볼) |
| 환경 | Dev / Prod / Staging | 어디에 붙나 (API 서버, 앱 이름) |

처음에 xcconfig 파일 이름을 `Dev`/`Prod`로 지었다가, 지금 단계에서는 configuration과 1:1로 대응하는 `Debug`/`Release`로 바꿨습니다.

#### 1단계: xcconfig 파일 (같은 키, 다른 값)

```
// Configs/Debug.xcconfig
APP_DISPLAY_NAME = HyperFocus개발

// Configs/Release.xcconfig
APP_DISPLAY_NAME = HyperFocus
```

`APP_DISPLAY_NAME`처럼 직접 지은 키를 사용자 정의 빌드 설정이라고 합니다.

`Configs/` 폴더 위치는 Tuist의 규칙이 아니라 관례입니다.

| 구분 | 예시 |
| --- | --- |
| Tuist가 이름·위치로 직접 찾는 것 | `Tuist.swift`, `Tuist/Package.swift`, `Project.swift` |
| 매니페스트에 경로를 적는 것 | xcconfig, `buildableFolders`의 `Sources/` 등 |

#### 2단계: 매니페스트에서 xcconfig 연결

```swift
settings: .settings(
    configurations: [
        .debug(name: .debug, xcconfig: "./Configs/Debug.xcconfig"),
        .release(name: .release, xcconfig: "./Configs/Release.xcconfig"),
    ]
)
```

처음에는 이 블록을 `Project(...)`의 프로젝트 레벨에 넣었고, Xcode Build Settings에서 Debug/Release 값이 다르게 보이는 것을 확인했습니다. 위치는 뒤의 5단계에서 다시 바꿉니다.

#### 3단계: Info.plist와 연결

앱 타깃의 `infoPlist`에 한 줄을 추가합니다.

```swift
infoPlist: .extendingDefault(
    with: [
        "UILaunchScreen": [ ... ],
        "CFBundleDisplayName": "$(APP_DISPLAY_NAME)",
    ]
),
```

처음에는 두 가지를 틀렸습니다.

```swift
"CFBundleName": "APP_DISPLAY_NAME"
```

- **`$( )`가 없었습니다.** Xcode는 `$(...)`로 감싼 것만 빌드 설정 이름으로 알아봅니다. 감싸지 않으면 홈 화면에 "APP_DISPLAY_NAME"이라는 글자 자체가 나옵니다.
- **키가 달랐습니다.** 홈 화면에 보이는 이름은 `CFBundleDisplayName`입니다. `CFBundleName`은 번들의 짧은 이름으로, 표시 이름이 없을 때 대신 쓰입니다. 게다가 `extendingDefault`는 기본값에 키를 **추가**하지만, 같은 키를 쓰면 **덮어씁니다.** 실수로 Tuist 기본값인 `CFBundleName = $(PRODUCT_NAME)`을 덮어쓰고 있었습니다.

#### 4단계: Tuist와 Xcode의 역할 경계

`tuist generate`는 `Derived/InfoPlists/HyperFocus-Info.plist`를 만들고, 생성된 프로젝트는 이 파일을 가리킵니다.

```
INFOPLIST_FILE = "Derived/InfoPlists/HyperFocus-Info.plist";
```

이 파일도 생성물이라 직접 고치면 안 됩니다. 관찰해 보니 **내용이 바뀐 plist만 다시 써졌습니다.** 키를 추가한 앱 plist는 수정 시간이 바뀌었고, 테스트 plist는 처음 생성한 시간 그대로였습니다.

생성된 plist를 열어 보면 값이 모두 `$(...)` 그대로 남아 있습니다.

```xml
<key>CFBundleIdentifier</key>
<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
<key>CFBundleDisplayName</key>
<string>$(APP_DISPLAY_NAME)</string>
```

| 단계 | 담당 | 결과 |
| --- | --- | --- |
| `tuist generate` | Tuist | `$(...)`가 들어 있는 plist 틀 |
| 빌드 | Xcode | `$(...)`를 현재 configuration 값으로 치환해서 앱 번들에 넣음 |

매니페스트의 `bundleId`도 똑같은 길을 갑니다.

```
bundleId: "com.hyperfocus.timer"  (Project.swift)
   → PRODUCT_BUNDLE_IDENTIFIER    (빌드 설정)
   → $(PRODUCT_BUNDLE_IDENTIFIER) (Info.plist)
   → com.hyperfocus.timer         (빌드된 앱)
```

Debug와 Release를 각각 빌드한 뒤 앱 번들 안의 Info.plist를 읽어서 확인했습니다.

```
$ /usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' .../Debug-iphonesimulator/HyperFocus.app/Info.plist
HyperFocus개발
$ /usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' .../Release-iphonesimulator/HyperFocus.app/Info.plist
HyperFocus
```

같은 plist 틀 하나로 configuration마다 다른 이름이 들어갔습니다.

> 💡 Info.plist를 매니페스트가 아니라 파일로 관리하고 싶다면 `infoPlist: .file(path: "Resources/Info.plist")`를 씁니다. 이 경우 Tuist는 파일을 가리키기만 하고 생성하거나 덮어쓰지 않습니다. 기존 앱을 옮길 때 현실적인 선택지입니다.

#### 5단계: 프로젝트 레벨 → 앱 타깃 레벨로 이동

프로젝트 레벨에 넣었더니 테스트 타깃에도 `APP_DISPLAY_NAME`이 생겼습니다. 테스트 plist에는 `CFBundleDisplayName`이 없어서 아무도 읽지 않는 값이었지만, "앱 표시 이름은 앱만의 관심사"라서 `settings`를 앱 타깃의 `dependencies` 뒤로 옮겼습니다.

```swift
.target(
    name: "HyperFocus",
    ...
    dependencies: [],
    settings: .settings(
        configurations: [
            .debug(name: .debug, xcconfig: "./Configs/Debug.xcconfig"),
            .release(name: .release, xcconfig: "./Configs/Release.xcconfig"),
        ]
    ),
),
```

타깃별 빌드 설정으로 확인했습니다.

```bash
xcodebuild -showBuildSettings -project HyperFocus.xcodeproj -target HyperFocus -configuration Debug | grep APP_DISPLAY_NAME
```

| 타깃 / configuration | `APP_DISPLAY_NAME` |
| --- | --- |
| HyperFocus / Debug | HyperFocus개발 |
| HyperFocus / Release | HyperFocus |
| HyperFocusTests / Debug | (없음) |
| HyperFocusTests / Release | (없음) |

### 9. 빌드 설정의 레벨과 우선순위

`settings`는 두 군데에 넣을 수 있습니다. 이건 Tuist가 만든 구조가 아니라 Xcode 빌드 설정 구조를 그대로 옮긴 것입니다.

| 매니페스트 | Xcode 화면 | 적용 범위 |
| --- | --- | --- |
| `Project(settings:)` | PROJECT | 그 프로젝트의 모든 타깃 |
| `.target(settings:)` | TARGETS | 그 타깃만 |

같은 키가 여러 곳에 있으면 위에 있는 값이 이깁니다.

| 우선순위 | 출처 | 매니페스트에서 |
| --- | --- | --- |
| 1 (가장 높음) | 타깃 빌드 설정 | `.target`의 settings 값 + `bundleId` 같은 타깃 파라미터 |
| 2 | 타깃 xcconfig | `.target`의 settings의 `xcconfig:` |
| 3 | 프로젝트 빌드 설정 | `Project`의 settings 값 + Tuist 권장 설정 |
| 4 | 프로젝트 xcconfig | `Project`의 settings의 `xcconfig:` |
| 5 (가장 낮음) | Xcode 플랫폼 기본값 | 프로젝트 파일에 적히지 않음 |

이 표로 이번 주에 겪은 일이 모두 설명됩니다.

- **타깃 레벨 이동**: `APP_DISPLAY_NAME`을 4번에서 2번으로 옮겨서 테스트 타깃이 더 이상 물려받지 않습니다.
- **xcconfig에 번들 ID를 넣으면 무시되는 이유**: 매니페스트의 `bundleId`는 1번으로 들어가서 2번의 xcconfig 값을 이깁니다.
- **배포 타깃이 iOS 27.2가 된 이유**: 1~4번 어디에도 값이 없어서 5번까지 내려갔습니다.

Xcode Build Settings에서 **Levels** 보기를 켜면 각 레벨의 값과 최종 값을 나란히 볼 수 있습니다.

### 10. 생략했을 때의 기본값은 층마다 다르다

프로젝트 레벨의 `settings`를 지웠는데도 Debug/Release configuration은 그대로 남았습니다. Tuist가 기본 configuration으로 Debug와 Release를 만들어 주기 때문입니다.

처음엔 이것도 "Xcode 플랫폼 기본값"이라고 생각했는데, 생성된 `project.pbxproj`를 열어 보니 달랐습니다. 매니페스트의 프로젝트 레벨에는 아무것도 쓰지 않았는데, 프로젝트 레벨 configuration에 설정이 **Debug 50개, Release 47개** 적혀 있었습니다. `ALWAYS_SEARCH_USER_PATHS`, `CLANG_ENABLE_MODULES` 같은 값들입니다.

이건 `.settings(...)`의 `defaultSettings: .recommended`가 기본값이라서, Tuist가 권장 빌드 설정을 프로젝트 파일에 직접 써 넣은 것입니다.

| 기본값 | 누가 | 프로젝트 파일에 적히나 |
| --- | --- | --- |
| configuration 목록 (Debug/Release) | Tuist | ⭕ |
| 권장 빌드 설정 (`.recommended`) | Tuist | ⭕ |
| 플랫폼 기본값 (예: 배포 타깃 = SDK 버전) | Xcode | ❌ |

`defaultSettings`는 `.recommended`, `.essential`, `.none` 중에서 고를 수 있습니다. 기존 앱의 설정을 원본과 똑같이 맞춰야 하는 마이그레이션에서는 `.none`을 검토하게 됩니다.

---

## TIL (Today I Learned)

- **생략한 값은 기본값이 된다.** 그리고 그 기본값은 Tuist가 쓴 것(프로젝트 파일에 적힘)과 Xcode가 쓰는 것(적히지 않음)으로 나뉜다.
- **매니페스트 한 줄이 Xcode에서 어디로 가는지 세어 보자.** `IPHONEOS_DEPLOYMENT_TARGET`이 2개냐 4개냐로 빠진 타깃을 찾았다.
- **타깃 이름 = 모듈 이름.** 이름을 바꾸면 `@testable import`까지 바뀌어야 한다.
- **의존성은 `Project.swift`의 타깃이, 묶음은 `Workspace.swift`가 정한다.** 워크스페이스는 생략해도 된다.
- **`mise.toml`은 약속, 강제는 셸 설정.** `which -a`로 실제 실행 경로를 확인할 수 있다.
- **Tuist의 루트는 `Tuist.swift`, `Tuist/`, `.git` 중 하나로 찾는다.** 추측보다 실험이 정확했다.
- **configuration(어떻게 빌드)과 환경(어디에 붙나)은 다른 개념이다.**
- **Tuist는 plist 틀을 만들고, `$(...)` 값은 Xcode가 빌드할 때 채운다.**
- **`extendingDefault`에 같은 키를 쓰면 기본값을 덮어쓴다.**
- **빌드 설정은 타깃 레벨이 프로젝트 레벨을 이긴다.** "이 값이 누구에게 필요한가"로 둘 곳을 정한다.
- **`tuist edit`은 편집용 프로젝트를 열고 바로 끝난다.** 편집 후 저장하고 바로 `tuist generate`하면 된다.

---

## 다음 할 일

- [ ] 시뮬레이터 홈 화면에서 "HyperFocus개발" 직접 확인 (빌드된 앱의 Info.plist로는 확인 완료)
- [ ] entitlements 다루기
- [ ] 최소 iOS 18.0을 고른 이유를 README에 기록
- [ ] README의 진행 상황 체크리스트와 프로젝트 구조(`Configs/`) 갱신
- [ ] 2주차: 모듈 분리와 `enforceExplicitDependencies`

## 참고 자료

- [Tuist 공식 문서: Manifests](https://tuist.dev/en/docs/guides/features/projects/manifests)
- [Tuist 공식 문서: Directory structure](https://tuist.dev/en/docs/guides/features/projects/directory-structure)
- [Tuist 공식 문서: Dependencies](https://tuist.dev/en/docs/guides/features/projects/dependencies)
- [ProjectDescription API 레퍼런스](https://projectdescription.tuist.dev/documentation/projectdescription)
