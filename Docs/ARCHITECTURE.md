# Architecture

The code separates the deterministic domain from platform UI. `LiftRelayCore` contains value models, unit conversion, voice parsing, substitution scoring, and whole-session relaying. It compiles and tests independently of iOS.

The SwiftUI target owns app state at the root and injects it through the environment. Feature state stays local to its view, and model-bearing modals use item-driven presentation. The app persists workouts locally first; network enhancement is optional and never blocks logging.

## Recommendation boundary

1. Filter hard constraints: availability, restrictions, duplicate/completed exercises, and experience.
2. Rank valid candidates with configurable weights for movement, muscle overlap, goal, equipment, fatigue, and preferences.
3. Display local results immediately.
4. A future server may return structured enhancements through `AIRecommendationClient`.
5. Validate count, ranges, confidence, and identifiers before merging. Remote text never directly mutates workout state.

## Data evolution

Core records are `Codable` and use stable UUIDs. Before a public release, move workout-history storage from the current MVP preferences adapter to a versioned SwiftData schema with explicit migrations. Planned and performed exercises must remain separate fields in every schema version.

## Gym Pulse boundary

Gym Pulse is deliberately not exposed in the MVP. Future reports must be opt-in, aggregated, time-bounded, and labelled either Live Reports or Historical Estimates. Location and workout history must not be exposed at user level.
