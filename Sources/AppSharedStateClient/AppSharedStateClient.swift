import Foundation
import SharedFeatureStateClient

// MARK: - AppReadWriteSharedStateClient

struct AppReadWriteSharedStateClient {}

extension AppReadWriteSharedStateClient {
  static var liveValue: ReadWriteSharedStateClient<AppSharedState> = .init()
}

// MARK: - AppReadOnlySharedStateClient

public struct AppReadOnlySharedStateClient {}

// MARK: - AppWriteOnlySharedStateClient

public struct AppWriteOnlySharedStateClient {}
