# APIService 재구성 로드맵: 가장 단순한 request부터 토큰 갱신까지

## TL;DR

- 기존 HyperFocus의 `APIService`는 400줄 가까이 되지만, 기능은 6개뿐이고 대부분이 같은 코드의 반복입니다.
- 한 번에 옮기지 않고, **가장 단순한 `request`를 만든 뒤 기능을 한 단계씩 얹습니다.** 단계마다 테스트로 확인하고 커밋합니다.
- 토큰 갱신과 경합 처리는 서비스 계층이 아니라 **Alamofire 인터셉터(`AuthenticationInterceptor`)** 로 옮기는 것이 목표입니다.

| 단계 | 추가할 것 | 상태 |
| --- | --- | --- |
| 0 | 가장 단순한 `request` | ✅ 완료 (`7cf2783`) |
| 1 | 공통 디코더 | ✅ 완료 |
| 2 | 핵심 함수 `send` 분리 + `requestData` | ⬜ |
| 3 | 취소 지원 | ⬜ |
| 4 | 토큰 주입 인터셉터 (`RequestAdapter`) | ⬜ |
| 5 | `AuthenticationInterceptor` (갱신·재시도·경합) | ⬜ |
| 6 | 갱신 실패 구분 + 세션 만료 1회 발행 | ⬜ |
| 7 | 선제 갱신 (`expiresIn`) | ⬜ |
| 별도 | Keychain 이전, 로깅 | ⬜ |

---

## 들어가며: 왜 다시 만드나

### 기존 APIService가 하는 일

| # | 기능 | 기존 위치 |
| --- | --- | --- |
| 1 | 요청 방식 3가지: `request`(바로 디코딩), `requestWrapped`(`APIResponse<D>`로 감싸서 디코딩), `requestData`(`Data` 반환) | public 메서드 3개 |
| 2 | 토큰 사전 검사: 토큰이 필요한데 없으면 `.tokenNotFound` | `checkAuthToken` |
| 3 | Moya 콜백을 async로 변환하고, 상태코드가 실패면 `.httpError`로 바꿈 | `performRequest*` 3개 |
| 4 | 디코딩: snake_case 변환. Wrapped만 날짜 포맷 4종 fallback | `performRequest*` 내부 |
| 5 | 401이면 토큰 갱신 후 1회 재시도. 갱신은 동시에 한 번만(actor). 실패하면 세션 만료 발행 | `TokenRefreshManager`, `refreshTokenIfNeeded` |
| 6 | TCA 의존성 등록 (live / test) | `DependencyKey` |

실제 사용처를 확인해 보면 이렇습니다.

- `request`: 호출하는 곳이 없음 → **삭제**
- `requestWrapped`: 모든 Repository가 사용 (약 40곳)
- `requestData`: `SoundAPI.getSoundFile` 1곳 (음악 파일 다운로드). 이 요청도 `Authorization` 헤더가 붙으므로 401 처리가 필요함

### 왜 복잡해졌나

**Moya Plugin으로는 재시도를 할 수 없기 때문입니다.**

| Moya `PluginType` 메서드 | 할 수 있는 일 |
| --- | --- |
| `prepare` | 요청 수정 (토큰 주입) ✅ |
| `willSend` / `didReceive` | 관찰 (로깅) |
| `process` | 결과 가공 |
| 재시도 | ❌ 없음 |

그래서 토큰 주입은 Plugin(`NetworkAuthPlugin`)이 하고, 갱신과 재시도는 APIService가 직접 하게 됐습니다. 그 결과 401 재시도 블록이 메서드 3개에 복사됐습니다.

다른 플랫폼에서도 토큰 갱신은 보통 HTTP 클라이언트의 **인터셉터 계층**이 맡습니다.

| 플랫폼 | 맡는 곳 |
| --- | --- |
| iOS (Alamofire) | `RequestInterceptor` / `AuthenticationInterceptor` |
| Android (OkHttp) | `Interceptor` + `Authenticator` |
| Web (Axios) | response interceptor |

