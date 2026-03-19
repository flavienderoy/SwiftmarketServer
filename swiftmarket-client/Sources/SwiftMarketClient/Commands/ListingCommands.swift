import ArgumentParser
import Foundation

// MARK: - listings

struct ListingsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "listings",
        abstract: "List all listings (paginated)"
    )

    @Option(name: .long, help: "Page number (default: 1)")
    var page: Int = 1

    @Option(name: .long, help: "Filter by category")
    var category: String?

    @Option(name: .long, help: "Search query")
    var query: String?

    func run() async throws {
        let api = APIClient()
        do {
            let result = try await api.getListings(page: page, category: category, query: query)

            if result.items.isEmpty {
                print("")
                print("No listings found.")
                return
            }

            print("")
            if result.totalPages > 1 {
                print("Listings (page \(result.page)/\(result.totalPages) — \(result.totalCount) results)")
            } else {
                print("Listings (\(result.totalCount) results)")
            }
            print(separator)
            print("\(padRight("ID", 38))\(padRight("Title", 19))\(padRight("Price", 10))\(padRight("Category", 14))\("Seller")")
            for item in result.items {
                print("\(padRight(item.id.uuidString, 38))\(padRight(item.title, 19))\(padRight(formatPrice(item.price), 10))\(padRight(item.category, 14))\(item.seller.username)")
            }

            if result.page < result.totalPages {
                print(separator)
                print("Next page: swiftmarket listings --page \(result.page + 1)")
            }
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

// MARK: - listing <id>

struct ListingCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "listing",
        abstract: "Show listing details"
    )

    @Argument(help: "Listing ID (UUID)")
    var id: String

    func run() async throws {
        guard let uuid = UUID(uuidString: id) else {
            printError("Invalid UUID format.")
            throw ExitCode.failure
        }
        let api = APIClient()
        do {
            let listing = try await api.getListing(id: uuid)
            print("")
            print(listing.title)
            print(String(repeating: "─", count: 40))
            print("Price:       \(formatPrice(listing.price))")
            print("Category:    \(listing.category)")
            print("Description: \(listing.description)")
            print("Seller:      \(listing.seller.username) (\(listing.seller.email))")
            print("Posted:      \(formatDate(listing.createdAt))")
        } catch let error as APIError {
            switch error {
            case .notFound:
                printError("Listing not found.")
            default:
                handleAPIError(error)
            }
            throw ExitCode.failure
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

// MARK: - post

struct PostCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "post",
        abstract: "Create a new listing"
    )

    @Option(name: .long, help: "Listing title")
    var title: String

    @Option(name: .long, help: "Description")
    var desc: String

    @Option(name: .long, help: "Price")
    var price: Double

    @Option(name: .long, help: "Category (electronics, clothing, furniture, other)")
    var category: String

    @Option(name: .long, help: "Seller user ID (UUID)")
    var seller: String

    func run() async throws {
        guard let sellerID = UUID(uuidString: seller) else {
            printError("Invalid seller UUID format.")
            throw ExitCode.failure
        }
        let api = APIClient()
        do {
            let body = CreateListingRequest(
                title: title,
                description: desc,
                price: price,
                category: category,
                sellerID: sellerID
            )
            let listing = try await api.createListing(body)
            print("")
            print("Listing created successfully.")
            print("ID:          \(listing.id)")
            print("Title:       \(listing.title)")
            print("Price:       \(formatPrice(listing.price))")
            print("Category:    \(listing.category)")
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

// MARK: - delete <id>

struct DeleteCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "delete",
        abstract: "Delete a listing"
    )

    @Argument(help: "Listing ID (UUID)")
    var id: String

    func run() async throws {
        guard let uuid = UUID(uuidString: id) else {
            printError("Invalid UUID format.")
            throw ExitCode.failure
        }
        let api = APIClient()
        do {
            let listing = try await api.deleteListing(id: uuid)
            print("")
            print("Listing \"\(listing.title)\" deleted.")
        } catch let error as APIError {
            switch error {
            case .notFound:
                printError("Listing not found.")
            default:
                handleAPIError(error)
            }
            throw ExitCode.failure
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}
