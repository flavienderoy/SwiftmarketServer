import Foundation

// MARK: - Error Handling

func handleAPIError(_ error: Error) {
    if let apiErr = error as? APIError {
        printError(apiErr.message)
    } else {
        printError(error.localizedDescription)
    }
}

func printError(_ message: String) {
    print("Error: \(message)")
}

// MARK: - Formatting

func formatPrice(_ price: Double) -> String {
    String(format: "%.2f€", price)
}

func formatDate(_ date: Date?) -> String {
    guard let date else { return "N/A" }
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}

let separator = String(repeating: "─", count: 65)

func padRight(_ str: String, _ width: Int) -> String {
    if str.count >= width { return String(str.prefix(width)) }
    return str + String(repeating: " ", count: width - str.count)
}
