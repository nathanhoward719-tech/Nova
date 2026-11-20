import UIKit
import WebKit

protocol BrowserEngine: AnyObject {
    var view: UIView { get }
    var onChange: (() -> Void)? { get set }
    var url: URL? { get }
    var title: String { get }
    var progress: Double { get }
    var isLoading: Bool { get }
    var canGoBack: Bool { get }
    var canGoForward: Bool { get }
    func load(_ url: URL)
    func goBack()
    func goForward()
    func reload()
    func stop()
}

final class WebKitEngine: NSObject, BrowserEngine {
    private let web: WKWebView
    private var observers: [NSKeyValueObservation] = []
    var onChange: (() -> Void)?
    var view: UIView { web }
    var url: URL? { web.url }
    var title: String { web.title ?? "" }
    var progress: Double { web.estimatedProgress }
    var isLoading: Bool { web.isLoading }
    var canGoBack: Bool { web.canGoBack }
    var canGoForward: Bool { web.canGoForward }

    init(isPrivate: Bool) {
        let config = WKWebViewConfiguration()
        if isPrivate { config.websiteDataStore = .nonPersistent() }
        config.allowsInlineMediaPlayback = true
        web = WKWebView(frame: .zero, configuration: config)
        super.init()
        web.allowsBackForwardNavigationGestures = true
        web.isOpaque = false
        let fire: () -> Void = { [weak self] in self?.onChange?() }
        observers = [
            web.observe(\.url) { _, _ in fire() },
            web.observe(\.title) { _, _ in fire() },
            web.observe(\.estimatedProgress) { _, _ in fire() },
            web.observe(\.isLoading) { _, _ in fire() },
            web.observe(\.canGoBack) { _, _ in fire() },
            web.observe(\.canGoForward) { _, _ in fire() }
        ]
    }

    func load(_ url: URL) { web.load(URLRequest(url: url)) }
    func goBack() { web.goBack() }
    func goForward() { web.goForward() }
    func reload() { web.reload() }
    func stop() { web.stopLoading() }
}
