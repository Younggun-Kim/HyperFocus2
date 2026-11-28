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
- 통신은 CoreNetwork의 API만 쓴다. Alamofire를 import하지 않는다. API 하나는 `APIEndpoint`를 채택한 struct 하나로 기술하고, `Response`로 응답 타입을 묶는다. 기능별 enum(`SettingAPI` 등)은 이름 공간으로만 쓴다.
- 응답 봉투(`APIResponse`)는 CoreNetwork가 연다. `service.request(_:)`는 던지지 않고 `Result<DTO, APIError>`를 돌려준다. Repository는 그 DTO만 다룬다. 본문을 쓰지 않는 API의 `Response`는 `EmptyResponse`다.
- `APIService`는 `Sources/Network/DataNetwork.swift`에서 하나만 만든다(baseURL은 Info.plist의 `API_BASE_URL`, 토큰은 키체인).
- Repository `liveValue`는 `live(service:)` 팩토리로 만들어, 테스트가 가짜 `APIServiceProtocol`을 넣을 수 있게 한다. 기기 저장소를 쓰는 Repository는 저장소도 인자로 받는다(테스트는 따로 만든 `UserDefaults` suite를 넣는다).

## 로컬 우선 동기화

- 기기에 남긴 값이 기준이다. 바꾼 값은 기기에 쓰고 구독자에게 보낸 뒤 서버에 보낸다. 서버에 닿지 못해도 변경의 실패가 아니다. "보낼 변경 있음"으로 표시해 두고 다음 동기화에서 보낸다.
- 동기화는 보낼 변경이 있으면 먼저 보내고(PATCH), 없으면 서버 값을 받는다(GET). 다른 계정의 값이 남아 있으면 버린다.
- 서버 요청은 한 번에 하나씩 보낸다. 요청을 기다리는 동안 기기 값이 바뀌었으면 받은 서버 값을 버리고 다시 맞춘다.
- 구독은 `CurrentValueBroadcaster`(지금 값을 먼저 보내는 브로드캐스터)로 만든다. 예시: `Repository/Setting/SettingSynchronizer.swift`.
- 작은 값은 `DataSource/Local`의 UserDefaults 저장소에 둔다. 저장 형식을 바꾸면 키의 버전(`.v1`)을 올리고, 읽지 못하는 값은 없는 것으로 본다.

## 에러

- `APIError`와 SwiftData 에러를 **Domain 에러로 변환**해서 `Result`의 실패로 돌려준다. 아래 계층의 에러 타입을 그대로 올려 보내지 않는다.
- 변환하기 **전에** 원본을 `os.Logger`로 로깅한다(category `Data`). 통신 결과에 `domainResult(_:)`를 부르면 둘 다 처리된다. 취소는 로깅하지 않고 `DomainError.cancelled`로 올린다. 토큰과 사용자 데이터에 `privacy: .public`을 붙이지 않는다.

## SwiftData

- 스키마는 **`VersionedSchema` + `SchemaMigrationPlan`으로만 변경한다.** `@Model`의 저장 속성을 바꾸는 PR에는 마이그레이션 단계와 그 테스트가 함께 있어야 한다.
- 저장소는 App Group 컨테이너(`$(APP_GROUP_ID)`)에 만든다. 앱 확장이 생기면 같은 스키마를 공유하게 하기 위해서다.
- (미적용) 아직 SwiftData를 쓰는 코드가 없다.

## 테스트

- Repository `liveValue`: DTO/`@Model` → Entity 변환과 에러 변환을 검증한다.
- 로컬 우선 Repository: 오프라인 변경이 남았다가 다음 동기화에서 보내지는지, 계정이 바뀌면 이전 값이 버려지는지, 다시 열어도 값이 남는지 검증한다.
