# CoreNetwork

통신 공통 코드(`APIService`, 인터셉터, 토큰 갱신)를 두는 모듈. 공통 규칙은 루트 `CLAUDE.md`를 따른다.

## 경계

- **Alamofire를 import할 수 있는 곳은 이 모듈뿐이다.** 라이브러리를 교체할 때 이 모듈만 바뀌게 하기 위해서다. 바깥에는 Alamofire 타입이 드러나지 않는 API만 공개한다.
- async/await 지원은 이 모듈이 감싸서 제공한다.
- 바깥에 공개하는 요청 단위는 `APIEndpoint`(경로, `HTTPMethod`, 본문, 인증 여부, 응답 타입 `Response`)다. `APIService`가 `URLRequest`로 바꿔 Alamofire `Session` 하나로 보낸다. `requiresAuth`가 `true`인 요청에만 토큰 인터셉터를 붙인다.
- 응답 봉투(`APIResponse`)는 이 모듈이 연다(`APIResponse.open`). 2xx인데 봉투가 약속과 다르면(`data` 없음, `success == false`) `APIError.decodingError`다. `EmptyResponse`로 받으면 `data`나 본문이 없어도 성공이다.
- 공개 API는 던지지 않고 `Result<_, APIError>`를 돌려준다(`requestData`, `request`, `TokenManager`의 `refresh` 클로저). 이 모듈이 내는 실패는 `APIError`뿐이라는 것을 타입으로 보장한다.
- `APIServiceProtocol`이 요구하는 것은 `requestData` 하나다. `request`는 extension이라, 가짜 구현도 실제와 같은 디코더와 봉투 규칙을 거친다.
- 이 모듈을 링크하는 곳은 Data뿐이다. Feature·Domain에 `import CoreNetwork`가 생기면 `APIError`가 위로 새는 것이다.
- API별 `APIEndpoint`와 DTO는 여기 두지 않는다. Data의 `DataSource/Remote`에 둔다.
- 응답은 직렬화기 없이 받는다(`request.response`). Alamofire의 async API(`serializingData` 등)는 실패한 요청을 인터셉터에 한 번 더 넘겨서, 세션 만료가 토큰 없음으로 덮인다.
- 로깅은 `APIService`가 요청 전후에 `NetworkLog`로 남긴다. 헤더는 찍지 않고, 본문은 `.debug`에 `privacy: .private`로만 찍는다. 토큰 갱신 후 재시도는 요청 한 번으로 남는다.

## 에러

- `APIError`는 **통신 사실만** 담는다(상태 코드, 디코딩, 세션 만료). 사용자에게 보여 줄 문구를 갖지 않는다. 문구는 Feature가 만든다.
- 세션 만료는 호출 하나의 에러가 아니라 앱 전역 이벤트다. 만료 알림은 이 모듈이 내보내고(`TokenManager`의 `onSessionExpired`), Data가 `AuthRepository.sessionExpired`로, Domain UseCase가 App에 노출한다.
- (미적용) `Sources/Error/APIError+UserMessage.swift`는 이 규칙을 어긴다. 사용자 문구는 Feature로 옮기고, `APIError`의 `LocalizedError` 채택도 다시 검토한다.

## 테스트

- 공개 API(`APIEndpoint`, `request`, `requestData`)로 보내고 `Tests/Helpers`의 `MockURLProtocol`로 응답해, 요청·디코딩·에러 변환·토큰 갱신을 검증한다. 테스트는 통신 라이브러리 타입을 import하지 않는다. 구현을 바꿔도 테스트는 그대로 통과해야 한다.
- fixture에 실제 토큰을 넣지 않는다.
