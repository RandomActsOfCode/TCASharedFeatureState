import AppSharedStateClient
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
      greeting: String? = nil,
      foo: FooFeature.State? = nil
    ) {
      self.temperature = temperature
      self.greeting = greeting
      self.foo = foo
    }

    // MARK: Public

    public var temperature: Int?
    public var greeting: String?
    public var foo: FooFeature.State?
  }

  public enum Action: Sendable {
    case task
    case temperatureUpdated(Int)
    case greetingUpdated(String)
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

  @Dependency(\.writeOnlySharedStateClient.temperature)
  var temperatureSharedStateClient
  @Dependency(\.writeOnlySharedStateClient.greeting)
  var greetingSharedStateClient
  @Dependency(\.continuousClock)
  var clock

  // MARK: Private

  private func core(into state: inout State, action: Action) -> EffectTask<Action> {
    switch action {
    case .task:
      let first: EffectTask<Action> = .run { send in
        for await _ in clock.timer(interval: .milliseconds(3000)) {
          await send(.temperatureUpdated(Int.random(in: -1 ..< 40)))
        }
      }

      let second: EffectTask<Action> = .run { send in
        let greetings = ["Hello", "Bonjour", "Hola", "Nǐ Hǎo"]
        for await _ in clock.timer(interval: .milliseconds(2000)) {
          await send(.greetingUpdated(greetings[Int.random(in: greetings.indices)]))
        }
      }

      return .merge(first, second)

    case let .temperatureUpdated(temperature):
      state.temperature = temperature
      return .run { _ in
        await temperatureSharedStateClient.write(temperature)
      }

    case let .greetingUpdated(greeting):
      state.greeting = greeting
      return .run { _ in
        await greetingSharedStateClient.write(greeting)
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
