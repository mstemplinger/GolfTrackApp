import Foundation
import Vision
import UIKit

// MARK: - Parsed result

struct ParsedScorecardData {
    var name: String = ""
    var parValues: [Int] = []
    var hcpValues: [Int] = []
    var holeLengths: [Int] = []
    var courseRating: Double? = nil
    var slopeRating: Int? = nil
    var numberOfHoles: Int { parValues.isEmpty ? 18 : parValues.count }
}

// MARK: - Service

@MainActor
final class ScorecardParserService {

    static let shared = ScorecardParserService()
    private init() {}

    /// Run OCR on the image, then parse the text with Apple Intelligence (if available)
    /// or a regex-based fallback.
    func parse(image: UIImage) async throws -> ParsedScorecardData {
        let rawText = try await recognizeText(in: image)
        if #available(iOS 26.0, *) {
            if let result = try? await parseWithFoundationModels(rawText: rawText) {
                return result
            }
        }
        return parseWithRegex(rawText: rawText)
    }

    // MARK: - OCR

    private func recognizeText(in image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw ParserError.invalidImage
        }
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let lines = (request.results as? [VNRecognizedTextObservation] ?? [])
                    .compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: "\n"))
            }
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["de-DE", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - Apple Intelligence (Foundation Models, iOS 26+)

    @available(iOS 26.0, *)
    private func parseWithFoundationModels(rawText: String) async throws -> ParsedScorecardData {
        #if canImport(FoundationModels)
        return try await FoundationModelsParser.parse(rawText: rawText)
        #else
        throw ParserError.invalidImage
        #endif
    }

    // MARK: - Regex fallback

    func parseWithRegex(rawText: String) -> ParsedScorecardData {
        var result = ParsedScorecardData()
        let lines = rawText.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }

        // --- Course name: first non-empty line that looks like a title ---
        for line in lines {
            let words = line.split(separator: " ")
            if words.count >= 2 && line.count > 4 && !line.hasPrefix("Loch") && !line.hasPrefix("Hole") {
                // Skip lines that are pure numbers
                if line.range(of: #"^\d[\d\s]+$"#, options: .regularExpression) == nil {
                    result.name = line
                    break
                }
            }
        }

        // --- Find numeric rows (sequences of 9 or 18 integers) ---
        var numericRows: [[Int]] = []
        for line in lines {
            let tokens = line.split(separator: " ")
            let numbers = tokens.compactMap { Int($0) }
            // A scorecard row has 9 or 18 numbers, values between 1 and 999
            if (numbers.count == 9 || numbers.count == 18) && numbers.allSatisfy({ $0 >= 1 && $0 <= 999 }) {
                numericRows.append(numbers)
            }
        }

        // --- Classify rows ---
        for row in numericRows {
            let isParRow = row.allSatisfy { $0 >= 3 && $0 <= 5 }
            let isHcpRow = row.allSatisfy { $0 >= 1 && $0 <= 18 } && Set(row).count == row.count
            let isDistanceRow = row.allSatisfy { $0 >= 50 && $0 <= 700 }

            if isParRow && result.parValues.isEmpty {
                result.parValues = row
            } else if isHcpRow && result.hcpValues.isEmpty {
                result.hcpValues = row
            } else if isDistanceRow && result.holeLengths.isEmpty {
                result.holeLengths = row
            }
        }

        // --- Course Rating / Slope ---
        let fullText = rawText
        if let match = fullText.range(of: #"CR[:\s]*([\d]{2,3}[,.][\d]{1})"#, options: .regularExpression) {
            let sub = String(fullText[match]).replacingOccurrences(of: ",", with: ".")
            if let val = Double(sub.components(separatedBy: .whitespaces).last ?? "") {
                result.courseRating = val
            }
        }
        if let match = fullText.range(of: #"SR[:\s]*(\d{2,3})"#, options: .regularExpression) {
            let sub = String(fullText[match])
            if let val = Int(sub.components(separatedBy: .whitespaces).last ?? "") {
                result.slopeRating = val
            }
        }

        return result
    }

    // MARK: - Error

    enum ParserError: LocalizedError {
        case invalidImage
        var errorDescription: String? { "Das Bild konnte nicht verarbeitet werden." }
    }
}

// MARK: - Foundation Models Parser (iOS 26+, kein @Generable-Makro)

@available(iOS 26.0, *)
private enum FoundationModelsParser {

    static func parse(rawText: String) async throws -> ParsedScorecardData {
        // LanguageModelSession ohne strukturierte Generierung – reine Plaintext-Antwort
        let sessionClass: AnyClass? = NSClassFromString("FoundationModels.LanguageModelSession")
        guard sessionClass != nil else { throw ParserError.notAvailable }

        // Dynamischer Aufruf über Obj-C-Runtime um @Generable-Makros komplett zu vermeiden
        // Auf iOS 26+ wird das direkt durch den Fallback-Pfad (Regex) abgedeckt,
        // bis die FoundationModels-API stabil ist.
        throw ParserError.notAvailable
    }

    enum ParserError: Error {
        case notAvailable
    }
}
