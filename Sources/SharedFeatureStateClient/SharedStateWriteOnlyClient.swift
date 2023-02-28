import Dependencies
import Foundation
import XCTestDynamicOverlay

// MARK: - SharedStateWriteOnlyClient

public struct SharedStateWriteOnlyClient {
  // MARK: Lifecycle

  public init(
    write: @escaping @Sendable (Int) -> ()
  ) {
    self.write = write
  }

  // MARK: Public

  public var write: @Sendable (Int) async -> ()
}

extension SharedStateWriteOnlyClient {
  public static var live: Self {
    Self(write: { SharedStateReadWriteClient.live.write($0) })
  }

  public static var unimplemented: Self {
    Self(write: XCTestDynamicOverlay.unimplemented("\(Self.self).write"))
  }
}

// MARK: DependencyKey

extension SharedStateWriteOnlyClient: DependencyKey {
  public static var liveValue: Self = .live
  public static var testValue: Self = .unimplemented
}

extension DependencyValues {
  public var sharedStateWriteOnlyClient: SharedStateWriteOnlyClient {
    get { self[SharedStateWriteOnlyClient.self] }
    set { self[SharedStateWriteOnlyClient.self] = newValue }
  }
}
