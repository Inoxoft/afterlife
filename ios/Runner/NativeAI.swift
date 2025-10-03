import Foundation

import FoundationModels

final class NativeAI {
  static let shared = NativeAI()
  private init() {}

  static var isFoundationModelsAvailable: Bool {
    if #available(iOS 26.0, *) {
      let model = SystemLanguageModel.default
      switch model.availability {
      case .available:
        return true
      case .unavailable(_):
        return false
      @unknown default:
        return false
      }
    } else { return false }
  }

  struct FMStatus {
    let available: Bool
    let reason: String
  }

  func getStatus() -> FMStatus {
    if #available(iOS 26.0, *) {
      let model = SystemLanguageModel.default
      switch model.availability {
      case .available:
        return .init(available: true, reason: "available")
      case .unavailable(let reason):
        return .init(available: false, reason: String(describing: reason))
      @unknown default:
        return .init(available: false, reason: "unknown")
      }

    } else {
      return .init(available: false, reason: "requires_ios_26")
    }
  }

  func generateText(prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
    if #available(iOS 26.0, *) {
      Task {
        do {
          let model = SystemLanguageModel.default
          switch model.availability {
          case .available:
            break
          case .unavailable(let reason):
            completion(.failure(NSError(domain: "FMUnavailable", code: -1, userInfo: [NSLocalizedDescriptionKey: "Foundation Models unavailable: \(reason)"])) )
            return
          @unknown default:
            break
          }

          let session = LanguageModelSession()
          let response = try await session.respond(to: prompt)
          completion(.success(response.content))
        } catch {
          completion(.failure(error))
        }
      }
    } else {
      completion(.failure(NSError(domain: "IOSVersion", code: -1, userInfo: [NSLocalizedDescriptionKey: "Requires iOS 26+"])) )
    }
  }
}