Moya는 내부적으로 Alamofire `Session`을 쓰므로, 인터셉터를 단 Session을 주입하면 됩니다.

```swift
MoyaProvider<MultiTarget>(session: Session(interceptor: ...))
```

### 기존 코드에서 찾은 문제

| | 문제 | 결과 | 해결 단계 |
| --- | --- | --- | --- |
| 🔴 ① | 세션 만료를 요청마다 발행 | 동시에 401을 받은 요청 수만큼 `autoLogin()`이 실행됨 | 5·6 |
| 🔴 ② | refresh token 회전과의 경합 | 이미 끝난 갱신을 모르고 옛 refresh token으로 다시 갱신 → 정상 세션이 만료 처리됨 | 5 |
| 🟠 ③ | 네트워크 오류도 세션 만료로 처리 | 오프라인일 때 로그아웃될 위험 | 6 |
| 🟠 ④ | 토큰을 UserDefaults에 평문 저장 | 백업에 포함됨, 암호화되지 않음 | 별도 |
| 🟡 | `"Authorization": ""` 빈 헤더로 인증 필요 여부를 표시 | 규칙이 코드에 드러나지 않음 | 4 |
| 🟡 | 날짜 디코딩 전략이 Wrapped에만 있고, 포매터를 매번 생성 | 메서드마다 디코딩 결과가 다름, 성능 낭비 | 1 |
| 🟡 | Task를 취소해도 네트워크 요청은 계속됨 | 화면을 떠나도 요청이 끝까지 진행 | 3 |

②번 경합은 이런 순서로 일어납니다.

```
t0  요청 A, B가 옛 토큰으로 출발
t1  B가 401 → 갱신 (refresh token R1 → R2)
t2  A가 늦게 401 → 갱신을 또 시작 → 이미 무효인 R1을 보내면 실패 ❌
```

---

## 0단계: 가장 단순한 request ✅

**목표**: Moya 호출 → `APIResponse<D>` 디코딩 → `APIError` 변환. 다른 기능은 넣지 않습니다.

**구현 포인트**

- Moya에는 async API가 없으므로 `withCheckedThrowingContinuation`으로 감쌉니다.
- continuation은 **모든 경로에서 정확히 한 번** resume해야 합니다. 빈 `catch`처럼 resume을 빠뜨리면 `await`가 영원히 끝나지 않습니다.
- 200번대가 아닌 응답은 따로 검사하지 않습니다. `BaseTarget.validationType = .successCodes` 설정 때문에 Moya가 이미 `.failure(.statusCode)`로 넘기고, `APIError.from`이 그걸 `httpError`로 바꿉니다.

**통과 기준** (`CoreNetworkTests`, Moya stub 사용)

- [x] 200 응답을 snake_case로 디코딩
- [x] 500 응답이면 `httpError(500, 서버 메시지)`
- [x] 깨진 JSON이면 `decodingError`
- [x] 연결 실패면 `networkError`

**확인된 사실**: Moya stub 응답에도 `validationType`이 적용됩니다.

---

## 1단계: 공통 디코더 ✅

**목표**: 디코더를 `static let` 하나로 공유하고, snake_case와 날짜 전략을 한 곳에서 정합니다.

**구현** (`APIService+Decoder.swift`)

- `JSONDecoder.api`: 모든 응답이 공유하는 디코더
- `ServerDate`: `Date.ISO8601FormatStyle` 두 개로 기존 포맷 4종을 모두 처리
  - 시간대 표기 있음 (`…Z`, `…+09:00`) → 표기된 시간대
  - 시간대 표기 없음 → UTC. 소수 초 0~6자리를 하나의 전략으로 처리
  - **순서 중요**: 시간대 없는 전략은 `+09:00`을 무시하므로 나중에 시도

