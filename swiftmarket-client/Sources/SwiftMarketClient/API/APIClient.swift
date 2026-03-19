import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct APIClient {
    let baseURL = "http://localhost:8080"

    private var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    private var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }

    // MARK: - Generic Helpers

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let url = URL(string: "\(baseURL)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let (data, response) = try await performRequest(request)
        try checkResponse(response, data: data)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func post<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        let url = URL(string: "\(baseURL)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(body)
        let (data, response) = try await performRequest(request)
        try checkResponse(response, data: data)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func put<T: Decodable>(_ path: String) async throws -> T {
        let url = URL(string: "\(baseURL)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let (data, response) = try await performRequest(request)
        try checkResponse(response, data: data)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func delete(_ path: String) async throws -> Data {
        let url = URL(string: "\(baseURL)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        let (data, response) = try await performRequest(request)
        try checkResponse(response, data: data)
        return data
    }

    // MARK: - Network + Error Handling

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await URLSession.shared.data(for: request)
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain &&
               (nsError.code == NSURLErrorCannotConnectToHost || nsError.code == NSURLErrorNetworkConnectionLost || nsError.code == NSURLErrorTimedOut) {
                throw APIError.connectionFailed
            }
            throw APIError.connectionFailed
        }
    }

    private func checkResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }

        switch http.statusCode {
        case 200...204:
            return
        case 404:
            let serverErr = try? decoder.decode(ServerError.self, from: data)
            throw APIError.notFound(serverErr?.reason ?? "Resource not found.")
        case 409:
            let serverErr = try? decoder.decode(ServerError.self, from: data)
            throw APIError.conflict(serverErr?.reason ?? "Conflict.")
        case 422:
            let serverErr = try? decoder.decode(ServerError.self, from: data)
            throw APIError.validationFailed(serverErr?.reason ?? "Invalid data.")
        default:
            let serverErr = try? decoder.decode(ServerError.self, from: data)
            throw APIError.serverError(serverErr?.reason ?? "Server error (\(http.statusCode)).")
        }
    }

    // MARK: - Users

    func createUser(_ body: CreateUserRequest) async throws -> UserResponse {
        try await post("/users", body: body)
    }

    func getUsers() async throws -> [UserResponse] {
        try await get("/users")
    }

    func getUser(id: UUID) async throws -> UserResponse {
        try await get("/users/\(id.uuidString)")
    }

    func getUserListings(userID: UUID) async throws -> [ListingResponse] {
        try await get("/users/\(userID.uuidString)/listings")
    }

    // MARK: - Listings

    func createListing(_ body: CreateListingRequest) async throws -> ListingResponse {
        try await post("/listings", body: body)
    }

    func getListings(page: Int = 1, category: String? = nil, query: String? = nil) async throws -> PagedListingResponse {
        var components = URLComponents(string: "\(baseURL)/listings")!
        var queryItems: [URLQueryItem] = [URLQueryItem(name: "page", value: "\(page)")]
        if let category, !category.isEmpty {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        if let query, !query.isEmpty {
            queryItems.append(URLQueryItem(name: "q", value: query))
        }
        components.queryItems = queryItems

        var request = URLRequest(url: components.url!)
        request.httpMethod = "GET"
        let (data, response) = try await performRequest(request)
        try checkResponse(response, data: data)
        do {
            return try decoder.decode(PagedListingResponse.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func getListing(id: UUID) async throws -> ListingResponse {
        try await get("/listings/\(id.uuidString)")
    }

    func deleteListing(id: UUID) async throws -> ListingResponse {
        // On récupère le listing AVANT de le supprimer (pour afficher le titre)
        let listing: ListingResponse = try await get("/listings/\(id.uuidString)")
        _ = try await delete("/listings/\(id.uuidString)")
        return listing
    }

    // MARK: - Bonus: Offers

    func createOffer(listingID: UUID, body: CreateOfferRequest) async throws -> OfferResponse {
        try await post("/listings/\(listingID.uuidString)/offers", body: body)
    }

    func getOffers(listingID: UUID) async throws -> [OfferResponse] {
        try await get("/listings/\(listingID.uuidString)/offers")
    }

    func acceptOffer(id: UUID) async throws -> OfferActionResponse {
        try await put("/offers/\(id.uuidString)/accept")
    }

    func rejectOffer(id: UUID) async throws -> OfferActionResponse {
        try await put("/offers/\(id.uuidString)/reject")
    }
}
