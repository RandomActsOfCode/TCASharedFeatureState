import Foundation

// MARK: - WriteOnlySharedStateClient

@dynamicMemberLookup
final public class WriteOnlySharedStateClient<State> {
  // MARK: Lifecycle

  public init(_ readWriteClient: ReadWriteSharedStateClient<State>) {
    self.readWriteClient = readWriteClient
  }

  // MARK: Public

  public subscript<Value>(dynamicMember keyPath: KeyPath<State, PublishedValue<Value>>)
    -> Client<Value> {
    let client = readWriteClient[dynamicMember: keyPath]
    return .init(write: client.write)
  }

  // MARK: Private

  private let readWriteClient: ReadWriteSharedStateClient<State>
}

// MARK: WriteOnlySharedStateClient.Client

extension WriteOnlySharedStateClient {
  public struct Client<State> {
    public var write: @Sendable (State) async -> ()
  }
}