**확인된 사실**

- `Date.ParseStrategy`는 쓰지 않습니다. `.fractional(6)`이어도 소수 초를 밀리초까지만 보존하고(`.123456` → `.123`), 기본값이 lenient라 `2026/11/20 07:50:11`도 통과시킵니다.
- `ISO8601FormatStyle`은 `Sendable`인 값 타입이라 `static let`으로 두고 `@Sendable` 클로저에서 그대로 쓸 수 있습니다.
- 날짜 뒤에 붙은 문자(`…Zjunk`)는 무시하고 파싱에 성공합니다. 서버가 보낼 일은 없어서 그대로 둡니다.

**통과 기준**

- [x] 날짜가 들어 있는 JSON 디코딩 성공 (마이크로초·밀리초·초 단위 포맷)
- [x] 날짜 포매터를 요청마다 만들지 않음

---

## 2단계: 핵심 함수 send 분리 + requestData

**목표**: JSON 요청과 Data 요청이 같은 경로를 거치게 합니다.

```
send(target) -> Data      ← 이후 단계의 공통 처리가 모두 여기에 모임
 ├─ request     → send 결과를 디코딩
 └─ requestData → send 결과를 그대로 반환
```

**정할 것**: 반환 타입 (1단계에서 넘어옴)

| 선택지 | 특징 |
| --- | --- |
| `APIResponse<D>` (지금) | 기존 호출부 40곳과 호환. Repository/UseCase가 `.data`를 꺼내고 `success`를 확인 |
| `D` | 응답 봉투(`APIResponse`)가 네트워크 계층 밖으로 새지 않음. `success == false`를 에러로 바꾸는 규칙을 서비스가 맡음 |

`D`로 가려면 `data: null` 규칙을 함께 정해야 합니다. 기존 코드에는 `EmptyResponse`(10곳) 외에도 `data: null`을 정상 값으로 쓰는 API가 있습니다.

**함께 고칠 것**: 디코딩 실패 시 `error.localizedDescription` 대신 `String(describing: error)`로 담아 `codingPath`와 `debugDescription`을 로그에 남깁니다.

**통과 기준**

- [ ] `request`와 `requestData`가 `send`를 공유
- [ ] `requestData`의 성공·실패 테스트

---

## 3단계: 취소 지원

**목표**: TCA Effect가 취소되면 네트워크 요청도 취소합니다.

**힌트**: `withTaskCancellationHandler`와 Moya `request`가 반환하는 `Cancellable`을 함께 씁니다.

**통과 기준**

- [ ] Task 취소 시 `.cancelled`

**3단계를 마칠 때 준비할 것**: `URLProtocol` mock. 아래 주의 사항을 참고하세요.

> ⚠️ **4단계부터는 Moya stub으로 테스트할 수 없습니다.** Moya stub(`immediatelyStub`)은 Alamofire `Session`을 거치지 않고 바로 응답을 돌려주므로 인터셉터가 실행되지 않습니다. 4단계부터는 `URLProtocol`을 상속한 mock을 `Session`의 configuration에 끼워서 테스트합니다.

---

## 4단계: 토큰 주입 인터셉터

**목표**: `NetworkAuthPlugin`을 `RequestAdapter`로 대체합니다. 아직 갱신은 하지 않습니다.

**함께 정리할 것**: `"Authorization": ""` 빈 헤더 대신 `BaseTarget.requiresAuth: Bool`로 인증 필요 여부를 명시합니다. 토큰 타입은 하드코딩한 `"Bearer"` 대신 서버가 주는 `tokenType`을 씁니다.

**통과 기준**

- [ ] `requiresAuth == true`인 요청에 `Bearer <token>` 헤더가 붙음
- [ ] 토큰이 없으면 요청을 보내지 않고 `.tokenNotFound`
- [ ] `NetworkAuthPlugin` 삭제

---

