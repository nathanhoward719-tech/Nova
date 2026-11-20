import SwiftUI

struct ContentView: View {
    @EnvironmentObject var model: BrowserModel
    @State private var showTabs = false

    var body: some View {
        VStack(spacing: 0) {
            TabScreen(tab: model.current).id(model.currentID)
            BottomBar(tab: model.current, showTabs: $showTabs).id(model.currentID)
        }
        .preferredColorScheme(model.current.isPrivate ? .dark : nil)
        .sheet(isPresented: $showTabs) { TabsSheet() }
    }
}

struct EngineView: UIViewRepresentable {
    let engine: BrowserEngine
    func makeUIView(context: Context) -> UIView { engine.view }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct TabScreen: View {
    @ObservedObject var tab: Tab
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: tab.isPrivate ? "eyeglasses" : (tab.engine.url?.scheme == "https" ? "lock.fill" : "magnifyingglass"))
                    .foregroundStyle(.secondary)
                TextField("Search or enter address", text: $text)
                    .focused($focused)
                    .keyboardType(.webSearch)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.go)
                    .onSubmit { tab.go(text); focused = false }
                if tab.started {
                    Button {
                        tab.engine.isLoading ? tab.engine.stop() : tab.engine.reload()
                    } label: {
                        Image(systemName: tab.engine.isLoading ? "xmark" : "arrow.clockwise")
                    }
                }
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 12).padding(.vertical, 8)

            if tab.engine.isLoading {
                ProgressView(value: tab.engine.progress).padding(.horizontal, 12)
            }

            if tab.started {
                EngineView(engine: tab.engine)
            } else {
                HomeView(tab: tab)
            }
        }
        .onChange(of: tab.engine.url) { _ in
            if !focused { text = tab.engine.url?.absoluteString ?? "" }
        }
    }
}

struct HomeView: View {
    @ObservedObject var tab: Tab
    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            TimelineView(.periodic(from: .now, by: 1)) { ctx in
                VStack(spacing: 4) {
                    Text(ctx.date, style: .time).font(.system(size: 56, weight: .thin, design: .rounded))
                    Text(ctx.date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                        .foregroundStyle(.secondary)
                }
            }
            Text("NOVA").font(.system(size: 34, weight: .bold, design: .rounded)).padding(.top, 24)
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [.indigo.opacity(0.25), .clear], startPoint: .top, endPoint: .bottom)
        )
    }
}

struct BottomBar: View {
    @ObservedObject var tab: Tab
    @EnvironmentObject var model: BrowserModel
    @Binding var showTabs: Bool

    var body: some View {
        HStack {
            Button { tab.engine.goBack() } label: { Image(systemName: "chevron.left") }
                .disabled(!tab.engine.canGoBack)
            Spacer()
            Button { tab.engine.goForward() } label: { Image(systemName: "chevron.right") }
                .disabled(!tab.engine.canGoForward)
            Spacer()
            if let url = tab.engine.url {
                ShareLink(item: url) { Image(systemName: "square.and.arrow.up") }
            } else {
                Image(systemName: "square.and.arrow.up").foregroundStyle(.tertiary)
            }
            Spacer()
            Button { showTabs = true } label: {
                Text("\(model.tabs.count)")
                    .font(.footnote.bold())
                    .frame(width: 24, height: 24)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(lineWidth: 2))
            }
            Spacer()
            Button { model.newTab(isPrivate: tab.isPrivate) } label: { Image(systemName: "plus") }
        }
        .font(.title3)
        .padding(.horizontal, 24).padding(.vertical, 10)
        .background(.bar)
    }
}

struct TabsSheet: View {
    @EnvironmentObject var model: BrowserModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(model.tabs) { tab in
                    TabRow(tab: tab, selected: tab.id == model.currentID)
                        .contentShape(Rectangle())
                        .onTapGesture { model.currentID = tab.id; dismiss() }
                }
                .onDelete { idx in idx.map { model.tabs[$0] }.forEach(model.close) }
            }
            .navigationTitle("Tabs")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Private") { model.newTab(isPrivate: true); dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("New") { model.newTab(); dismiss() }
                }
            }
        }
    }
}

struct TabRow: View {
    @ObservedObject var tab: Tab
    let selected: Bool
    var body: some View {
        HStack {
            Image(systemName: tab.isPrivate ? "eyeglasses" : "globe")
            VStack(alignment: .leading) {
                Text(tab.displayTitle).lineLimit(1)
                Text(tab.engine.url?.host ?? "").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if selected { Image(systemName: "checkmark").foregroundStyle(.tint) }
        }
    }
}
