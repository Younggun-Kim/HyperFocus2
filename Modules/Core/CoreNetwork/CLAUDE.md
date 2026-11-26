# CoreNetwork

통신 공통 코드(`APIService`, 인터셉터, 토큰 갱신)를 두는 모듈. 공통 규칙은 루트 `CLAUDE.md`를 따른다.

## 경계

- **Moya와 Alamofire를 import할 수 있는 곳은 이 모듈뿐이다.** 라이브러리를 교체할 때 이 모듈만 바뀌게 하기 위해서다. 바깥에는 Moya·Alamofire 타입이 드러나지 않는 API만 공개한다.
- async/await 지원은 이 모듈이 감싸서 제공한다.
- 바깥에 공개하는 요청 단위는 `APIEndpoint`(경로, `HTTPMethod`, 본문, 인증 여부, 응답 타입 `Response`)다. Moya `TargetType`(`BaseTarget`)은 internal로 두고 `APIService`가 바꾼다.
- 응답 봉투(`APIResponse`)는 이 모듈이 연다(`APIResponse.open`). 2xx인데 봉투가 약속과 다르면(`data` 없음, `success == false`) `APIError.decodingError`다. `EmptyResponse`로 받으면 `data`나 본문이 없어도 성공이다.
- `APIServiceProtocol`이 요구하는 것은 `requestData` 하나다. `request`는 extension이라, 가짜 구현도 실제와 같은 디코더와 봉투 규칙을 거친다.
- 이 모듈을 링크하는 곳은 Data뿐이다. Feature·Domain에 `import CoreNetwork`가 생기면 `APIError`가 위로 새는 것이다.
- API별 `APIEndpoint`와 DTO는 여기 두지 않는다. Data의 `DataSource/Remote`에 둔다.
- (미적용) `Alamofire`는 Moya를 통해 간접으로 들어온다. 직접 import하므로 `Tuist/Package.swift`에 명시적으로 선언한다.

## 에러

- `APIError`는 **통신 사실만** 담는다(상태 코드, 디코딩, 세션 만료). 사용자에게 보여 줄 문구를 갖지 않는다. 문구는 Feature가 만든다.
- 세션 만료는 호출 하나의 에러가 아니라 앱 전역 이벤트다. 만료 알림은 이 모듈이 내보내고, Domain UseCase가 받아서 App에 노출한다.
- (미적용) `Sources/Error/APIError+UserMessage.swift`는 이 규칙을 어긴다. 사용자 문구는 Feature로 옮기고, `APIError`의 `LocalizedError` 채택도 다시 검토한다.

## 테스트

- stub provider와 `Tests/Helpers`(`MockURLProtocol`, `InMemoryTokenStorage`, `Fixtures`)로 요청, 디코딩, 토큰 갱신을 검증한다.
- fixture에 실제 토큰을 넣지 않는다.
