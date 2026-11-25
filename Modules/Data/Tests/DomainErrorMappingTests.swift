import CoreNetwork
import Domain
import Testing
@testable import Data

struct DomainErrorMappingTests {
    @Test(arguments: [
        (APIError.networkError("timeout"), DomainError.offline),
        (.tokenNotFound, .unauthorized),
        (.sessionExpired, .unauthorized),
        (.httpError(statusCode: 401, message: nil), .unauthorized),
        (.httpError(statusCode: 403, message: nil), .unauthorized),
        (.httpError(statusCode: 404, message: nil), .notFound),
        (.httpError(statusCode: 400, message: "잘못된 값"), .invalid),
        (.httpError(statusCode: 409, message: nil), .invalid),
        (.httpError(statusCode: 422, message: nil), .invalid),
        (.httpError(statusCode: 500, message: nil), .unknown),
        (.decodingError("bad"), .unknown),
        (.unknown("?"), .unknown),
    ])
    func APIError를_Domain_에러로_바꾼다(error: APIError, expected: DomainError) {
        #expect(DomainError(error) == expected)
    }

    @Test func 토큰_갱신_응답을_AuthToken으로_바꾼다() {
        let dto = TokenResponseDTO(accessToken: "access", refreshToken: "refresh", tokenType: "Bearer")

        #expect(dto.toAuthToken() == AuthToken(accessToken: "access", refreshToken: "refresh", tokenType: "Bearer"))
    }

    @Test func 토큰_갱신은_인증_없이_보낸다() {
        #expect(AuthEndpoint.refresh(refreshToken: "refresh").requiresAuth == false)
    }
}
