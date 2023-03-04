import AppSharedStateClient
import ComposableArchitecture

// MARK: - BazzFeature

public struct BazzFeature: ReducerProtocol {
  // MARK: Lifecycle

  public init() {}

  // MARK: Public

  public struct State: Equatable {
    // MARK: Lifecycle

    public init() {
      self.temperature = nil
    }

    // MARK: Public

    public var temperature: Int?
  }

  public enum Action: Sendable {
    case task
    case temperatureUpdated(Int?)
  }

  @SharedStateObserver(\AppSharedState.temperature)
  public var temperatureClient

  public var body: some ReducerProtocol<State, Action> {
    Reduce(core)
  }

  // MARK: Private

  private func core(into state: inout State, action: Action) -> EffectTask<Action> {
    switch action {
    case .task:
      return .run { send in
        for await newValue in temperatureClient.observe() {
          await send(.temperatureUpdated(newValue))
        }
      }

    case let .temperatureUpdated(temperature):
      state.temperature = temperature
      return .none
    }
  }
}

extension BazzFeature.State {
  var temperatureString: String {
    guard let temperature else {
      return "No Value"
    }

    return String(temperature)
  }
}
