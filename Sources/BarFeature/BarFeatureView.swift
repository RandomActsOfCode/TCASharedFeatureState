import BazzFeature
import ComposableArchitecture
import Foundation
import SwiftUI

public struct BarFeatureView: View {
  // MARK: Lifecycle

  public init(store: StoreOf<BarFeature>) {
    self.store = store
  }

  // MARK: Public

  public var body: some View {
    WithViewStore(store.stateless) { viewStore in
      VStack {
        titleText
        Spacer()
        temperatureText
        Spacer()
        bazzView
        Spacer()
      }
      .task { await viewStore.send(.task).finish() }
    }
  }

  // MARK: Private

  private let store: StoreOf<BarFeature>

  private var titleText: some View {
    Text("Bar Feature")
      .font(.headline)
      .padding()
  }

  private var temperatureText: some View {
    WithViewStore(store, observe: \.temperatureString) { viewStore in
      Text("Temperature: \(viewStore.state)")
        .padding()
    }
  }

  private var bazzView: some View {
    BazzFeatureView(store: store.scope(state: \.bazz, action: BarFeature.Action.bazz(action:)))
  }
}
