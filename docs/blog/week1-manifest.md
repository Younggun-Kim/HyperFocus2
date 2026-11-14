# Tuist 1주차: 매니페스트로 iOS 프로젝트 만들기

## TL;DR

- Tuist는 Swift 코드(매니페스트)로 Xcode 프로젝트를 선언하고, `tuist generate`로 만들어 냅니다. 1주차 목표였던 "명령 하나로 앱 빌드·실행"을 통과했습니다.
- 매니페스트에서 생략한 값은 사라지지 않고 **Tuist나 Xcode가 채운 기본값**이 됩니다. 최소 iOS 버전을 빠뜨렸다가 실행할 시뮬레이터가 사라지는 일을 겪었습니다.
- Debug 빌드와 Release 빌드가 홈 화면 이름과 App Group을 각자 갖도록 설정을 분리하면서, Xcode가 설정 값을 어디서 찾는지 정리했습니다. UI 테스트 타깃까지 추가해 1주차 학습 항목을 모두 마쳤습니다.

> 환경: Tuist 4.216.2(mise로 고정), Xcode 27.2, macOS 26.6

---

## 1주차 학습 주제

로드맵의 1주차 목표는 **매니페스트 읽고 쓰기**이고, 통과 기준은 "`tuist generate`만으로 앱이 빌드되고 실행된다"입니다. 다룬 내용은 아래와 같습니다.

- 기본 명령어: `tuist init`, `tuist generate`, `tuist edit`
- 매니페스트 3종(`Project.swift`, `Workspace.swift`, `Tuist.swift`)의 역할
- 타깃 구성: 앱, 유닛 테스트, UI 테스트, 리소스, Info.plist, entitlements
- 설정 파일(xcconfig)로 Debug/Release 설정 분리

이 글에서 자주 쓰는 용어를 먼저 정리합니다.

| 용어 | 뜻 |
| --- | --- |
| 매니페스트 | 프로젝트 구조를 선언하는 Swift 파일. `Project.swift`, `Tuist.swift` 등 |
| 타깃 | 빌드 결과물 하나(앱, 테스트 번들 등). Swift에서는 기본적으로 타깃 하나가 `import`할 수 있는 모듈 하나가 됩니다 |
| 빌드 설정 | Xcode Build Settings 화면의 `KEY = VALUE` 값들. 예: `PRODUCT_BUNDLE_IDENTIFIER` |
| configuration | 같은 코드를 다른 빌드 설정으로 빌드하는 단위. 기본은 Debug와 Release |
| xcconfig | 빌드 설정을 `KEY = VALUE` 형식으로 적어 두는 텍스트 파일 |
| entitlements | 앱이 쓸 수 있는 시스템 기능(자격)을 선언하는 파일. 코드 서명에 함께 들어갑니다 |

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

처음에 "현재 폴더"라는 뜻으로 `.`을 입력했더니 다음과 같이 생성됐습니다.

```swift
// Project.swift (❌ 틀린 예: 이름에 . 이 들어감)
name: ".",
bundleId: "dev.tuist..",
```

다시 init하지 않고 생성된 파일을 직접 고쳤는데, 이름이 생각보다 여러 곳에 퍼져 있었습니다. `Project.swift`의 프로젝트·타깃 이름과 번들 ID, `Tuist/Package.swift`의 패키지 이름, `Sources/__App.swift`와 `Tests/__Tests.swift`의 파일 이름과 struct 이름까지 모두 바꿔야 했습니다.

특히 테스트 코드의 `@testable import __`도 `@testable import HyperFocus`로 바꿔야 합니다. 타깃 이름이 기본적으로 모듈 이름이 되기 때문입니다. (`productName:`으로 따로 지정하면 달라질 수 있습니다.)

### 2. 생성된 파일과 매니페스트의 역할

| 파일 | 역할 |
| --- | --- |
| `Tuist.swift` | 프로젝트 루트 표시, 생성 옵션 |
| `Project.swift` | Xcode 프로젝트 하나를 선언 (타깃, 번들 ID, 의존성) |
| `Tuist/Package.swift` | 외부 라이브러리(SPM) 선언, `tuist install`로 받음 |
| `mise.toml` | Tuist 버전 고정 |
| `.gitignore` | `*.xcodeproj`, `*.xcworkspace`, `Derived/` 등 생성물 제외 |

`Project.swift`의 `buildableFolders`는 폴더를 통째로 타깃에 연결합니다. `Sources/`에 파일을 추가하면 등록 없이 자동으로 빌드에 포함됩니다. 생성된 `.xcodeproj`를 Xcode에서 직접 수정하면 다음 `tuist generate`에서 사라지니, 설정은 항상 매니페스트에서 바꿉니다.

공식 문서는 매니페스트를 이렇게 설명합니다(번역).

> Tuist는 프로젝트와 워크스페이스를 정의하고 생성 프로세스를 구성하는 기본 방식으로 Swift 파일을 사용합니다.

"생성 프로세스를 구성"은 *configure the generation process*의 직역투라 어색하지만, 파일별로 나눠 보면 의미가 분명해집니다. `Project.swift`는 **무엇을** 만들지, `Workspace.swift`는 어떤 프로젝트를 **묶을지**, `Tuist.swift`는 **어떻게** 만들지(생성 옵션)를 정합니다. 풀어 쓰면 다음과 같습니다.

