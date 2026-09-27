import Foundation

enum AnalyticsEvent: String, Sendable {
    case onboardingCompleted = "onboarding_completed"
    case workoutStarted = "workout_started"
    case workoutCompleted = "workout_completed"
    case equipmentUnavailable = "equipment_unavailable"
    case substitutionRequested = "substitution_requested"
    case substitutionSelected = "substitution_selected"
    case relayStarted = "relay_started"
    case relayAccepted = "relay_accepted"
    case timeRescueUsed = "time_rescue_used"
    case paywallViewed = "paywall_viewed"
}

actor AnalyticsClient {
    static let shared = AnalyticsClient()
    private(set) var bufferedEvents: [(AnalyticsEvent, Date)] = []

    nonisolated func track(_ event: AnalyticsEvent) {
        Task { await append(event) }
    }

    private func append(_ event: AnalyticsEvent) { bufferedEvents.append((event, .now)) }
}
