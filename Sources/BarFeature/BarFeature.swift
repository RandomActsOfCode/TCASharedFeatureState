import AppSharedStateClient
import BazzFeature
import ComposableArchitecture

// MARK: - BarFeature

public struct BarFeature: ReducerProtocol {
  // MARK: Lifecycle

  public init() {}

  // MARK: Public

  public struct State: Equatable {
    // MARK: Lifecycle

    public init(
      bazz: BazzFeature.State = .init()
    ) {
      self.temperature = .notObserved
      self.greeting = .notObserved
      self.bazz = bazz
    }

    // MARK: Public

    public var temperature: ObservedValue<Int?>
    public var greeting: ObservedValue<String?>
    public var bazz: BazzFeature.State
  }

  public enum Action: Sendable {
    case task
    case greetingUpdated(String?)
    case temperatureUpdated(Int?)
    case bazz(action: BazzFeature.Action)
  }

  @Dependency(\.readOnlySharedStateClient.temperature)
  public var temperatureSharedStateClient
  @Dependency(\.readOnlySharedStateClient.greeting)
  public var greetingSharedStateClient

  public var body: some ReducerProtocol<State, Action> {
    Reduce(core)
    Scope(state: \.bazz, action: /Action.bazz(action:)) {
      BazzFeature()
    }
  }

  // MARK: Private

  private func core(into state: inout State, action: Action) -> EffectTask<Action> {
    switch action {
    case .task:
      let first: EffectTask<Action> = .run { send in
        for await newValue in temperatureSharedStateClient.observe() {
          await send(.temperatureUpdated(newValue))
        }
      }

      let second: EffectTask<Action> = .run { send in
        for await newValue in greetingSharedStateClient.observe() {
          await send(.greetingUpdated(newValue))
        }
      }

      return .merge(first, second)

    case let .temperatureUpdated(temperature):
      state.temperature = .observed(temperature)
      return .none

    case let .greetingUpdated(greeting):
      state.greeting = .observed(greeting)
      return .none

    case .bazz:
      return .none
    }
  }
}

extension BarFeature.State {
  var temperatureString: String {
    guard let temperature = temperature.value, let x = temperature else {
      return "No Value"
    }

    return String(x)
  }
}

extension BarFeature.State {
  var greetingString: String {
    guard let greeting = greeting.value, let x = greeting else {
      return "No Value"
    }

    return String(x)
  }
}
