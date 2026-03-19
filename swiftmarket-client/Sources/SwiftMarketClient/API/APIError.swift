import Foundation

enum APIError: Error {
    case notFound(String)
    case conflict(String)
    case validationFailed(String)
    case serverError(String)
    case connectionFailed
    case decodingError(Error)

    var message: String {
        switch self {
        case .notFound(let msg):
            return msg
        case .conflict(let msg):
            return msg
        case .validationFailed(let msg):
            return "Validation failed.\n\(msg)"
        case .serverError(let msg):
            return msg
        case .connectionFailed:
            return """
                Could not connect to server at http://localhost:8080.
                Make sure the server is running: swift run in swiftmarket-server/
                """
        case .decodingError(let err):
            return "Failed to decode server response: \(err.localizedDescription)"
        }
    }
}
