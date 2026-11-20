import SwiftUI

final class Tab: ObservableObject, Identifiable {
    let id = UUID()
    let isPrivate: Bool
    let engine: BrowserEngine
    @Published var started = false

    init(isPrivate: Bool) {
        self.isPrivate = isPrivate
        engine = WebKitEngine(isPrivate: isPrivate)
        engine.onChange = { [weak self] in self?.objectWillChange.send() }
    }

    var displayTitle: String {
        if !started { return "New Tab" }
        return engine.title.isEmpty ? (engine.url?.host ?? "Loading…") : engine.title
    }

    func go(_ input: String) {
        let t = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        var target: URL?
        if t.hasPrefix("http://") || t.hasPrefix("https://") {
            target = URL(string: t)
        } else if !t.contains(" ") && t.contains(".") {
            target = URL(string: "https://" + t)
        } else {
            var c = URLComponents(string: "https://www.google.com/search")!
            c.queryItems = [URLQueryItem(name: "q", value: t)]
            target = c.url
        }
        if let target { started = true; engine.load(target) }
    }
}

final class BrowserModel: ObservableObject {
    @Published var tabs: [Tab]
    @Published var currentID: UUID

    init() {
        let t = Tab(isPrivate: false)
        tabs = [t]
        currentID = t.id
    }

    var current: Tab { tabs.first { $0.id == currentID } ?? tabs[0] }

    func newTab(isPrivate: Bool = false) {
        let t = Tab(isPrivate: isPrivate)
        tabs.append(t)
        currentID = t.id
    }

    func close(_ tab: Tab) {
        tabs.removeAll { $0.id == tab.id }
        if tabs.isEmpty { newTab() }
        else if !tabs.contains(where: { $0.id == currentID }) { currentID = tabs[tabs.count - 1].id }
    }
}
