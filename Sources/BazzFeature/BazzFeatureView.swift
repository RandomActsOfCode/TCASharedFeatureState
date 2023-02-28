import ComposableArchitecture
import Foundation
import SwiftUI

public struct BazzFeatureView: View {
  // MARK: Lifecycle

  public init(store: StoreOf<BazzFeature>) {
    self.store = store
  }

  // MARK: Public

  public var body: some View {
    WithViewStore(store.stateless) { viewStore in
      HStack {
        titleText
        temperatureText
      }
      .padding()
      .border(.black, width: 1)
      .task { await viewStore.send(.task).finish() }
    }
  }

  // MARK: Private

  private let store: StoreOf<BazzFeature>

  private var titleText: some View {
    Text("Bazz Feature")
  }

  private var temperatureText: some View {
    WithViewStore(store, observe: \.temperatureString) { viewStore in
      Text("Temperature: \(viewStore.state)")
    }
  }
}
