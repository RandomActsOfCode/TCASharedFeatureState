import BarFeature
import ComposableArchitecture
import Foundation
import SwiftUI

// MARK: - FooFeatureView

public struct FooFeatureView: View {
  // MARK: Lifecycle

  public init(store: StoreOf<FooFeature>) {
    self.store = store
  }

  // MARK: Public

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack {
        titleText
        Spacer()
        barFeatureSheetButton
        Spacer()
      }
      .barFeatureSheet(store)
    }
  }

  // MARK: Private

  private let store: StoreOf<FooFeature>

  private var titleText: some View {
    Text("Foo Feature")
      .font(.headline)
      .padding()
  }

  private var barFeatureSheetButton: some View {
    WithViewStore(store.stateless) { viewStore in
      Button(action: { viewStore.send(.gotoBarFeatureButtonPressed) }) {
        Text("Goto Bar Feature")
      }
    }
  }
}

extension View {
  fileprivate func barFeatureSheet(_ store: StoreOf<FooFeature>) -> some View {
    WithViewStore(store, observe: \.showBarFeatureSheet) { viewStore in
      sheet(
        isPresented: viewStore.binding(
          get: { $0 },
          send: FooFeature.Action.barFeatureSheetDismissed
        )
      ) {
        IfLetStore(
          store
            .scope(
              state: \.bar,
              action: FooFeature.Action.bar(action:)
            )
        ) { store in
          BarFeatureView(store: store)
        }
      }
    }
  }
}
