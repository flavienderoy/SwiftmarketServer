import ArgumentParser
import Foundation

// MARK: - create-user

struct CreateUserCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create-user",
        abstract: "Create a new user"
    )

    @Option(name: .long, help: "Username")
    var username: String

    @Option(name: .long, help: "Email address")
    var email: String

    func run() async throws {
        let api = APIClient()
        do {
            let user = try await api.createUser(CreateUserRequest(username: username, email: email))
            print("")
            print("User created successfully.")
            print("ID:       \(user.id)")
            print("Username: \(user.username)")
            print("Email:    \(user.email)")
        } catch let error as APIError {
            switch error {
            case .conflict:
                printError("A user with this username or email already exists.")
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

// MARK: - users

struct UsersCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "users",
        abstract: "List all users"
    )

    func run() async throws {
        let api = APIClient()
        do {
            let users = try await api.getUsers()
            print("")
            print("Users (\(users.count))")
            print(separator)
            print("\(padRight("ID", 38))\(padRight("Username", 11))\("Email")")
            for user in users {
                print("\(padRight(user.id.uuidString, 38))\(padRight(user.username, 11))\(user.email)")
            }
        } catch {
            handleAPIError(error)
            throw ExitCode.failure
        }
    }
}

// MARK: - user <id>

struct UserCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "user",
        abstract: "Show user profile"
    )

    @Argument(help: "User ID (UUID)")
    var id: String

    func run() async throws {
        guard let uuid = UUID(uuidString: id) else {
            printError("Invalid UUID format.")
            throw ExitCode.failure
        }
        let api = APIClient()
        do {
            let user = try await api.getUser(id: uuid)
            print("")
            print(user.username)
            print("Email:        \(user.email)")
            print("Member since: \(formatDate(user.createdAt))")
        } catch let error as APIError {
            switch error {
            case .notFound:
                printError("User not found.")
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

// MARK: - user-listings <userID>

struct UserListingsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "user-listings",
        abstract: "List all listings by a user"
    )

    @Argument(help: "User ID (UUID)")
    var userID: String

    func run() async throws {
        guard let uuid = UUID(uuidString: userID) else {
            printError("Invalid UUID format.")
            throw ExitCode.failure
        }
        let api = APIClient()
        do {
            let user = try await api.getUser(id: uuid)
            let listings = try await api.getUserListings(userID: uuid)

            print("")
            print("Listings by \(user.username) (\(listings.count))")
            print(separator)
            print("\(padRight("ID", 38))\(padRight("Title", 19))\(padRight("Price", 10))\("Category")")
            for listing in listings {
                print("\(padRight(listing.id.uuidString, 38))\(padRight(listing.title, 19))\(padRight(formatPrice(listing.price), 10))\(listing.category)")
            }
        } catch let error as APIError {
            switch error {
            case .notFound:
                printError("User not found.")
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