> Tuist에서는 Swift 파일로 무엇을 만들지(프로젝트, 워크스페이스)와 어떻게 만들지(생성 옵션)를 모두 선언합니다. 이 파일들을 매니페스트 파일이라고 합니다.

### 3. 프로젝트, 타깃, 모듈, 워크스페이스

처음에 "`Project.swift` = 내가 만드는 모듈 구조"라고 이해했는데, 조금 더 정확히 하면 이렇습니다.

- **`Project.swift`는 Xcode 프로젝트 하나이고, 그 안에 모듈(타깃)이 여러 개 들어갑니다.**
- **모듈 간 의존성은 각 타깃의 `dependencies`에서 선언합니다.** `Workspace.swift`가 아닙니다.

| 의존 대상 | 작성 예시 |
| --- | --- |
| 같은 `Project.swift`의 타깃 | `.target(name: "Core")` |
| 다른 `Project.swift`의 타깃 | `.project(target: "Core", path: "../Core")` |
| 외부 라이브러리 | `.external(name: "Alamofire")` |

- **`Workspace.swift`는 어떤 프로젝트를 함께 보여줄지만 정합니다.** 생략하면 Tuist가 의존성을 따라가서 워크스페이스를 자동으로 만듭니다. 이 저장소에 `Workspace.swift`가 없는데도 `HyperFocus.xcworkspace`가 생긴 이유입니다.
- **폴더 구조와 모듈 구조는 자동으로 같아지지 않습니다.** 폴더를 만든다고 모듈이 생기지 않고, 매니페스트에서 타깃과 `buildableFolders`로 연결해야 합니다.

### 4. 트러블슈팅: "실행할 디바이스가 없다"

**증상**: Xcode에서 실행하려는데 고를 수 있는 시뮬레이터가 없었습니다.

**원인**: `Project.swift`에 배포 타깃(최소 iOS 버전)을 지정하지 않으면 생성된 프로젝트에도 `IPHONEOS_DEPLOYMENT_TARGET`이 없습니다. 이때 Xcode는 iOS SDK에 적힌 기본값(`SDKSettings.json`의 `DefaultDeploymentTarget`)을 씁니다. 이 값이 SDK 버전과 같은 `27.2`였는데, 설치된 시뮬레이터 런타임은 iOS 26.5와 27.0뿐이었습니다. 27.2 이상에서만 도는 앱을 실행할 기기가 없었던 것입니다.

**해결**: 두 타깃 모두에 배포 타깃을 명시하고 상수로 뺐습니다.

```swift
// Project.swift
let deploymentTargets: DeploymentTargets = .iOS("18.0")

// 앱 타깃과 테스트 타깃의 .target(...) 안에 각각
deploymentTargets: deploymentTargets,
```

**검증**: 생성된 `project.pbxproj`에서 값이 몇 번 나오는지 세어 봤습니다.

```
$ grep "IPHONEOS_DEPLOYMENT_TARGET" HyperFocus.xcodeproj/project.pbxproj | sort | uniq -c
   4 IPHONEOS_DEPLOYMENT_TARGET = 18.0;
```

4개는 2개 타깃 × Debug/Release입니다. 처음엔 앱 타깃에만 넣어서 2개였고, 이 숫자를 보고 테스트 타깃이 빠진 걸 알아챘습니다. 매니페스트 한 줄이 Xcode 빌드 설정 몇 곳으로 바뀌는지 세어 보는 것이 좋은 검증 방법이었습니다. 이후 iOS 26.5 시뮬레이터에서 빌드와 테스트가 통과했습니다(`** TEST SUCCEEDED **`).

### 5. Debug/Release를 xcconfig로 분리

**목표**: Debug 빌드는 홈 화면에 "HyperFocus개발", Release 빌드는 "HyperFocus"로 보이게 만들기.

시작하기 전에 헷갈리기 쉬운 두 개념을 구분했습니다. **configuration**(Debug/Release)은 *어떻게 빌드할지*(최적화, 디버그 심볼)를 나누고, **환경**(Dev/Prod/Staging)은 *어디에 붙을지*(API 서버, 앱 이름)를 나눕니다. 처음엔 xcconfig 파일 이름을 `Dev`/`Prod`로 지었다가, 지금 단계에서는 configuration과 1:1로 대응하는 `Debug`/`Release`로 바꿨습니다.

#### 1단계: xcconfig 파일 만들기

저장소 루트에 `Configs/` 폴더를 만들고, 두 파일에 같은 키를 다른 값으로 넣었습니다. `APP_DISPLAY_NAME`처럼 직접 지은 키를 사용자 정의 빌드 설정이라고 합니다.

```
// Configs/Debug.xcconfig
APP_DISPLAY_NAME = HyperFocus개발

// Configs/Release.xcconfig
APP_DISPLAY_NAME = HyperFocus
```

`Configs/`라는 위치는 Tuist의 규칙이 아니라 관례입니다. `Tuist.swift`, `Tuist/Package.swift`처럼 Tuist가 이름과 위치로 직접 찾는 파일과 달리, xcconfig는 매니페스트에 경로를 적어 주기 때문에 어디에 둬도 됩니다.

#### 2단계: 매니페스트에서 xcconfig 연결

