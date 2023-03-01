import Combine
import Dependencies
import Foundation

// MARK: - ReadWriteSharedStateClient

@dynamicMemberLookup
final public class ReadWriteSharedStateClient<State> {
  // MARK: Lifecycle

  public init() {}

  // MARK: Public

  public subscript<Value>(dynamicMember keyPath: KeyPath<State, PublishedValue<Value>>)
    -> Client<Value> {
    guard let client = storage[ObjectIdentifier(type(of: keyPath))] else {
      let newClient = Client<Value>()
      storage[ObjectIdentifier(type(of: keyPath))] = newClient
      return newClient
    }

    return client as! Client<Value>
  }

  // MARK: Private

  private var storage: [ObjectIdentifier: Any] = [:]
}

// MARK: ReadWriteSharedStateClient.Client

extension ReadWriteSharedStateClient {
  public struct Client<State> {
    // MARK: Internal

    func observe() -> AsyncStream<State> {
      AsyncStream { continuation in
        let cancellable = subject.sink {
          if case let .published(value) = $0 {
            continuation.yield(value)
          }
        }

        continuation.onTermination = { continuation in
          cancellable.cancel()
        }
      }
    }

    func read() -> PublishedValue<State> { subject.value }

    @Sendable
    func write(_ newValue: State) async {
      subject.send(.published(newValue))
    }

    // MARK: Private

    private let subject = CurrentValueSubject<PublishedValue<State>, Never>(.notPublished)
  }
}
