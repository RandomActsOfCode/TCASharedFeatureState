import BarFeature
import ComposableArchitecture

// MARK: - FooFeature

public struct FooFeature: ReducerProtocol {
  // MARK: Lifecycle

  public init() {}

  // MARK: Public

  public struct State: Equatable {
    // MARK: Lifecycle

    public init(
      bar: BarFeature.State? = nil
    ) {
      self.bar = bar
    }

    // MARK: Public

    public var bar: BarFeature.State?
  }

  public enum Action: Sendable {
    case gotoBarFeatureButtonPressed
    case barFeatureSheetDismissed
    case bar(action: BarFeature.Action)
  }

  public var body: some ReducerProtocol<State, Action> {
    Reduce(core)
      .ifLet(\.bar, action: /Action.bar(action:)) {
        BarFeature()
      }
  }

  // MARK: Private

  private func core(into state: inout State, action: Action) -> EffectTask<Action> {
    switch action {
    case .gotoBarFeatureButtonPressed:
      state.bar = .init()
      return .none

    case .barFeatureSheetDismissed:
      state.bar = nil
      return .none

    case .bar:
      return .none
    }
  }
}

extension FooFeature.State {
  var showBarFeatureSheet: Bool {
    bar != nil
  }
}
