import Foundation
import SharedFeatureStateClient

public struct AppSharedState {
  // MARK: Lifecycle

  public init(
    temperature: PublishedValue<Int> = .notPublished,
    greeting: PublishedValue<String> = .notPublished
  ) {
    self.temperature = temperature
    self.greeting = greeting
  }

  // MARK: Public

  public var temperature: PublishedValue<Int>
  public var greeting: PublishedValue<String>
}
