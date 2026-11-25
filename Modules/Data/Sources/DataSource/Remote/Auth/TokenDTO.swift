import CoreNetwork

struct RefreshRequestDTO: Encodable, Sendable {
    let refreshToken: String
}

struct TokenResponseDTO: Decodable, Sendable, Equatable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
}

extension TokenResponseDTO {
    func toAuthToken() -> AuthToken {
        AuthToken(accessToken: accessToken, refreshToken: refreshToken, tokenType: tokenType)
    }
}
