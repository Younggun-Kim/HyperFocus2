# App

앱 진입점과 조립. 공통 규칙은 루트 `CLAUDE.md`를 따른다.

## 조립

- `HyperFocusApp.init`에서 Store를 만들기 **전에** `DataModule.bootstrap()`을 호출한다. 위치를 옮기지 않는다.
- Feature는 `RootFeature`에서 조립하고, 화면 이동은 자식의 delegate 액션으로 처리한다.
- 세션 만료는 `RootFeature`가 `ObserveSessionExpiredUseCase`의 `AsyncStream`을 `.task`에서 구독해서 로그아웃과 같은 흐름(계정 비우기 → 타이머 탭 → 익명 로그인)으로 보낸다. 개별 Feature에서 처리하지 않는다.

## 설정과 비밀값

- 환경별 값은 `Configs/{Debug,Release}.xcconfig` → 빌드 설정 → Info.plist 순서로 흘려보낸다(예: `APP_DISPLAY_NAME`, `APP_GROUP_ID`, `API_BASE_URL`). 코드에 `#if DEBUG`로 하드코딩하지 않는다.
- xcconfig에 키를 추가하면 파일 끝 줄바꿈을 확인한다. 없으면 값이 에러 없이 빈 문자열이 된다.
- 비밀값은 커밋하지 않는다. (미적용) `Configs/Secrets.xcconfig`를 gitignore하고 각 xcconfig에서 `#include? "Secrets.xcconfig"`로 선택적으로 포함한다. CI는 GitHub Secrets로 이 파일을 만든다.
- 버전(`MARKETING_VERSION`)과 빌드 번호(`CURRENT_PROJECT_VERSION`)는 매니페스트나 xcconfig에서 관리한다. Xcode UI에서 바꾸지 않는다(생성물이라 사라진다).

## 테스트

- `Tests`(Swift Testing): App 수준 조립 검증. `HyperFocusTests`는 모든 Feature에 의존해서 선택적 테스트에서도 매번 다시 실행된다.
- `UITests`(XCTest): 핵심 사용자 흐름만(앱 실행, 타이머 시작·종료).
