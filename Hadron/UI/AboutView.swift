import SwiftUI

/// About screen: version, links to the portal, and the legal documents
/// App Review expects to be reachable in-app.
struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 10) {
                    Image("HadronMark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    Text("Hadron")
                        .font(.title3.bold())
                    Text("Version \(Self.version) (\(Self.build))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .listRowBackground(Color.clear)
            }

            Section {
                Link(destination: AppState.config.portalBaseURL) {
                    Label("hadronmemory.com", systemImage: "globe")
                }
                Link(destination: URL(string: "https://docs.hadronmemory.com")!) {
                    Label("Documentation", systemImage: "book")
                }
            }

            Section("Legal") {
                Link(destination: URL(string: "https://docs.hadronmemory.com/legal/privacy/")!) {
                    Label("Privacy Statement", systemImage: "hand.raised")
                }
                Link(destination: URL(string: "https://docs.hadronmemory.com/legal/terms/")!) {
                    Label("Terms of Service", systemImage: "doc.text")
                }
            }

            Section {
                Text("© 2026 Baragaun, Inc.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }
}
