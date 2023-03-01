import Foundation

// MARK: - ObservedValue

public enum ObservedValue<Value> {
  case notObserved
  case observed(Value)
}

// MARK: Equatable

extension ObservedValue: Equatable where Value: Equatable {}

extension ObservedValue {
  public var value: Value? {
    guard case let .observed(value) = self else {
      return nil
    }

    return value
  }
}

extension ObservedValue {
  public init(_ publishedValue: PublishedValue<Value>) {
    switch publishedValue {
    case .notPublished:
      self = .notObserved
    case let .published(value):
      self = .observed(value)
    }
  }
}
