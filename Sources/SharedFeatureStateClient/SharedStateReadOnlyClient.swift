import Dependencies
import Foundation
import XCTestDynamicOverlay

// MARK: - SharedStateReadOnlyClient

public struct SharedStateReadOnlyClient {
  // MARK: Lifecycle

  public init(
    read: @escaping @Sendable () -> Int?,
    observe: @Sendable @escaping () -> AsyncStream<Int>
  ) {
    self.read = read
    self.observe = observe
  }

  // MARK: Public

  public var read: @Sendable () async -> Int?
  public var observe: @Sendable () async -> AsyncStream<Int>
}

extension SharedStateReadOnlyClient {
  public static var live: Self {
    Self(
      read: { SharedStateReadWriteClient.live.read() },
      observe: { SharedStateReadWriteClient.live.observe() }
    )
  }

  public static var unimplemented: Self {
    Self(
      read: XCTestDynamicOverlay.unimplemented("\(Self.self).read"),
      observe: XCTestDynamicOverlay.unimplemented("\(Self.self).observe")
    )
  }
}

extension DependencyValues {
  public var sharedStateReadonlyClient: SharedStateReadOnlyClient {
    get { self[SharedStateReadOnlyClient.self] }
    set { self[SharedStateReadOnlyClient.self] = newValue }
  }
}

// MARK: - SharedStateReadOnlyClient + DependencyKey

extension SharedStateReadOnlyClient: DependencyKey {
  public static var liveValue: Self = .live
  public static var testValue: Self = .unimplemented
}
