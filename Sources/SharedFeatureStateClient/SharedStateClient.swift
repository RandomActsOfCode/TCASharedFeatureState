import Combine
import Foundation

// MARK: - SharedStateClient

public class SharedStateClient<State> {
  // MARK: Lifecycle

  public init() {
    self.storage = [:]
  }

  // MARK: Public

  public var readOnly: ReadOnlyAccess { .init(self) }
  public var writeOnly: WriteOnlyAccess { .init(self) }

  // MARK: Internal

  func getClient<Value>(
    for keyPath: KeyPath<State, Value>
  ) -> ReadWriteClient<Value> {
    let anyKeyPath: AnyKeyPath = keyPath
    guard let client = storage[anyKeyPath] else {
      let client = ReadWriteClient<Value>()
      storage[anyKeyPath] = client
      return client
    }

    return client as! ReadWriteClient<Value>
  }

  // MARK: Private

  private var storage: [AnyKeyPath: Any]
}

// MARK: SharedStateClient.ReadOnlyAccess

extension SharedStateClient {
  @dynamicMemberLookup
  public class ReadOnlyAccess {
    // MARK: Lifecycle

    init(_ client: SharedStateClient) {
      self.client = client
    }

    // MARK: Public

    public subscript<Value>(
      dynamicMember keyPath: KeyPath<State, Value>
    ) -> ReadOnlyClient<Value> {
      .init(client: client.getClient(for: keyPath))
    }

    // MARK: Private

    private var client: SharedStateClient
  }
}

// MARK: SharedStateClient.WriteOnlyAccess

extension SharedStateClient {
  @dynamicMemberLookup
  public struct WriteOnlyAccess {
    // MARK: Lifecycle

    init(_ client: SharedStateClient) {
      self.client = client
    }

    // MARK: Public

    public subscript<Value>(
      dynamicMember keyPath: KeyPath<State, Value>
    ) -> WriteOnlyClient<Value> {
      .init(client: client.getClient(for: keyPath))
    }

    // MARK: Private

    private var client: SharedStateClient
  }
}

// MARK: SharedStateClient.ReadOnlyClient

extension SharedStateClient {
  public struct ReadOnlyClient<Value> {
    // MARK: Lifecycle

    init(client: ReadWriteClient<Value>) {
      self.client = client
    }

    // MARK: Public

    public var currentValue: PublishedValue<Value> {
      client.currentValue
    }

    public func observe() -> AsyncStream<Value> {
      client.observe()
    }

    // MARK: Private

    private var client: ReadWriteClient<Value>
  }
}

// MARK: SharedStateClient.WriteOnlyClient

extension SharedStateClient {
  public struct WriteOnlyClient<Value> {
    // MARK: Lifecycle

    init(client: ReadWriteClient<Value>) {
      self.client = client
    }

    // MARK: Public

    public func write(newValue: Value) async {
      await client.write(newValue: newValue)
    }

    // MARK: Private

    private var client: ReadWriteClient<Value>
  }
}

// MARK: SharedStateClient.ReadWriteClient

extension SharedStateClient {
  struct ReadWriteClient<Value> {
    // MARK: Internal

    typealias Publisher = CurrentValueSubject<PublishedValue<Value>, Never>

    var currentValue: PublishedValue<Value> {
      publisher.value
    }

    func write(newValue: Value) async {
      publisher.send(.published(newValue))
    }

    func observe() -> AsyncStream<Value> {
      AsyncStream { continuation in
        let cancellable = publisher.sink {
          if case let .published(value) = $0 {
            continuation.yield(value)
          }
        }

        continuation.onTermination = { continuation in
          cancellable.cancel()
        }
      }
    }

    // MARK: Private

    private let publisher: Publisher = .init(.notPublished)
  }
}
