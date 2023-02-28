import ComposableArchitecture
import FooFeature

// MARK: - AppFeature

public struct AppFeature: ReducerProtocol {
  // MARK: Lifecycle

  public init() {}

  // MARK: Public

  public struct State: Equatable {
    // MARK: Lifecycle

    public init(
      temperature: Int? = nil,
      foo: FooFeature.State? = nil
    ) {
      self.temperature = temperature
      self.foo = foo
    }

    // MARK: Public

    public var temperature: Int?
    public var foo: FooFeature.State?
  }

  public enum Action: Sendable {
    case task
    case temperatureUpdated(Int)
    case gotoChildButtonPressed
    case fooFeatureSheetDismissed
    case foo(action: FooFeature.Action)
  }

  public var body: some ReducerProtocol<State, Action> {
    Reduce(core)
      .ifLet(\.foo, action: /Action.foo(action:)) {
        FooFeature()
      }
  }

  // MARK: Internal

  @Dependency(\.sharedStateWriteOnlyClient)
  var sharedStateWriteOnlyClient
  @Dependency(\.continuousClock)
  var clock

  // MARK: Private

  private func core(into state: inout State, action: Action) -> EffectTask<Action> {
    switch action {
    case .task:
      return .run { send in
        for await _ in clock.timer(interval: .milliseconds(5000)) {
          await send(.temperatureUpdated(Int.random(in: -1 ..< 40)))
        }
      }

    case let .temperatureUpdated(temperature):
      state.temperature = temperature
      return .run { _ in
        await sharedStateWriteOnlyClient.write(temperature)
      }

    case .gotoChildButtonPressed:
      state.foo = .init()
      return .none

    case .fooFeatureSheetDismissed:
      state.foo = nil
      return .none

    case .foo:
      return .none
    }
  }
}

extension AppFeature.State {
  var showFooFeatureSheet: Bool {
    foo != nil
  }

  var temperatureString: String {
    guard let temperature else {
      return "No Value"
    }

    return String(temperature)
  }
}
