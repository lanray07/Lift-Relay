import SwiftUI

extension View {
    func appSheets(_ activeSheet: Binding<AppSheet?>) -> some View {
        sheet(item: activeSheet) { destination in
            switch destination {
            case .createWorkout:
                WorkoutBuilderView(isQuick: false)
            case .quickWorkout:
                WorkoutBuilderView(isQuick: true)
            case .gymProfiles:
                GymProfilesView()
            case .paywall:
                PaywallView()
            }
        }
    }
}
