import SwiftUI

@main
@MainActor
struct SportyCuteApp: App {
    @State private var race: RaceViewModel
    @State private var vault: VoiceVaultViewModel

    init() {
        let directory = URL.applicationSupportDirectory.appending(path: "SportyCute")
        let vault = VoiceVaultViewModel(store: LocalRaceStore(directory: directory), audio: CheerAudio())
        _vault = State(initialValue: vault)
        _race = State(initialValue: RaceViewModel(location: LocationTracker(), bluetooth: TransitionScanner(), vault: vault))
    }

    var body: some Scene {
        WindowGroup {
            RootView(race: race, vault: vault)
                .preferredColorScheme(.light)
        }
    }
}