## 5단계: AuthenticationInterceptor

**목표**: 갱신, 재시도, 경합 처리를 Alamofire에 맡깁니다.

`Authenticator` 프로토콜의 메서드 4개가 기존 문제와 하나씩 대응합니다.

| 메서드 | 하는 일 | 해결되는 것 |
| --- | --- | --- |
| `apply(_:to:)` | 요청에 토큰 주입 | 4단계의 어댑터 대체 |
| `didRequest(_:with:failDueToAuthenticationError:)` | 이 실패가 인증 실패인지 판단 (보통 401) | 반복된 401 블록 |
| `isRequest(_:authenticatedWith:)` | 이 요청이 **현재** 토큰으로 나갔는지 확인 | **② 회전 경합**: 옛 토큰이었으면 갱신 없이 재시도 |
| `refresh(_:for:completion:)` | 실제 갱신. 동시에 한 번만 실행되고 나머지 요청은 대기 | `TokenRefreshManager` 제거 |

**주의**

- 갱신 요청(`/auth/refresh`)이 다시 인터셉터를 타면 루프가 생깁니다. 인터셉터가 없는 Session을 따로 둡니다.
- Alamofire의 재시도는 요청이 **실패했을 때만** 동작합니다. 401이 실패로 처리되도록 `validationType = .successCodes`를 유지합니다.

**통과 기준**

- [ ] 401 → 갱신 → 재시도 성공
- [ ] 동시에 401이 와도 갱신은 1번
- [ ] 갱신 직후에 늦게 도착한 401은 갱신 없이 재시도
- [ ] `TokenRefreshManager`와 401 재시도 블록 삭제

---

## 6단계: 갱신 실패 구분 + 세션 만료 1회 발행

**목표**: 갱신 결과를 세 가지로 나누고, 세션 만료는 정말 만료됐을 때 한 번만 알립니다.

| 갱신 결과 | 처리 |
| --- | --- |
| 성공 | 재시도 |
| refresh token 무효 (서버가 401/403 응답) | 세션 만료 발행 |
| 일시적 실패 (네트워크 오류) | 세션 유지, 에러만 전달 |

**힌트**: `refresh`는 동시에 한 번만 실행되므로, 세션 만료 발행을 `refresh`의 실패 분기에 두면 자연스럽게 한 번만 발행됩니다.

**통과 기준**

- [ ] 오프라인에서 갱신에 실패해도 세션 만료 이벤트가 나가지 않음
- [ ] 동시에 5개 요청이 실패해도 세션 만료 이벤트는 1번

---

## 7단계: 선제 갱신

**목표**: 401을 받기 전에, 만료가 가까운 토큰이면 미리 갱신합니다.

**힌트**: `TokenEntity`를 `AuthenticationCredential`로 만들고, `requiresRefresh`에서 `expiresIn`(또는 JWT의 `exp` 클레임)을 씁니다. 기존 코드는 `expiresIn`을 저장만 하고 쓰지 않았습니다.

**통과 기준**

- [ ] 만료가 가까운 토큰이면 요청을 보내기 전에 갱신

---

## 별도 트랙

네트워크 단계와 무관하므로 아무 때나 끼워 넣을 수 있습니다.

| 항목 | 내용 |
| --- | --- |
| Keychain 이전 | refresh token까지 UserDefaults에 평문 저장 중. Keychain으로 옮김 |
| 로깅 | `NetworkLoggingPlugin`은 Plugin 역할(관찰)에 맞으므로 그대로 Moya Plugin으로 둠 |
| WebSocket | `StompClient`도 access token을 쓰지만 갱신 흐름에 포함되지 않음. 소켓 연결 중 만료되면 어떻게 되는지 확인 필요 |
| 모듈 경계 | `APIError+Reason.swift`의 `deferralReason`은 집중 세션 애널리틱스 전용. Core에서 Feature/Data 쪽으로 옮길지 검토 |
