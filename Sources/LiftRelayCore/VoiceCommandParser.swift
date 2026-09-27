import Foundation

public enum WorkoutVoiceAction: Equatable, Sendable {
    case logSet(reps: Int, weight: Double)
    case startRestTimer
    case equipmentUnavailable
    case timeRescue(minutes: Int)
    case whatsNext
    case repeatLast
    case unknown
}

public struct VoiceCommandParser: Sendable {
    public init() {}

    public func parse(_ transcript: String) -> WorkoutVoiceAction {
        let text = transcript.lowercased()
        if text.contains("what's next") || text.contains("whats next") { return .whatsNext }
        if text.contains("repeat") { return .repeatLast }
        if text.contains("rest timer") { return .startRestTimer }
        if text.contains("isn't available") || text.contains("is not available") || text.contains("unavailable") { return .equipmentUnavailable }
        if text.contains("minutes") && (text.contains("only") || text.contains("left")), let value = numbers(in: text).first { return .timeRescue(minutes: Int(value)) }
        if text.contains("log"), text.contains("rep") {
            let values = numbers(in: text)
            if values.count >= 2 { return .logSet(reps: Int(values[0]), weight: values[1]) }
        }
        return .unknown
    }

    private func numbers(in text: String) -> [Double] {
        let replacements: [String: String] = [
            "one":"1", "two":"2", "three":"3", "four":"4", "five":"5", "six":"6", "seven":"7", "eight":"8", "nine":"9", "ten":"10",
            "fifteen":"15", "twenty":"20", "thirty":"30", "forty":"40", "fifty":"50", "sixty":"60", "seventy":"70", "eighty":"80", "ninety":"90"
        ]
        let normalized = text.split(separator: " ").map { replacements[String($0).trimmingCharacters(in: .punctuationCharacters)] ?? String($0) }.joined(separator: " ")
        return normalized.split { !$0.isNumber && $0 != "." }.compactMap { Double($0) }
    }
}
