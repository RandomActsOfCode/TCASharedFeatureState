import Foundation

// MARK: - PublishedValue

public enum PublishedValue<Value> {
  case notPublished
  case published(Value)
}

// MARK: Equatable

extension PublishedValue: Equatable where Value: Equatable {}

extension PublishedValue {
  public var value: Value? {
    guard case let .published(value) = self else {
      return nil
    }

    return value
  }
}