```swift
// Project.swift — 앱 타깃 .target(...)의 dependencies 바로 뒤
dependencies: [],
settings: .settings(
    configurations: [
        .debug(name: .debug, xcconfig: "./Configs/Debug.xcconfig"),
        .release(name: .release, xcconfig: "./Configs/Release.xcconfig"),
    ]
),
```

처음에는 이 `settings`를 `Project(...)`에 넣었습니다(프로젝트 레벨). 그랬더니 테스트 타깃에도 `APP_DISPLAY_NAME`이 생겼습니다. 테스트 타깃의 Info.plist는 이 값을 읽지 않아서 당장 문제는 없었지만, 앱 표시 이름은 앱만의 관심사라서 위처럼 **앱 타깃 레벨**로 옮겼습니다. 옮긴 뒤에는 앱 타깃에만 값이 남았습니다.

```bash
xcodebuild -showBuildSettings -project HyperFocus.xcodeproj -target HyperFocus -configuration Debug | grep APP_DISPLAY_NAME
#   APP_DISPLAY_NAME = HyperFocus개발
xcodebuild -showBuildSettings -project HyperFocus.xcodeproj -target HyperFocusTests -configuration Debug | grep APP_DISPLAY_NAME
#   (출력 없음)
```

설정을 어느 레벨에 둘지는 **"이 값이 누구에게 필요한가"**로 정합니다. 여러 모듈이 같이 써야 하는 값(API 서버 주소 등)은 프로젝트 레벨, 특정 타깃만 의미 있는 값(앱 표시 이름, 앱 아이콘 등)은 타깃 레벨입니다.

#### 3단계: Info.plist와 연결

빌드 설정은 빌드할 때만 쓰이는 값이라 앱이 직접 읽을 수 없습니다. 그래서 Info.plist가 값을 받아 앱 번들 안에 넣어 줘야 홈 화면에 표시됩니다.

```swift
// Project.swift — 앱 타깃의 infoPlist
infoPlist: .extendingDefault(
    with: [
        "UILaunchScreen": [ ... ],   // 기존 값 유지
        "CFBundleDisplayName": "$(APP_DISPLAY_NAME)",
    ]
),
```

처음에는 이렇게 썼다가 두 가지를 틀렸습니다.

```swift
// ❌ 틀린 예
"CFBundleName": "APP_DISPLAY_NAME"
```

- **`$( )`가 없었습니다.** Xcode는 `$(...)`(또는 `${...}`)로 감싼 것만 빌드 설정 이름으로 알아보고 값으로 바꿉니다. 감싸지 않으면 홈 화면에 "APP_DISPLAY_NAME"이라는 글자 자체가 나옵니다.
- **키가 달랐습니다.** 홈 화면에 보이는 이름은 `CFBundleDisplayName`입니다. `CFBundleName`은 번들의 짧은 이름(15자 이내 권장)으로, 표시 이름이 없을 때 대신 쓰입니다. 게다가 `extendingDefault`는 기본값에 키를 **추가**하지만, 같은 키를 쓰면 **덮어씁니다.** 실수로 Tuist 기본값인 `CFBundleName = $(PRODUCT_NAME)`을 덮어쓰고 있었습니다.

#### 4단계: Tuist가 하는 일과 Xcode가 하는 일

`tuist generate`는 `Derived/InfoPlists/HyperFocus-Info.plist`를 만들고, 생성된 프로젝트는 이 파일을 가리킵니다(`INFOPLIST_FILE`). 이 파일도 생성물이라 직접 고치면 안 됩니다. 관찰해 보니 키를 추가한 앱 plist만 수정 시간이 바뀌었고, 테스트 plist는 처음 생성한 시간 그대로였습니다. 내용이 바뀐 파일만 다시 쓰는 것으로 보이지만, Tuist 문서로 확인한 동작은 아닙니다.

생성된 plist를 열어 보면 값이 `$(...)` 그대로 남아 있습니다.

```xml
<!-- Derived/InfoPlists/HyperFocus-Info.plist -->
<key>CFBundleIdentifier</key>
<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
<key>CFBundleDisplayName</key>
<string>$(APP_DISPLAY_NAME)</string>
```

즉 **Tuist는 `$(...)`가 들어 있는 plist 틀을 만들고, 값을 채워 넣는 건 Xcode가 빌드할 때** 합니다. 이 치환은 빌드 설정 `INFOPLIST_EXPAND_BUILD_SETTINGS = YES`일 때 일어나는데, 앱 타깃에서는 기본으로 켜져 있었습니다. 매니페스트의 `bundleId`도 똑같은 길을 갑니다.

```
bundleId: "com.hyperfocus.timer"  (Project.swift)
   → PRODUCT_BUNDLE_IDENTIFIER    (빌드 설정)
   → $(PRODUCT_BUNDLE_IDENTIFIER) (Info.plist 틀)
   → com.hyperfocus.timer         (빌드된 앱)
```

Debug와 Release를 각각 빌드한 뒤 앱 번들 안의 Info.plist를 읽어서 확인했습니다. 같은 plist 틀 하나로 configuration마다 다른 이름이 들어갔습니다.

