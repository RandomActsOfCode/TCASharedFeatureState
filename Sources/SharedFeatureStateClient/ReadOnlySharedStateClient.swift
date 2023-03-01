import Foundation

// MARK: - ReadOnlySharedStateClient

@dynamicMemberLookup
final public class ReadOnlySharedStateClient<State> {
  // MARK: Lifecycle

  public init(_ readWriteClient: ReadWriteSharedStateClient<State>) {
    self.readWriteClient = readWriteClient
  }

  // MARK: Public

  public subscript<Value>(dynamicMember keyPath: KeyPath<State, PublishedValue<Value>>)
    -> Client<Value> {
    let client = readWriteClient[dynamicMember: keyPath]
    return .init(read: { client.read() }, observe: { client.observe() })
  }

  // MARK: Private

  private let readWriteClient: ReadWriteSharedStateClient<State>
}

// MARK: ReadOnlySharedStateClient.Client

extension ReadOnlySharedStateClient {
  public struct Client<State> {
    public var read: @Sendable () -> PublishedValue<State>
    public var observe: @Sendable () -> AsyncStream<State>
  }
}
