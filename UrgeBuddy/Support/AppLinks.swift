import Foundation

enum AppLinks {
    static let support = URL(string: "https://jacobrozell.github.io/Urge-Buddy/support.html")!
    static let privacy = URL(string: "https://jacobrozell.github.io/Urge-Buddy/privacy.html")!
    static let accessibility = URL(string: "https://jacobrozell.github.io/Urge-Buddy/accessibility.html")!
    static let crisisFindAHelpline = URL(string: "https://findahelpline.com")!
    static let urgeSurfingPractice = URL(string: "https://www.mirecc.va.gov/MIRECC/visn5/EBT/CBT-SUD/Urge-Surfing.asp")!
    static let urgeSurfingOrigin = URL(string: "https://inquiringmind.com/article/2602_w_marlatt-interview-with-g-alan-marlatt-surfing-the-urge/")!

    static let appStoreAppID: String = "6752591094"

    static var appStoreReview: URL {
        URL(string: "https://apps.apple.com/app/id\(appStoreAppID)?action=write-review")!
    }
}