```bash
/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' <빌드 폴더>/Debug-iphonesimulator/HyperFocus.app/Info.plist
# HyperFocus개발
/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' <빌드 폴더>/Release-iphonesimulator/HyperFocus.app/Info.plist
# HyperFocus
```

> 참고: Info.plist를 매니페스트가 아니라 파일로 관리하고 싶다면 `infoPlist: .file(path: "Resources/Info.plist")`를 씁니다. 이 경우 Tuist는 파일을 가리키기만 하고 생성하거나 덮어쓰지 않습니다. 기존 앱을 옮길 때 현실적인 선택지입니다.

여기까지 하면서 "설정을 어디에 두면 누가 이기나", "아무것도 안 썼는데 왜 값이 있나"라는 질문이 계속 나왔습니다. 다음 절에서 이 두 질문을 하나의 그림으로 정리합니다.

### 6. 빌드 설정은 5장의 투명 시트다

#### 핵심 그림

빌드 설정은 **5장의 투명 시트를 겹쳐 놓은 것**입니다. Xcode는 설정 값을 찾을 때 맨 위 시트부터 내려다보고, **가장 먼저 보이는 값**을 씁니다.

```
 ┌─────────────────────────────┐
 │ ① 타깃 설정                  │  ← 가장 먼저 보임 (가장 강함)
 ├─────────────────────────────┤
 │ ② 타깃 xcconfig              │
 ├─────────────────────────────┤
 │ ③ 프로젝트 설정               │
 ├─────────────────────────────┤
 │ ④ 프로젝트 xcconfig           │
 ├─────────────────────────────┤
 │ ⑤ 플랫폼 기본값 (iOS Default)  │  ← 위에 아무것도 없을 때만 보임
 └─────────────────────────────┘
```

매니페스트의 `settings`를 `Project(...)`에 넣으면 ③·④에, `.target(...)`에 넣으면 ①·②에 들어갑니다. 이 구조는 Tuist가 만든 게 아니라 Xcode 빌드 설정 구조를 그대로 옮긴 것입니다. Xcode Build Settings 화면에서 **Levels** 보기를 켜면 시트들이 열로 나란히 보이고, ⑤는 "iOS Default" 열로 나옵니다.

시트는 configuration마다 한 벌씩 있습니다. Debug 묶음의 ②에는 `Debug.xcconfig`를, Release 묶음의 ②에는 `Release.xcconfig`를 끼워 넣었기 때문에 이름이 달라졌습니다. 테스트 타깃은 자기만의 ①·②를 갖고, ③·④는 앱과 같이 씁니다. 그래서 `APP_DISPLAY_NAME`을 프로젝트 레벨(④)에 두었을 때는 테스트 타깃에도 보였습니다.

#### 각 시트에 누가 무엇을 써 넣었나

| 시트 | 매니페스트에서 내가 쓴 것 | 내가 안 써도 채워진 것 |
| --- | --- | --- |
| ① 타깃 설정 | `bundleId`, `deploymentTargets` | Tuist 권장 설정(타깃용) + 매니페스트에서 파생된 값 |
| ② 타깃 xcconfig | `Configs/Debug.xcconfig` 등 | 없음 |
| ③ 프로젝트 설정 | 없음 | Tuist 권장 설정(프로젝트용) |
| ④ 프로젝트 xcconfig | 없음 | 없음 |
| ⑤ 플랫폼 기본값 | 쓸 수 없음 | Xcode와 SDK가 갖고 있음 (프로젝트 파일에 안 적힘) |

"생략한 값은 기본값이 된다"에서 그 기본값은 한 군데가 아니라 층마다 따로 있습니다. ①·③은 Tuist가 프로젝트 파일에 **실제로 써 넣고**, ⑤는 Xcode와 SDK가 **안에 갖고 있습니다.**

Tuist 권장 설정은 `settings`의 `defaultSettings`가 정합니다. 프로젝트와 타깃에 각각 있고 둘 다 기본값이 `.recommended`입니다. 생성된 `project.pbxproj`를 보면 매니페스트의 프로젝트 레벨에 아무것도 쓰지 않았는데도 약 50개의 설정이 적혀 있었습니다(`ALWAYS_SEARCH_USER_PATHS`, `CLANG_ENABLE_MODULES` 등). 타깃 레벨에도 `SWIFT_VERSION = 5`, `TARGETED_DEVICE_FAMILY = "1,2"` 같은 값이 들어가 있었습니다. Xcode 27로 빌드해도 **Swift 6가 아니라 Swift 5 언어 모드**라는 점은 놀라웠습니다.

configuration 목록도 같은 원리입니다. 프로젝트 레벨 `settings`를 지웠는데도 Debug/Release가 남은 건 Tuist가 기본으로 두 개를 만들기 때문입니다.

#### 이번 주에 겪은 일을 그림으로 따라가기

| 설정 | Xcode가 위에서 내려다보면 | 결과 |
| --- | --- | --- |
| `APP_DISPLAY_NAME` | ①에 없음 → **②에서 발견** | HyperFocus개발 |
| `PRODUCT_BUNDLE_IDENTIFIER` | **①에서 발견** (`bundleId`) | xcconfig(②)에 넣어도 ①에 가려서 안 보임 |
| `SWIFT_VERSION` | **①에서 발견** (Tuist 권장값) | 안 썼는데 5 |
| `IPHONEOS_DEPLOYMENT_TARGET` (고치기 전) | ①~④ 모두 없음 → **⑤까지 내려감** | 27.2 |
| `IPHONEOS_DEPLOYMENT_TARGET` (고친 뒤) | **①에서 발견** | 18.0 |

