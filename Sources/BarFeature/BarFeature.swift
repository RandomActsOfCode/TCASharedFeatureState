import BazzFeature
import ComposableArchitecture
import SharedFeatureStateClient

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
      self.temperature = .notSynchronized
      self.bazz = bazz
    }

    // MARK: Public

    public var temperature: SharedState<Int>
    public var bazz: BazzFeature.State
  }

  public enum Action: Sendable {
    case task
    case temperatureUpdated(Int)
    case bazz(action: BazzFeature.Action)
  }

  public var body: some ReducerProtocol<State, Action> {
    Reduce(core)
    Scope(state: \.bazz, action: /Action.bazz(action:)) {
      BazzFeature()
    }
  }

  // MARK: Internal

  @Dependency(\.sharedStateReadonlyClient)
  var sharedStateReadonlyClient

  // MARK: Private

  private func core(into state: inout State, action: Action) -> EffectTask<Action> {
    switch action {
    case .task:
      return .run { send in
        for await newValue in await sharedStateReadonlyClient.observe() {
          await send(.temperatureUpdated(newValue))
        }
      }

    case let .temperatureUpdated(temperature):
      state.temperature = .value(temperature)
      return .none

    case .bazz:
      return .none
    }
  }
}

extension BarFeature.State {
  var temperatureString: String {
    guard let temperature = temperature.value else {
      return "No Value"
    }

    return String(temperature)
  }
}
