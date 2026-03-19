import ArgumentParser
import Foundation

// MARK: - offer <listingID> --amount --buyer

struct OfferCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "offer",
        abstract: "Make an offer on a listing"
    )

    @Argument(help: "Listing ID (UUID)")
    var listingID: String

    @Option(name: .long, help: "Offer amount")
    var amount: Double

    @Option(name: .long, help: "Buyer user ID (UUID)")
    var buyer: String

    func run() async throws {
        guard let listingUUID = UUID(uuidString: listingID) else {
            printError("Invalid listing UUID format.")
            throw ExitCode.failure
        }
        guard let buyerUUID = UUID(uuidString: buyer) else {
            printError("Invalid buyer UUID format.")
            throw ExitCode.failure
        }
        let api = APIClient()
        do {
            let body = CreateOfferRequest(amount: amount, buyerID: buyerUUID)
            let offer = try await api.createOffer(listingID: listingUUID, body: body)
            let listingTitle = offer.listing?.title ?? "N/A"
            print("")
            print("Offer sent successfully.")
            print("Listing: \(listingTitle)")
            print("Amount:  \(formatPrice(offer.amount))")
            print("Status:  \(offer.status)")
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

// MARK: - offers <listingID>

struct OffersCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "offers",
        abstract: "List offers on a listing"
    )

    @Argument(help: "Listing ID (UUID)")
    var listingID: String

    func run() async throws {
        guard let listingUUID = UUID(uuidString: listingID) else {
            printError("Invalid listing UUID format.")
            throw ExitCode.failure
        }
        let api = APIClient()
        do {
            let listing = try await api.getListing(id: listingUUID)
            let offers = try await api.getOffers(listingID: listingUUID)

            print("")
            print("Offers for \"\(listing.title)\" (\(offers.count))")
            print(separator)
            print("\(padRight("ID", 38))\(padRight("Buyer", 11))\(padRight("Amount", 11))\("Status")")
            for offer in offers {
                print("\(padRight(offer.id.uuidString, 38))\(padRight(offer.buyer.username, 11))\(padRight(formatPrice(offer.amount), 11))\(offer.status)")
            }
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

// MARK: - accept <offerID>

struct AcceptCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "accept",
        abstract: "Accept an offer"
    )

    @Argument(help: "Offer ID (UUID)")
    var id: String

    func run() async throws {
        guard let uuid = UUID(uuidString: id) else {
            printError("Invalid UUID format.")
            throw ExitCode.failure
        }
        let api = APIClient()
        do {
            let result = try await api.acceptOffer(id: uuid)
            let listingTitle = result.listing?.title ?? "N/A"
            print("")
            print("Offer accepted.")
            print("Listing: \(listingTitle)")
            print("Buyer:   \(result.buyer.username)")
            print("Amount:  \(formatPrice(result.amount))")
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

// MARK: - reject <offerID>

struct RejectCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "reject",
        abstract: "Reject an offer"
    )

    @Argument(help: "Offer ID (UUID)")
    var id: String

    func run() async throws {
        guard let uuid = UUID(uuidString: id) else {
            printError("Invalid UUID format.")
            throw ExitCode.failure
        }
        let api = APIClient()
        do {
            let result = try await api.rejectOffer(id: uuid)
            print("")
            print("Offer from \(result.buyer.username) rejected.")
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}