두 번째 줄은 Tuist 사용자가 실제로 자주 걸리는 함정입니다. **`bundleId`처럼 매니페스트 파라미터로 넣은 값은 ①에 들어가기 때문에 xcconfig로는 덮을 수 없습니다.** Debug용 번들 ID를 xcconfig로 따로 주고 싶다면 매니페스트 쪽을 바꿔야 합니다.

#### 주의: 가리기만 하는 게 아니라 합쳐지기도 한다

값에 `$(inherited)`를 쓰면 위 시트가 아래 시트 값을 가리지 않고 **이어 붙입니다.** 예를 들어 `OTHER_LDFLAGS = $(inherited) -ObjC`는 아래 시트의 값 뒤에 `-ObjC`를 붙입니다. 실제로 생성된 프로젝트에서도 `LD_RUNPATH_SEARCH_PATHS`, `OTHER_LDFLAGS` 등이 이 방식으로 적혀 있었습니다. 또 시트 맨 위에는 `xcodebuild KEY=VALUE`처럼 명령줄로 넘긴 값이 올라갈 수 있는데, CI에서 설정이 예상과 다를 때 확인할 지점입니다.

> 참고: `defaultSettings`는 `.recommended`, `.essential`, `.none` 중에서 고르고, `.recommended(excluding: [...])`로 특정 키만 뺄 수도 있습니다. `.none`으로 바꿔도 ⑤(플랫폼 기본값)는 그대로 남기 때문에, 기존 앱을 옮길 때 설정을 원본과 같게 맞추려면 원본의 값을 xcconfig로 옮겨야 합니다.

### 7. entitlements: App Group을 환경별로 나누기

#### entitlements와 App Group

**entitlements**는 "이 앱이 이런 시스템 기능을 쓸 자격이 있다"는 선언입니다. 코드 서명할 때 앱에 함께 새겨지고, iOS는 이걸 보고 기능을 허락합니다. 앱에 대한 정보(이름, 버전)를 담는 Info.plist와 달리, entitlements는 애플이 허락해야 하는 자격입니다. 실기기에서는 개발자 계정의 프로비저닝 프로파일에도 같은 자격이 등록돼 있어야 합니다.

자격이 필요할 것 같지만 필요 없는 경우도 있습니다. 타이머 종료를 알리는 **로컬 알림**은 entitlement 없이 사용자 허락만 받으면 되고, 원격 푸시(`aps-environment`)나 Time Sensitive 알림에는 entitlement가 필요합니다.

이번에 다룬 건 **App Group**입니다. iOS에서 앱과 위젯은 각자 격리된 공간(샌드박스)에서 별도 프로세스로 실행되기 때문에, 위젯은 앱의 `UserDefaults`나 파일을 직접 읽을 수 없습니다. App Group은 같은 팀의 앱과 확장이 함께 쓰는 공유 공간입니다. 그룹을 쓰는 **모든 타깃**의 entitlements에 같은 그룹 ID를 선언해야 합니다.

참고로 위젯은 앱 확장(App Extension)이라 별도의 번들 ID가 필요하고, 그 ID는 앱 번들 ID로 시작해야 합니다(예: `com.hyperfocus.timer.widget`). 선택이 아니라 애플의 규칙입니다.

#### 원본 앱은 어떻게 쓰고 있었나

리팩터링 전 원본 HyperFocus 앱을 조사해 보니, 앱이 집중 세션 상태·종료 시각·제목을 `UserDefaults(suiteName: appGroupID)`에 쓰고 위젯이 같은 곳에서 읽고 있었습니다. 그룹은 환경별로 두 개였습니다.

| configuration | 앱 번들 ID | App Group |
| --- | --- | --- |
| Development | `com.hyperfocus.timer.dev` | `group.com.hyperfocus.timer.dev` |
| Production | `com.hyperfocus.timer` | `group.com.hyperfocus.timer` |

눈에 띈 점이 두 가지 있었습니다.

- **같은 그룹 ID를 두 가지 방법으로 계산했습니다.** 앱은 컴파일 플래그(`#if DEVELOPMENT`)로 고르고, 위젯은 자기 번들 ID에서 `.widget`을 떼고 `group.`을 붙여 계산했습니다. 지금은 결과가 같지만, 한쪽 규칙만 바뀌면 앱과 위젯이 서로 다른 저장소를 보게 됩니다. 에러 없이 위젯에 데이터만 안 보이니 원인을 찾기 어렵습니다.
- **entitlements 파일 하나에 두 그룹을 모두 선언했습니다.** 그래서 운영 빌드에도 개발용 그룹이 들어갑니다.

#### 개선: 그룹 ID를 xcconfig 값 하나로

지금까지 익힌 패턴을 그대로 썼습니다. 그룹 ID를 xcconfig에 두고, entitlements가 `$(...)`로 참조합니다.

```
// Configs/Debug.xcconfig
APP_DISPLAY_NAME = HyperFocus개발
APP_GROUP_ID = group.com.hyperfocus.timer.dev

// Configs/Release.xcconfig
APP_DISPLAY_NAME = HyperFocus
APP_GROUP_ID = group.com.hyperfocus.timer
```

