import Foundation

// MARK: - SharedState

public enum SharedState<Value> {
  case notSynchronized
  case value(Value)
}

// MARK: Equatable

extension SharedState: Equatable where Value: Equatable {}

extension SharedState {
  public var value: Value? {
    guard case let .value(value) = self else { return nil }
    return value
  }
}
