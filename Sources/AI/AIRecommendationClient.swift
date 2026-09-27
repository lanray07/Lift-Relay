import Foundation

struct AIRecommendationRequest: Codable, Sendable {
    let plannedExercise: String
    let movementPattern: MovementPattern
    let primaryMuscles: Set<MuscleGroup>
    let secondaryMuscles: Set<MuscleGroup>
    let availableEquipment: Set<Equipment>
    let goal: TrainingGoal
    let experienceLevel: ExperienceLevel
    let completedExercises: [String]
    let timeRemaining: Int?
    let restrictions: [String]
    let preferredLanguage: String
}

struct AIRecommendationResponse: Codable, Sendable {
    struct Item: Codable, Sendable {
        let exerciseID: UUID
        let exerciseName: String
        let reason: String
        let sets: Int
        let minimumReps: Int
        let maximumReps: Int
        let suggestedLoadStrategy: String
        let confidence: Double
        let warnings: [String]
    }
    let substitutions: [Item]
}

struct AIRecommendationClient: Sendable {
    let endpoint: URL

    func recommendations(_ request: AIRecommendationRequest) async throws -> AIRecommendationResponse {
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { throw ClientError.invalidResponse }
        let decoded = try JSONDecoder().decode(AIRecommendationResponse.self, from: data)
        guard decoded.substitutions.count <= 3,
              decoded.substitutions.allSatisfy({ (1...8).contains($0.sets) && (1...50).contains($0.minimumReps) && $0.minimumReps <= $0.maximumReps && (0...1).contains($0.confidence) })
        else { throw ClientError.failedValidation }
        return decoded
    }

    enum ClientError: Error { case invalidResponse, failedValidation }
}