```swift
// Project.swift — 앱 타깃 .target(...)의 buildableFolders 뒤
entitlements: .dictionary([
    "com.apple.security.application-groups": ["$(APP_GROUP_ID)"],
]),
```

`entitlements:`는 `.dictionary`, `.file(path:)`, `.variable(...)` 세 형태가 있습니다. `.dictionary`는 Info.plist의 `.extendingDefault`처럼 Tuist가 파일을 생성합니다. 생성 결과는 Info.plist와 같은 구조였습니다.

- Tuist가 `Derived/Entitlements/HyperFocus.entitlements`에 `$(APP_GROUP_ID)`가 그대로 들어 있는 틀을 만듭니다.
- `CODE_SIGN_ENTITLEMENTS` 빌드 설정이 이 파일을 가리킵니다(Info.plist의 `INFOPLIST_FILE`과 같은 역할).
- 값은 Xcode가 빌드할 때 채웁니다.

| configuration | 빌드된 앱의 App Group |
| --- | --- |
| Debug | `group.com.hyperfocus.timer.dev` |
| Release | `group.com.hyperfocus.timer` |

이제 각 빌드에는 자기 환경의 그룹 하나만 들어갑니다. 나중에 위젯 타깃을 추가할 때 위젯도 같은 `$(APP_GROUP_ID)`를 읽게 하면, 원본에서 본 "두 가지 계산 방식" 문제가 구조적으로 사라집니다.

#### 걸려 넘어진 곳

```swift
// ❌ 틀린 예 1: 위치
entitlements: .dictionary([...]),
buildableFolders: [...],
```

`entitlements:`는 `buildableFolders:` **뒤**에 와야 합니다. 매니페스트가 컴파일되지 않고 `argument 'buildableFolders' must precede argument 'entitlements'` 에러가 납니다.

```swift
// ❌ 틀린 예 2: 문자열
"com.apple.security.application-groups": "$(APP_GROUP_ID)",
```

앱 하나가 여러 그룹에 속할 수 있어서 이 키의 값은 **항상 배열**입니다. 문자열로 써도 매니페스트는 컴파일되기 때문에 컴파일러가 잡아 주지 않습니다.

**❌ 틀린 예 3: xcconfig 마지막 줄의 줄바꿈.** 실험 중에 `Debug.xcconfig` 끝에 줄바꿈이 없는 상태로 새 줄을 덧붙였더니 두 줄이 하나로 합쳐졌습니다.

```
APP_DISPLAY_NAME = HyperFocus개발APP_GROUP_ID = group.com.hyperfocus.timer.dev
```

그 결과 `APP_GROUP_ID`가 정의되지 않았고, Debug 빌드의 App Group이 **빈 문자열**이 됐습니다. **에러도 경고도 없었습니다.** 정의되지 않은 빌드 설정은 조용히 빈 값이 됩니다. 에디터의 "파일 끝에 줄바꿈 자동 추가" 옵션을 켜 두는 게 좋습니다.

#### 확인 방법

시뮬레이터 빌드에서는 `codesign -d --entitlements`로 확인하면 빈 결과가 나옵니다. 실제 적용된 값은 빌드 폴더의 `HyperFocus.app-Simulated.xcent` 파일에 있습니다.

```bash
plutil -p ~/Library/Developer/Xcode/DerivedData/HyperFocus-<임의 문자열>/Build/Intermediates.noindex/HyperFocus.build/Debug-iphonesimulator/HyperFocus.build/HyperFocus.app-Simulated.xcent
```

`<임의 문자열>`은 Xcode가 프로젝트마다 붙이는 값이라 사람마다 다릅니다. Xcode의 Product → Show Build Folder in Finder로 찾을 수 있습니다.

#### 같은 패턴을 세 번 썼다

| 빌드 설정 | 받는 곳 | Tuist가 만든 틀 |
| --- | --- | --- |
| `PRODUCT_BUNDLE_IDENTIFIER` | Info.plist `CFBundleIdentifier` | `Derived/InfoPlists/` |
| `APP_DISPLAY_NAME` | Info.plist `CFBundleDisplayName` | `Derived/InfoPlists/` |
| `APP_GROUP_ID` | entitlements `application-groups` | `Derived/Entitlements/` |

### 8. UI 테스트 타깃 추가

기존 유닛 테스트 타깃(`HyperFocusTests`)에 이어 UI 테스트 타깃을 추가했습니다. 두 테스트는 동작 방식이 다릅니다. 유닛 테스트는 앱 **안에서** 코드를 직접 호출하고(`@testable import`), UI 테스트는 **별도 프로세스에서** 앱을 실행해 사용자처럼 화면을 조작합니다. 그래서 UI 테스트에는 `@testable import`가 없고, 보통 XCTest의 `XCUIApplication`으로 작성합니다.

```swift
// UITests/HyperFocusUITests.swift
import XCTest

final class HyperFocusUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_앱을_실행하면_인사말이_보인다() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["Hello, World!"].waitForExistence(timeout: 5))
    }
}
```

앱이 뜨는 데 시간이 걸리기 때문에 `exists` 대신 `waitForExistence(timeout:)`로 기다립니다.

