import Dependencies
import Foundation
import SharedFeatureStateClient

// MARK: - AppSharedStateClient

public struct AppSharedStateClient {}

// MARK: DependencyKey

extension AppSharedStateClient: DependencyKey {
  public static var liveValue: SharedStateClient<AppSharedState> = .init()
}

extension DependencyValues {
  public var appSharedStateClient: SharedStateClient<AppSharedState> {
    get { self[AppSharedStateClient.self] }
    set { self[AppSharedStateClient.self] = newValue }
  }
}

//// MARK: - AppReadOnlySharedStateClient + DependencyKey
//
// extension AppReadOnlySharedStateClient: DependencyKey {
//  public static var liveValue: ReadOnlySharedStateClient<AppSharedState> =
//    .init(AppReadWriteSharedStateClient.liveValue)
// }
//
// extension DependencyValues {
//  public var readOnlySharedStateClient: ReadOnlySharedStateClient<AppSharedState> {
//    get { self[AppReadOnlySharedStateClient.self] }
//    set { self[AppReadOnlySharedStateClient.self] = newValue }
//  }
// }

// MARK: - AppWriteOnlySharedStateClient + DependencyKey

//
// extension AppWriteOnlySharedStateClient: DependencyKey {
//  public static var liveValue: WriteOnlySharedStateClient<AppSharedState> =
//    .init(AppReadWriteSharedStateClient.liveValue)
// }
//
// extension DependencyValues {
//  public var writeOnlySharedStateClient: WriteOnlySharedStateClient<AppSharedState> {
//    get { self[AppWriteOnlySharedStateClient.self] }
//    set { self[AppWriteOnlySharedStateClient.self] = newValue }
//  }
// }
