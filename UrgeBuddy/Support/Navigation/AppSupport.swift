import Foundation

enum AppSupport {
    static let feedbackEmail = "jacob.rozell83@gmail.com"

    static var installedVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    static var versionLabel: String {
        "Urge Buddy · Version \(installedVersion)"
    }

    static var feedbackMailtoURL: URL {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = feedbackEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Urge Buddy Feedback"),
            URLQueryItem(
                name: "body",
                value: "\n\n---\nUrge Buddy \(installedVersion)"
            )
        ]
        return components.url ?? URL(string: "mailto:\(feedbackEmail)")!
    }
}