```swift
// Project.swift — targets 배열의 세 번째 타깃
.target(
    name: "HyperFocusUITests",
    destinations: .iOS,
    product: .uiTests,
    bundleId: "com.hyperfocus.timer.uitests",
    deploymentTargets: deploymentTargets,
    infoPlist: .default,
    buildableFolders: [
        "./UITests"
    ],
    dependencies: [.target(name: "HyperFocus")]
),
```

배포 타깃은 4절에서 상수로 빼 둔 `deploymentTargets`를 그대로 썼습니다. 상수로 뺀 덕분에 한 줄로 끝났습니다.

**UI 테스트는 앱 코드를 import하지 않는데 왜 앱 타깃에 의존할까?** 테스트할 앱이 먼저 빌드돼 있어야 하기 때문입니다. 여기서 의존성은 "코드를 가져다 쓴다"가 아니라 "이 타깃보다 먼저 빌드하고, 테스트 대상 앱으로 연결한다"는 뜻입니다.

**스킴은 직접 만들지 않았는데 테스트가 포함될까?** 포함됐습니다. 생성된 `HyperFocus` 스킴의 Test 항목에 `HyperFocusTests`와 `HyperFocusUITests`가 둘 다 들어 있었습니다. 스킴을 생략하면 Tuist가 앱 타깃의 스킴을 만들고, 앱에 의존하는 테스트 타깃을 넣어 주는 것으로 보입니다(결과를 보고 추론한 것이고 문서로 확인하지는 않았습니다).

iOS 26.5 시뮬레이터에서 두 테스트가 모두 통과했습니다. 유닛 테스트는 0.001초, UI 테스트는 4.4초가 걸렸습니다. 앱을 실제로 띄우는 비용이 숫자로 보입니다.

---

## 곁가지 실험

본 흐름과는 조금 떨어져 있지만, 1주차 동안 확인한 두 가지입니다.

### mise로 버전 고정하기: 실제로 무엇이 실행되나

"팀원이 Homebrew로 다른 버전을 설치했다면 이 폴더에서 `tuist version`은 무엇을 출력할까?"라는 질문으로 정리했습니다.

```
$ which -a tuist
~/.local/share/mise/installs/tuist/4.216.2/tuist
~/.local/share/mise/shims/tuist
```

- 첫 줄: 셸에 `mise activate`가 설정되어 있어서, 이 폴더에 들어오면 `mise.toml`의 고정 버전 경로가 `PATH` 맨 앞에 들어갑니다. 이게 실행됩니다.
- 둘째 줄: **shim**. 실행되면 현재 폴더부터 상위 폴더, 전역 설정까지 따라 올라가며 버전을 찾아 넘겨주는 대리 실행 파일입니다. 셸 활성화가 없는 환경(IDE, Xcode Run Script 등)을 위한 경로입니다.

그래서 결과는 셸 설정에 달려 있습니다. mise 없이 Homebrew만 쓰면 `mise.toml`은 무시되고 Homebrew 버전이 실행됩니다. 활성화하지 않았더라도 shim 폴더가 `PATH`에서 Homebrew보다 앞에 있으면 고정 버전이 실행됩니다. 실험 중에 `mise.toml`이 없는 폴더에서 shim을 실행했더니 `No version is set for shim: tuist` 에러가 났습니다.

`mise.toml`은 버전을 정하는 약속이고, 그 약속을 실제로 지키게 하는 건 셸 설정입니다. 처음 받은 저장소라면 `mise install`로 버전을 설치해야 하고(경우에 따라 `mise trust`도 필요합니다), 셸 설정을 믿기 어려운 CI에서는 `mise exec -- tuist generate`처럼 mise를 거쳐 실행합니다.

### Tuist는 프로젝트 루트를 어떻게 찾나

"`Tuist.swift`에는 기본 설정만 있는데 지우면 어떻게 될까?"를 임시 폴더에 복사해서 실험했습니다.

| 남겨 둔 것 | `tuist generate` |
| --- | --- |
| `Tuist/` 폴더 (`Tuist.swift` 삭제) | 성공 |
| `Tuist.swift`만 (`Tuist/` 폴더 없음) | 성공 |
| 둘 다 없음 (`.git`도 없음) | 실패 |

실패했을 때의 에러 메시지입니다.

```
Couldn't locate the root directory from path ...
The root directory is the closest directory that contains a Tuist or a .git directory.
```

에러 메시지에는 `Tuist/`와 `.git`만 나오지만, 실험해 보니 `Tuist.swift`만 있어도 루트로 인식했습니다. 즉 Tuist는 **`Tuist.swift`, `Tuist/` 폴더, `.git` 중 하나**가 있는 가장 가까운 폴더를 루트로 삼습니다. 그래도 `Tuist.swift`를 두는 이유는 루트를 명시적으로 표시하고, 2주차의 `enforceExplicitDependencies` 같은 **생성 옵션**을 넣는 곳이기 때문입니다.

---

## TIL (Today I Learned)

