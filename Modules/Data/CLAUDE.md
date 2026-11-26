# Data

Domain의 Repository 포트를 구현하는 모듈. App만 링크한다. 공통 규칙은 루트 `CLAUDE.md`를 따른다.

## bootstrap 등록

- Repository를 추가하면 `Sources/DataModule.swift`의 `bootstrap()`에 **반드시 등록**한다.
- 빠뜨려도 컴파일은 통과하고 런타임에 실패한다. swift-dependencies는 `liveValue`를 런타임 조회로 찾는데, 정적 링크에서는 코드가 참조하지 않는 `liveValue`가 바이너리에서 빠지기 때문이다.
- (미적용) 누락을 잡는 테스트: App 테스트에서 `bootstrap()` 후 모든 Repository가 test/preview 값이 아닌 live 값으로 해석되는지 확인한다.

## 구조

- 구현은 `Sources/Repository/XxxRepository+Live.swift`의 `liveValue`에 둔다. 저장 방식과 묶인 처리(조회, 변환, 캐시)는 여기서 한다.
- DataSource는 구체 타입으로 두고 swift-dependencies로 주입하지 않는다.
- 저장 방식 타입은 `internal`로 둔다. API별 `APIEndpoint`와 DTO는 `DataSource/Remote`, SwiftData `@Model`은 `DataSource` 아래에 둔다. `liveValue`에서 Entity로 변환해 반환하고, 이 타입들을 `public`으로 열지 않는다.
- 통신은 CoreNetwork의 API만 쓴다. Moya·Alamofire를 import하지 않는다. API 하나는 `APIEndpoint`를 채택한 struct 하나로 기술하고, `Response`로 응답 타입을 묶는다. 기능별 enum(`SettingAPI` 등)은 이름 공간으로만 쓴다.
- 응답 봉투(`APIResponse`)는 CoreNetwork가 연다. Repository는 `service.request(_:)`가 돌려준 DTO만 다룬다. 본문을 쓰지 않는 API의 `Response`는 `EmptyResponse`다.
- `APIService`는 `Sources/Network/DataNetwork.swift`에서 하나만 만든다(baseURL은 Info.plist의 `API_BASE_URL`, 토큰은 키체인).
- Repository `liveValue`는 `live(service:)` 팩토리로 만들어, 테스트가 가짜 `APIServiceProtocol`을 넣을 수 있게 한다.

## 에러

- `APIError`와 SwiftData 에러를 **Domain 에러로 변환**해서 던진다. 아래 계층의 에러 타입을 그대로 올려 보내지 않는다.
- 변환하기 **전에** 원본을 `os.Logger`로 로깅한다(category `Data`). `convertingErrors`로 감싸면 둘 다 처리된다. 취소는 `CancellationError`로 올린다. 토큰과 사용자 데이터에 `privacy: .public`을 붙이지 않는다.

## SwiftData

- 스키마는 **`VersionedSchema` + `SchemaMigrationPlan`으로만 변경한다.** `@Model`의 저장 속성을 바꾸는 PR에는 마이그레이션 단계와 그 테스트가 함께 있어야 한다.
- 저장소는 App Group 컨테이너(`$(APP_GROUP_ID)`)에 만든다. 앱 확장이 생기면 같은 스키마를 공유하게 하기 위해서다.
- (미적용) 아직 SwiftData를 쓰는 코드가 없다.

## 테스트

- Repository `liveValue`: DTO/`@Model` → Entity 변환과 에러 변환을 검증한다.
