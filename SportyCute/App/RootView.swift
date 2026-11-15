import SwiftUI

struct RootView: View {
    private enum Tab: String, CaseIterable {
        case race = "Race"
        case crew = "Crew"
        case vault = "Vault"

        var icon: String {
            switch self {
            case .race: "figure.run"
            case .crew: "heart.fill"
            case .vault: "waveform"
            }
        }
    }

    @Bindable var race: RaceViewModel
    @Bindable var vault: VoiceVaultViewModel
    @State private var tab: Tab = .race

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "bolt.heart.fill")
                    .foregroundStyle(Theme.violet)
                    .accessibilityHidden(true)
                Text("sporty-cute").font(Theme.display(.title3))
                Spacer()
                if race.progress != nil {
                    Label("LIVE", systemImage: "circle.fill")
                        .font(Theme.label)
                        .foregroundStyle(Theme.violet)
                }
            }
            .padding(.horizontal, 23)
            .padding(.vertical, 12)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    switch tab {
                    case .race:
                        RaceView(model: race, vault: vault) { tab = .vault }
                    case .crew:
                        CrewView(vault: vault, raceIsActive: race.progress != nil)
                    case .vault:
                        VoiceVaultView(vault: vault, raceIsActive: race.progress != nil)
                    }
                }
                .frame(maxWidth: 520)
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity)
            }
            .id(tab)

            HStack(spacing: 12) {
                ForEach(Tab.allCases, id: \.self) { item in
                    Button {
                        tab = item
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: item.icon).font(.system(size: 17, weight: .semibold))
                            Text(item.rawValue).font(.system(.caption, design: .rounded, weight: .bold))
                        }
                        .frame(maxWidth: .infinity, minHeight: 49)
                        .foregroundStyle(tab == item ? Theme.violet : Theme.muted)
                        .background(tab == item ? Theme.lavender : .clear, in: RoundedRectangle(cornerRadius: 15))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(tab == item ? .isSelected : [])
                    .accessibilityIdentifier("tab.\(item.rawValue.lowercased())")
                }
            }
            .frame(maxWidth: 520)
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 3)
            .frame(maxWidth: .infinity)
            .background(alignment: .top) {
                Theme.paper.shadow(color: Theme.ink.opacity(0.09), radius: 10, y: -3)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
        .foregroundStyle(Theme.ink)
        .background(Theme.paper.ignoresSafeArea())
        .tint(Theme.violet)
        .alert("Sporty-cute", isPresented: Binding(
            get: { vault.errorMessage != nil },
            set: { if !$0 { vault.errorMessage = nil } }
        )) {
            Button("OK") { vault.errorMessage = nil }
        } message: {
            Text(vault.errorMessage ?? "")
        }
    }
}
