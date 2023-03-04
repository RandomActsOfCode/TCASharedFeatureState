import Foundation

// MARK: - SharedStateClientStorage

enum SharedStateClientStorage {
  static var storage: [ObjectIdentifier: Any] = [:]
}

// MARK: - SharedStateObserver

@propertyWrapper
public struct SharedStateObserver<State, Value> {
  // MARK: Lifecycle

  public init(_ keyPath: KeyPath<State, Value>) {
    let cached = SharedStateClientStorage
      .storage[ObjectIdentifier(State.self)] as? SharedStateClient<State>
    guard let cached else {
      let client = SharedStateClient<State>()
      SharedStateClientStorage.storage[ObjectIdentifier(State.self)] = client
      self.wrappedValue = client.readOnly[dynamicMember: keyPath]
      return
    }
    self.wrappedValue = cached.readOnly[dynamicMember: keyPath]
  }

  // MARK: Public

  public var wrappedValue: SharedStateClient<State>.ReadOnlyClient<Value>
}

// MARK: - SharedStatePublisher

@propertyWrapper
public struct SharedStatePublisher<State, Value> {
  // MARK: Lifecycle

  public init(_ keyPath: KeyPath<State, Value>) {
    let cached = SharedStateClientStorage
      .storage[ObjectIdentifier(State.self)] as? SharedStateClient<State>
    guard let cached else {
      let client = SharedStateClient<State>()
      SharedStateClientStorage.storage[ObjectIdentifier(State.self)] = client
      self.wrappedValue = client.writeOnly[dynamicMember: keyPath]
      return
    }
    self.wrappedValue = cached.writeOnly[dynamicMember: keyPath]
  }

  // MARK: Public

  public var wrappedValue: SharedStateClient<State>.WriteOnlyClient<Value>
}

// MARK: - Foo

struct Foo {
  var bar: Int
  var bazz: String
}

// MARK: - X

struct X {
  @SharedStateObserver(\Foo.bar)
  var bar

  @SharedStatePublisher(\Foo.bazz)
  var bazz

  func x() async {
    await bazz.write(newValue: "Hello")
  }
}
