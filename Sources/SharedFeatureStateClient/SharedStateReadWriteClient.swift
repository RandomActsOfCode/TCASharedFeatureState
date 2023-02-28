import Combine
import Foundation

// MARK: - SharedStateReadWriteClient

struct SharedStateReadWriteClient {
  // MARK: Internal

  func observe() -> AsyncStream<Int> {
    AsyncStream { continuation in
      let cancellable = subject.sink { if let value = $0 { continuation.yield(value) } }
      continuation.onTermination = { continuation in
        cancellable.cancel()
      }
    }
  }

  func read() -> Int? { subject.value }

  func write(_ newValue: Int) {
    subject.send(newValue)
  }

  // MARK: Private

  private let subject = CurrentValueSubject<Int?, Never>(nil)
}

extension SharedStateReadWriteClient {
  static var live: SharedStateReadWriteClient = .init()
}
