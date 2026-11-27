# Features

화면 단위 TMA 모듈(Sources, Example, Tests). 공통 규칙은 루트 `CLAUDE.md`를 따른다.

## 경계

- `@Dependency`로는 **UseCase만** 쓴다. Repository를 직접 쓰지 않는다. 같은 Domain 모듈에 있어 그래프로는 막히지 않으니 직접 지킨다.
- Feature끼리 의존하지 않는다. 화면 이동은 부모 Reducer가 자식의 delegate 액션을 받아 처리한다.
- 여러 Feature가 함께 쓰는 화면 계층 코드는 `BaseFeature`에 둔다. 화면이 없는 모듈이라 `Target.module`로 만들고(Example 없음), Domain과 TCA에만 의존한다. 특정 화면의 문구나 액션은 넣지 않는다.
- `Data`, `CoreNetwork`, `SwiftData`, `Alamofire`를 import하지 않는다.
- Reducer에는 화면 상태, 흐름, 화면 이동만 둔다. 비즈니스 규칙은 UseCase로 보낸다.

## 에러 처리

- Domain 에러를 화면 상태(alert, 재시도, 빈 화면)로 바꾼다. **사용자 문구는 여기서 만든다.**
- effect는 UseCase가 돌려준 `Result`를 `switch`로 풀어 성공/실패 액션을 보낸다.
- 실패 알림은 `BaseFeature`의 `AlertState.failure(title:error:)`로 만든다. 제목과 숨길 에러는 각 Feature가 정한다.
- `DomainError.cancelled`는 알리지 않는다(문구를 만드는 함수가 `nil`을 돌려준다). effect가 취소돼서 생긴 결과는 `send`가 버리므로 Reducer에 오지 않는다.
- `unauthorized`를 받아도 화면을 이동하지 않는다. 세션 만료는 App의 `RootFeature`가 처리한다.

## 새 Feature 만들기

1. 저장소 루트에서 `--path` 없이 `tuist scaffold Feature --name <이름>`을 실행한다.
2. `Project.swift`의 Features 구간에 `Target.feature(name:dependencies:)`를 **직접** 추가한다. 의존성을 리뷰하려고 일부러 수작업으로 둔다.
3. 앱에 붙이려면 `HyperFocus` 타깃의 `dependencies`에 추가하고 `RootFeature`에서 조립한다.

## Example 앱과 테스트

- Data를 링크하지 않는다. `prepareDependencies`(Example)와 `TestStore`의 `withDependencies`(Tests)로 mock을 명시적으로 주입한다.
- Repository 포트에 mock을 넣으면 UseCase는 실제 로직대로 동작한다.
- Reducer 테스트: `TestStore`로 액션, 상태, delegate 흐름을 검증한다(Swift Testing).