- **생략한 값은 기본값이 됩니다.** 그 기본값은 Tuist가 프로젝트 파일에 써 넣은 것과 Xcode·SDK가 갖고 있는 것으로 나뉩니다.
- **빌드 설정은 5장의 투명 시트입니다.** 위에서부터 처음 보이는 값이 이기고, 설정을 둘 곳은 "이 값이 누구에게 필요한가"로 정합니다.
- **Tuist는 틀을 만들고, Xcode가 값을 채웁니다.** Info.plist와 entitlements의 `$(...)`는 빌드할 때 치환되고, 정의되지 않은 값은 에러 없이 빈 문자열이 됩니다.
- **매니페스트 한 줄이 Xcode에서 어디로 가는지 세어 보면 실수가 보입니다.** `IPHONEOS_DEPLOYMENT_TARGET`이 2개냐 4개냐로 빠진 타깃을 찾았습니다.
- **추측보다 실험이 정확합니다.** 루트 탐색 규칙은 에러 메시지만 봐서는 알 수 없었습니다.

---

## 다음 할 일

- [x] 시뮬레이터 홈 화면에서 "HyperFocus개발" 확인
- [x] entitlements 다루기: App Group을 xcconfig 값으로 환경별 분리
- [x] UI 테스트 타깃 추가
- [ ] 두 xcconfig 파일 끝에 줄바꿈 추가
- [x] 최소 iOS 18.0을 고른 이유를 README에 기록: 최신 버전이 아닌 기기 사용자까지 지원하면서 SwiftData를 쓰기 위해
- [ ] 2주차: 모듈 분리와 `enforceExplicitDependencies`

---

## 부록: 1주차 최종 코드와 실행 순서

### 실행 순서

```bash
mise install          # mise.toml에 고정된 Tuist 설치 (셸에 mise activate 필요)
tuist version         # 4.216.2 확인
tuist edit            # 매니페스트를 Xcode에서 편집. 편집용 프로젝트를 열고 바로 종료됨
tuist generate        # 편집·저장 후 실제 프로젝트 생성
```

`tuist edit`은 편집용 프로젝트(`Manifests.xcworkspace`)를 열고 명령 자체는 바로 끝납니다. 편집하고 `⌘S`로 저장하면 실제 `Project.swift`가 바뀌니, 그대로 `tuist generate`를 실행하면 됩니다. 편집용 프로젝트에서 `⌘B`를 누르면 매니페스트가 컴파일되는지 미리 확인할 수 있습니다.

### `Project.swift`

```swift
import ProjectDescription

let deploymentTargets: DeploymentTargets = .iOS("18.0")

let project = Project(
    name: "HyperFocus",
    targets: [
        .target(
            name: "HyperFocus",
            destinations: .iOS,
            product: .app,
            bundleId: "com.hyperfocus.timer",
            deploymentTargets: deploymentTargets,
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": [
                        "UIColorName": "",
                        "UIImageName": "",
                    ],
                    "CFBundleDisplayName": "$(APP_DISPLAY_NAME)",
                ]
            ),
            buildableFolders: [
                "./Sources",
                "./Resources",
            ],
            entitlements: .dictionary([
                "com.apple.security.application-groups": ["$(APP_GROUP_ID)"],
            ]),
            dependencies: [],
            settings: .settings(
                configurations: [
                    .debug(name: .debug, xcconfig: "./Configs/Debug.xcconfig"),
                    .release(name: .release, xcconfig: "./Configs/Release.xcconfig"),
                ]
            ),
        ),
        .target(
            name: "HyperFocusTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.hyperfocus.timer.tests",
            deploymentTargets: deploymentTargets,
            infoPlist: .default,
            buildableFolders: [
                "./Tests"
            ],
            dependencies: [.target(name: "HyperFocus")]
        ),
        .target(
            name: "HyperFocusUITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "com.hyperfocus.timer.uitests",
            deploymentTargets: deploymentTargets,
            infoPlist: .default,
            buildableFolders: [
                "./UITests"
            ],
            dependencies: [.target(name: "HyperFocus")]
        ),
    ]
)
```

### `Configs/`

```
// Configs/Debug.xcconfig
APP_DISPLAY_NAME = HyperFocus개발
APP_GROUP_ID = group.com.hyperfocus.timer.dev

// Configs/Release.xcconfig
APP_DISPLAY_NAME = HyperFocus
APP_GROUP_ID = group.com.hyperfocus.timer
```

### `UITests/HyperFocusUITests.swift`

8절의 코드와 같습니다.

### 커밋할 파일과 커밋하지 않는 파일

| 커밋함 | 커밋하지 않음 (생성물) |
| --- | --- |
| `Project.swift`, `Tuist.swift`, `Tuist/Package.swift`, `Configs/`, `Sources/`, `Resources/`, `Tests/`, `UITests/`, `mise.toml` | `*.xcodeproj`, `*.xcworkspace`, `Derived/`, `graph.png` |

팀원은 커밋된 파일만 받아서 `mise install` → `tuist generate`로 같은 프로젝트를 만들 수 있습니다.

## 참고 자료

- [Tuist 공식 문서: Manifests](https://tuist.dev/en/docs/guides/features/projects/manifests)
- [Tuist 공식 문서: Directory structure](https://tuist.dev/en/docs/guides/features/projects/directory-structure)
- [Tuist 공식 문서: Dependencies](https://tuist.dev/en/docs/guides/features/projects/dependencies)
- [ProjectDescription API 레퍼런스](https://projectdescription.tuist.dev/documentation/projectdescription)
